import bcrypt, json, db_sqlite


type
    SignUpPayload* = object
        username*: string
        password*: string
        email*: string


proc signUp*(conn: DbConn, data: SignUpPayload): bool =
    ## creates database record for the user, unless it exists already
    ## returns true if user was created
    if conn.getValue(sql"SELECT id FROM users WHERE username = ?", data.username) != "":
        return false

    let salt = genSalt(10)
    conn.exec(sql"INSERT INTO users (username, email, pwdhash, pwdsalt) VALUES (?, ?, ?, ?)",
              data.username, data.email, hash(data.password, salt), salt)
    return true

