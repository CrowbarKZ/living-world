CREATE TABLE users(
    id INTEGER PRIMARY KEY,
    username VARCHAR(255),
    email VARCHAR(255),
    pwdhash VARCHAR(255),
    pwdsalt VARCHAR(255)
);

CREATE TABLE planets(
    id INTEGER PRIMARY KEY,
    userid INTEGER,
    data TEXT
);
