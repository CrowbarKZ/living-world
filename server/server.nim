import random, asynchttpserver, asyncdispatch, asyncnet, strformat, strutils, json
import websocket
import entity, planet, vector, cell

var clients = newSeq[AsyncWebSocket]()
var p: Planet = emptyPlanet(60, 60)

type
    Command = object
        name: string
        x: int
        y: int
        cellKind: CellKind


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
                    let command: Command = parseJson(data).to(Command)
                    let pos: Vector2 = (command.x, command.y)

                    case command.name:
                    of "get_planet_data":
                        p.process
                        await ws.sendBinary(p.toMsgPack)
                    of "get_cell_info":
                        await ws.sendText($p.getCellJson(pos))
                    of "change_cell":
                        p.setCellKind(pos, command.cellKind)
                        echo "processed command!"
                    else:
                        echo fmt"received command: {command.name}"

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
