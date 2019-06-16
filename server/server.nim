import random, asynchttpserver, asyncdispatch, asyncnet, strformat
from times import getTime, toUnix, nanosecond

import websocket

import planet

let now = getTime()
var generator = initRand(now.toUnix * 1000000000 + now.nanosecond)
var clients = newSeq[AsyncWebSocket]()


proc sendPlanetData(ws: AsyncWebSocket) {.async.} =
    while true:
        if ws.sock.isClosed:
            break

        var planet: Planet = createEmptyPlanet(60, 60)
        for i in 0..<planet.cells.len:
            planet.cells[i] = CellType(generator.rand(2))

        try:
            await ws.sendBinary(planet.toMsgPack)
        except ValueError:
            echo fmt"client died, total clients: {clients.len}"
            return

        echo fmt"sent data to client {ws.sock.getFd.int}, total clients: {clients.len}"
        await sleepAsync(1000)

    clients.delete(clients.find(ws))


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
            var key: string = ""
            clients.add(ws)
            asyncCheck sendPlanetData(ws)

            echo fmt"New client, total: {clients.len}"

        while true:
            try:
                let (opcode, data) = await ws.readData()
                echo "(opcode: ", opcode, ", data length: ", data.len, ")"

                case opcode
                of Opcode.Text:
                    discard
                of Opcode.Binary:
                    await ws.sendBinary(data)
                of Opcode.Close:
                    asyncCheck ws.close()
                    # let (closeCode, reason) = extractCloseData(data)
                    echo fmt"client closed, total clients: {clients.len}"
                else: discard
            except:
                echo "encountered exception: ", getCurrentExceptionMsg()


proc main() =
    var server = newAsyncHttpServer()
    waitFor server.serve(Port(8000), processRequest)



when isMainModule:
   main()
