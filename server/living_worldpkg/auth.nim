## Authentication related routines

import db_sqlite, json, tables
import bcrypt
import planet

type
    SignUpPayload* = object
        username*: string
        password*: string
        email*: string

    SignInPayload* = object
        username*: string
        password*: string


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


proc signIn*(conn: DbConn, body: string, planets: TableRef[string, Planet]): JsonNode =
    ## signs user in, loads his planet in memory (or creates if needed)
    ## returns json response with session token for client
    var payload: SignInPayload
    parseBody(payload, body, SignInPayload)

    let row = conn.getRow(sql"SELECT pwdsalt, pwdhash FROM users WHERE username = ?", payload.username)
    let pwdsalt = row[0]
    let pwdhash = row[1]

    if pwdsalt == "" or hash(payload.password, pwdsalt) != pwdhash:
        return response(false, "login_failed")
    else:
        let token = genSalt(1)
        planets[token] = emptyPlanet(50, 50)
        return response(true, token)
