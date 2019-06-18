import times, typetraits, random, math
import msgpack4nim
import entity

let now = getTime()
var generator = initRand(now.toUnix * 1000000000 + now.nanosecond)

const grassInterval: uint8 = 5
let oneDay: Duration = initDuration(days=1)


type
    CellKind* = enum
        land, water, desert

    Planet* = tuple
        dimensions: Vector2
        age: int
        cells: seq[CellKind]
        entities: seq[Entity]
        lastProcessed: DateTime
        grassTimer: uint8


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
        grassTimer: 0.uint8,
    )


func entityExists(entities: seq[Entity], pos: Vector2): bool =
    for e in entities:
        if e.position == pos:
            result = true
            return result
    result = false


proc find(entities: seq[Entity], pos: Vector2): int =
    for i, e in entities.pairs:
        echo e.position
        if e.position == pos:
            return i
    result = -1


proc getCellInfo*(p: Planet, pos: Vector2): string =
    let idx: int = find(p.entities, pos)
    if idx >= 0:
        return $p.entities[idx].energy


proc step(p: var Planet) {.discardable.} =
    # process existing entities
    for e in p.entities.mitems:
        step(e)

    # create grass if needed and the cell is free
    var pos: Vector2 = (generator.rand(p.dimensions.x - 1), generator.rand(p.dimensions.y - 1))
    if not entityExists(p.entities, pos):
        if p.grassTimer mod grassInterval == 0:
            p.entities.add(createEntity(pos, grass))
        p.grassTimer += 1


proc process*(p: var Planet) {.discardable.} =
    let newNow: DateTime = now().utc
    var dt: Duration = newNow - p.lastProcessed
    if dt > oneDay:
        dt = oneDay

    let numsteps = (dt.inMilliseconds.int / 1000).round.int
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
