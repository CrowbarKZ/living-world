## Authentication related routines

import db_sqlite, json, tables, times
import bcrypt
import types, planet

const sessionKeepAlive: Duration = initDuration(minutes=15)

type
    SessionObj = object
        username*: string
        planet*: Planet
        lastRequest*: DateTime

    Session* = ref SessionObj

    SignUpPayload = object
        username*: string
        password*: string
        email*: string

    SignInPayload = object
        username*: string
        password*: string


proc newSession(username: string, planet: Planet): Session =
    return Session(
        username: username,
        planet: planet,
        lastRequest: now().utc
    )


template parseBody(outvar: untyped, body: string, outtype: untyped) =
    ## attempt to parse json into specific type variable
    ## or return jsonNode from containing proc
    try:
        outvar = parseJson(body).to(outtype)
    except KeyError, JsonParsingError:
        return response(false, "bad_payload")


func response(success: bool, data: string): JsonNode =
    return %*{"success": success, "data": data}


proc signUp*(conn: DbConn, body: string): JsonNode =
    ## creates database record for the user, unless it exists already
    ## returns json response for client
    var payload: SignUpPayload
    parseBody(payload, body, SignUpPayload)

    if conn.getValue(sql"SELECT id FROM users WHERE username = ?", payload.username) != "":
        return response(false, "user_exists")

    let salt = genSalt(10)
    conn.exec(sql"INSERT INTO users (username, email, pwdhash, pwdsalt) VALUES (?, ?, ?, ?)",
              payload.username, payload.email, hash(payload.password, salt), salt)
    return response(true, "user_created")


func getExistingToken(username: string, sessions: TableRef[string, Session]): string =
    ## returns token for username if session exists in memory
    ## otheriwse returns empty string
    for k, v in sessions.pairs:
        if v.username == username:
            return k
    return ""


proc endSession*(conn: DbConn, token: string, sessions: TableRef[string, Session]) {.discardable.} =
    ## save progress and delete session
    if not (token in sessions):
        return

    let session = sessions[token]
    let userid = conn.getValue(sql"SELECT id FROM users WHERE username = ?", session.username)
    let planetid = conn.getValue(sql"SELECT id FROM planets WHERE userid = ?", userid)
    if planetid == "":
        echo "making new planet in db for ", userid
        conn.exec(sql"INSERT INTO planets (userid, data) VALUES (?, ?)",
                  userid, $(session.planet.getRenderJson()))
    else:
        echo "updating planet in db for ", userid
        conn.exec(sql"UPDATE planets SET data = ? WHERE id = ?",
                  $(session.planet.getRenderJson()), planetid)
    sessions.del(token)


proc cleanDeadSessions(conn: DbConn, sessions: TableRef[string, Session]) {.discardable.} =
    let newNow: DateTime = now().utc
    var dt: Duration

    var keysToDelete: seq[string] = newSeq[string]()
    for k, v in sessions.pairs:
        dt = newNow - v.lastRequest
        if dt > sessionKeepAlive:
            keysToDelete.add(k)

    for k in keysToDelete:
        endSession(conn, k, sessions)
        echo "ended a dead session"


proc signIn*(conn: DbConn, body: string, sessions: TableRef[string, Session]): JsonNode =
    ## signs user in, loads his planet in memory (or creates if needed)
    ## returns json response with session token for client
    var payload: SignInPayload
    parseBody(payload, body, SignInPayload)

    let row = conn.getRow(sql"SELECT pwdsalt, pwdhash, username, id FROM users WHERE username = ?", payload.username)
    let pwdsalt = row[0]
    let pwdhash = row[1]
    let username = row[2]
    let userid = row[3]

    if pwdsalt == "" or hash(payload.password, pwdsalt) != pwdhash:
        return response(false, "login_failed")

    cleanDeadSessions(conn, sessions)

    var token: string = getExistingToken(username, sessions)
    if token == "":
        token = genSalt(1)

    let planetText = conn.getValue(sql"SELECT data FROM planets WHERE userid = ?", userid)
    var planet: Planet
    if planetText == "":
        echo "creating new planet..."
        planet = emptyPlanet()
        planet.generateTerrain()
    else:
        echo "loading planet from db... (not really)"
        # planet = newPlanetFromText(planetText)
        planet = emptyPlanet()
        planet.generateTerrain()

    sessions[token] = newSession(username, planet)

    echo "currently we have this many sessions:", len(sessions)
    return response(true, token)

