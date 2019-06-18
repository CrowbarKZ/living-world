import random, asynchttpserver, asyncdispatch, asyncnet, strformat, strutils
import websocket
import entity, planet

var clients = newSeq[AsyncWebSocket]()
var p: Planet = createEmptyPlanet(60, 60)


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
                    let parts: seq[string] = split(data, ":")
                    case parts[0]:
                    of "get_planet_data":
                        p.process
                        await ws.sendBinary(p.toMsgPack)
                    of "get_cell_data":
                        let pos: Vector2 = (parts[1].parseInt, parts[2].parseInt)
                        let info: string = getCellInfo(p, pos)
                        await ws.sendText(fmt"energy at {pos} = {info}")
                    else:
                        discard
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
