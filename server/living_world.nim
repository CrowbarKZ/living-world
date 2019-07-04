## WebSocket server

import random, asynchttpserver, asyncdispatch, asyncnet, strformat, strutils, json, db_sqlite, tables
import websocket
import living_worldpkg/types, living_worldpkg/entity, living_worldpkg/planet, living_worldpkg/auth,
       living_worldpkg/command

var dbConnection {.threadvar.}: DbConn
var clients {.threadvar.}: seq[AsyncWebSocket]
var sessions {.threadvar.}: TableRef[string, Session]
var server: AsyncHttpServer = newAsyncHttpServer()

randomize()


proc processRequest(req: Request) {.async, gcsafe.} =
    if req.url.path == "/backend/signup":
        let responseBody: JsonNode = signUp(dbConnection, req.body)
        await req.respond(Http200, $responseBody, newHttpHeaders([("Content-Type","application/json")]))

    if req.url.path == "/backend/signin":
        let responseBody: JsonNode = signIn(dbConnection, req.body, sessions)
        await req.respond(Http200, $responseBody, newHttpHeaders([("Content-Type","application/json")]))

    if req.url.path == "/backend/ws":
        # handle connection
        let (ws, error) = await verifyWebsocketRequest(req, "living-world-default")
        if ws.isNil:
            echo "WS negotiation failed: ", error
            await req.respond(Http400, "Websocket negotiation failed: " & error)
            req.client.close()
            return
        else:
            clients.add(ws)
            echo fmt"New client, total: {clients.len}"

        while true:
            try:
                let (opcode, data) = await ws.readData()
                case opcode
                of Opcode.Text:
                    await ws.sendText($processCommand(dbConnection, data, sessions))
                of Opcode.Binary:
                    await ws.sendBinary(data)
                of Opcode.Close:
                    asyncCheck ws.close()
                    clients.delete(clients.find(ws))
                    let (closeCode, reason) = extractCloseData(data)
                    echo fmt"client closed {closeCode} {reason}, total clients: {clients.len}"
                else: discard
            except:
                echo "encountered exception: ", getCurrentExceptionMsg()
                break;


proc main() =
    dbConnection = open("data.db", "", "", "")
    clients = newSeq[AsyncWebSocket]()
    sessions = newTable[string, Session]()
    waitFor server.serve(Port(8000), processRequest)


when isMainModule:
    main()
