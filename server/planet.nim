import times, typetraits, random, math
import msgpack4nim
import entity

let now = getTime()
var generator = initRand(now.toUnix * 1000000000 + now.nanosecond)

let oneDay: Duration = initDuration(days=1)
const spawnIntervals: array[EntityKind, int] = [5, 20, 50]
const directionChangeInterval: int = 10
const msPerRound = 500

type
    CellKind* = enum
        land, water, desert

    Planet* = tuple
        dimensions: Vector2
        age: int
        cells: seq[CellKind]
        entities: seq[Entity]
        lastProcessed: DateTime


proc createEmptyPlanet*(w: int, h: int): Planet =
    let dimensions = (w, h)
    let entities: seq[Entity] = newSeq[Entity]()
    var cells: seq[CellKind] = newSeq[CellKind](w * h)
    result = (
        dimensions: dimensions,
        age: 0,
        cells: cells,
        entities: entities,
        lastProcessed: now().utc,
    )


func entityExists(entities: seq[Entity], pos: Vector2): bool =
    for e in entities:
        if e.position == pos:
            result = true
            return result
    result = false


proc findEntityIdx(entities: seq[Entity], pos: Vector2): int =
    for i, e in entities.pairs:
        if e.position == pos:
            return i
    return -1


proc isCellPassable*(p: Planet, pos: Vector2): bool =
    if pos.x >= p.dimensions.x or pos.y >= p.dimensions.y or pos.x < 0 or pos.y < 0:
        return false
    return p.cells[pos.x + pos.y * p.dimensions.x] != water


proc getCellInfo*(p: Planet, pos: Vector2): string =
    let idx: int = findEntityIdx(p.entities, pos)
    if idx >= 0:
        return $p.entities[idx].energy


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
    if not entityExists(p.entities, pos):
        if p.age mod spawnIntervals[grass] == 0:
            p.entities.add(createEntity(grass, pos, generator.sample(directions)))


    # create sheep if needed and the cell is free
    pos = (generator.rand(p.dimensions.x - 1), generator.rand(p.dimensions.y - 1))
    if not entityExists(p.entities, pos):
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
    var planet = createEmptyPlanet(50, 50)
    echo planet
