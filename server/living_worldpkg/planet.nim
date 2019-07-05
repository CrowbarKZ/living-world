import times, random, math, json
import perlin
import types, entity, system

const timeFmt = "yyyy-MM-dd HH:mm:ss"
const oneDay: Duration = initDuration(days=1)
const msPerRound = 500


proc getRenderJson*(p: Planet): JsonNode =
    var organismsNode = newJArray()

    for i in 0.uint16..<planetSize:
        if p.idx[i] != 0:
            organismsNode.add(%p.organisms[p.idx[i]].kind)
        else:
            organismsNode.add(newJNull())

    return %*{
        "dimensions": {"x": planetWidth, "y": planetHeight},
        "age": p.age,
        "waterLevelHeight": p.waterLevelHeight,
        "heights": p.heights,
        "organisms": organismsNode,
        "lastProcessed": p.lastProcessed.format(timeFmt),
        "paused": p.paused
    }


proc emptyPlanet*(): Planet =
    let now = getTime()
    let seed = now.toUnix + now.nanosecond

    result = Planet(
        entityManager: newEntityManager(),
        generator: initRand(seed),
        age: 0,
        waterLevelHeight: 4000,
        lastProcessed: now().utc,
        paused: false,
    )

    ## assign height between 0 and 1000 value to each cell
    let noiseSeed = result.generator.rand(uint32.high).uint32
    let noise = newNoise(noiseSeed.uint32, 1, 0.5)
    for y in 0.uint8..<uint8.high:
        for x in 0.uint8..<uint8.high:
            result.heights[x.uint16 + y.uint16 * planetWidth] = (noise.perlin(x.int, y.int) * 10000).round.int


proc pause*(p: Planet) {.discardable.} =
    p.paused = true


proc unpause*(p: Planet) {.discardable.} =
    p.paused = false
    p.lastProcessed = now().utc


proc step(p: Planet) {.discardable.} =
    inc(p.age)
    growGrass(p)
    spawnSheep(p)
    roam(p)

    # process existing entities
    # var i: int = 0
    # while i < p.entities.len:
    #     var entity = p.entities[i]
    #     let delIdx = stepEntity(p, entity)
    #     if delIdx > 0:
    #         p.deleteEntity(entity.position, delIdx)
    #     else:
    #         inc(i)



    # create sheep if needed and the cell is free
    # pos = (generator.rand(p.dimensions.x - 1), generator.rand(p.dimensions.y - 1))
    # cell = p.getCell(pos)
    # if cell.isPassable and cell.isFree:
    #     if p.age mod spawnIntervals[sheep] == 0:
    #         p.createEntity(sheep, pos)


proc process*(p: Planet) {.discardable.} =
    if p.paused:
        return

    let newNow: DateTime = now().utc
    var dt: Duration = newNow - p.lastProcessed
    if dt > oneDay:
        dt = oneDay

    let numsteps = (dt.inMilliseconds.int / msPerRound).round.int
    if numsteps == 0:
        return

    if numsteps > 1:
        echo "processing steps ", numsteps

    for i in 0..<numsteps:
        step(p)
    p.lastProcessed = newNow


# proc newPlanetFromText*(s: string): Planet =
#     ## create a planet from its text-json representation
#     var node: JsonNode
#     try:
#         node = parseJson(s)
#         result = emptyPlanet(node["dimensions"]["x"].getInt, node["dimensions"]["y"].getInt)
#         result.lastProcessed = parse(node["lastProcessed"].getStr, timeFmt, utc())
#         echo result.lastProcessed
#         for idx, c in node["cells"].getElems:
#             result.cells[idx].kind = parseEnum[CellKind](c.getStr)
#         for n in node["entities"].getElems:
#             let e: Entity = newEntityFromJson(n)
#             result.addEntity(e)

#     except JsonParsingError, KeyError, ValueError:
#         echo "failed to parse planet data from text: ", getCurrentExceptionMsg()
#         return result


when isMainModule:
    import sequtils

    var p: Planet = emptyPlanet()
    echo planetSize
    echo p.heights

    var t0 = cpuTime()
    for i in 0..200000:
        if i mod 100 == 0:
            let notZero = filter(p.idx, proc(x: uint16): bool =
                x != 0)
            echo "processing step = ", i, " num organisms = ", notZero.len, " time taken = ", cpuTime() - t0
            t0 = cpuTime()
        step(p)

    # echo
