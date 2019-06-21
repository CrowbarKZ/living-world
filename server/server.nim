import random, asynchttpserver, asyncdispatch, asyncnet, strformat, strutils, json
import websocket
import entity, planet, vector, cell

var clients = newSeq[AsyncWebSocket]()
var p: Planet = emptyPlanet(60, 60)


proc processRequest(req: Request) {.async, gcsafe.} =
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
                    let command = parseJson(data)

                    case command["name"].getStr:
                    of "get_planet_data":
                        p.process
                        await ws.sendBinary(p.toMsgPack)
                    of "pause":
                        p.pause
                    of "unpause":
                        p.unpause
                    of "get_cell_info":
                        let pos: Vector2 = (command["x"].getInt, command["y"].getInt)
                        await ws.sendText($p.getCellJson(pos))
                    of "change_cell":
                        let pos: Vector2 = (command["x"].getInt, command["y"].getInt)
                        p.setCellKind(pos, command["cellKind"].getInt.CellKind)
                    else:
                        let cmdName = command["name"].getStr
                        echo fmt"received command: {cmdName}"

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


proc main() =
    var server = newAsyncHttpServer()
    waitFor server.serve(Port(8000), processRequest)


when isMainModule:
   main()
