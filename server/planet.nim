import times, typetraits, random, math, json
import msgpack4nim, perlin
import vector, entity

randomize()
let now = getTime()
let seed = now.toUnix + now.nanosecond
var generator = initRand(seed)
let noise = newNoise(seed.uint32, 1, 0.5)

let oneDay: Duration = initDuration(days=1)
const spawnIntervals: array[EntityKind, int] = [5, 20, 50]
const directionChangeInterval: int = 10
const msPerRound = 500

type
    CellKind* = enum
        desert, land, water

    Planet* = tuple
        dimensions: Vector2
        age: int
        cells: seq[CellKind]
        entities: seq[Entity]
        lastProcessed: DateTime


func noiseToCell(f: float): CellKind =
    ## converts perlin noise output 0..1 float to CellKind
    if f < 0.4:
        return desert
    elif f >= 0.4 and f <= 0.7:
        return land
    else:
        return water


proc createEmptyPlanet*(w: int, h: int): Planet =
    let dimensions = (w, h)
    let entities: seq[Entity] = newSeq[Entity]()
    var cells: seq[CellKind] = newSeq[CellKind](w * h)

    for x in 0..<w:
        for y in 0..<h:
            cells[x + y * w] = noise.perlin(x, y).noiseToCell

    result = (
        dimensions: dimensions,
        age: 0,
        cells: cells,
        entities: entities,
        lastProcessed: now().utc,
    )


proc findEntityIdx(entities: seq[Entity], pos: Vector2): int =
    for i, e in entities.pairs:
        if e.position == pos:
            return i
    return -1


func entityExists(entities: seq[Entity], pos: Vector2): bool =
    return entities.findEntityIdx(pos) >= 0


func getCell(p: Planet, pos: Vector2): CellKind =
    if pos.x >= p.dimensions.x or pos.y >= p.dimensions.y or pos.x < 0 or pos.y < 0:
        return water
    return p.cells[pos.x + pos.y * p.dimensions.x]


proc setCell*(p: var Planet, pos: Vector2, kind: CellKind) {.discardable.} =
    if pos.x >= p.dimensions.x or pos.y >= p.dimensions.y or pos.x < 0 or pos.y < 0:
        return

    if p.cells[pos.x + pos.y * p.dimensions.x] == kind:
        return

    # delete entities at that pos
    let idx = p.entities.findEntityIdx(pos)
    if idx >= 0:
        p.entities.delete(idx)
    p.cells[pos.x + pos.y * p.dimensions.x] = kind



func getCellJson*(p: Planet, pos: Vector2): JsonNode =
    result = %*{"pos": pos, "cell_kind": p.getCell(pos)}

    let idx = findEntityIdx(p.entities, pos)
    if idx >= 0:
        result["entity"] = %p.entities[idx]


func isCellPassable(p: Planet, pos: Vector2): bool =
    return p.getCell(pos) != water


func isCellGrowable(p: Planet, pos: Vector2): bool =
    return p.getCell(pos) == land


proc stepEntity(p: var Planet, e: var Entity): int =
    ## process a turn for entity and return an index of entity to delete

    # age
    inc(e.age)

    # change energy
    e.addEnergy(energyIncrement[e.kind])
    if e.energy <= 0:
        return p.entities.find(e)

    # move and process interactions
    case e.kind:
    of grass:
        discard
    of sheep:
        # randomize roaming pattern
        if p.age mod directionChangeInterval == 0:
            e.direction = generator.sample(directions)

        let newPos = e.position + e.direction
        if isCellPassable(p, newPos):
            let blockingIdx = findEntityIdx(p.entities, newPos)
            if blockingIdx >= 0:
                let blocking = p.entities[blockingIdx]
                case blocking.kind:
                of grass:
                    # eat grass
                    e.addEnergy(blocking.energy)
                    return blockingIdx
                of sheep:
                    # give birth
                    let birthPos = e.position + e.direction.nextDir
                    if (isCellPassable(p, birthPos) and
                        e.canBirth and
                        blocking.canBirth):

                        echo "gave birth!"
                        e.energy = int(e.energy / 2)
                        p.entities[blockingIdx].energy = int(blocking.energy / 2)
                        p.entities.add(createEntity(sheep, birthPos, generator.sample(directions)))
                    e.direction = generator.sample(directions)
                else:
                    discard
            else:
                e.position = newPos
        else:
            e.direction = generator.sample(directions)
    of human:
        discard

    return -1


proc step(p: var Planet) {.discardable.} =
    # age planet
    inc(p.age)

    # process existing entities
    var i: int = 0
    while i < p.entities.len:
        let delIdx = stepEntity(p, p.entities[i])
        if delIdx > 0:
            p.entities.delete(delIdx)
        else:
            inc(i)

    # create grass if needed and the cell is free
    var pos: Vector2 = (generator.rand(p.dimensions.x - 1), generator.rand(p.dimensions.y - 1))
    if p.isCellGrowable(pos) and not entityExists(p.entities, pos):
        if p.age mod spawnIntervals[grass] == 0:
            p.entities.add(createEntity(grass, pos, generator.sample(directions)))


    # create sheep if needed and the cell is free
    pos = (generator.rand(p.dimensions.x - 1), generator.rand(p.dimensions.y - 1))
    if p.isCellPassable(pos) and not entityExists(p.entities, pos):
        if p.age mod spawnIntervals[sheep] == 0:
            p.entities.add(createEntity(sheep, pos, generator.sample(directions)))


proc process*(p: var Planet) {.discardable.} =
    let newNow: DateTime = now().utc
    var dt: Duration = newNow - p.lastProcessed
    if dt > oneDay:
        dt = oneDay

    let numsteps = (dt.inMilliseconds.int / msPerRound).round.int
    if numsteps == 0:
        return

    for i in 0..<numsteps:
        step(p)
    p.lastProcessed = newNow


proc toMsgPack*(p: Planet): string =
    result = pack(p)


when isMainModule:
    for y in 0..<60:
        for x in 0..<60:
            let value = noise.perlin(x, y)

            stdout.write( int(round(10 * value)) )
        stdout.write("\n")
