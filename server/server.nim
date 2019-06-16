import random
from times import getTime, toUnix, nanosecond

import jester
import planet

let now = getTime()
var generator = initRand(now.toUnix * 1000000000 + now.nanosecond)


router mainRouter:

    get "/backend/planet/":
        var planet: Planet = createEmptyPlanet(60, 60)
        for i in 0..<planet.cells.len:
            planet.cells[i] = CellType(generator.rand(2))
        resp planet.toMsgPack


proc main() =
    const port = Port(8000)
    let settings = newSettings(port = port)
    var jester = initJester(mainRouter, settings = settings)
    jester.serve()


when isMainModule:
    main()
