## Planet
## This is the primary data structure we operate on, contains everything game - related
## Needs to be stored to save game state

import times, typetraits, random, math, json, strutils
import perlin
import vector, entity, cell

randomize()
let now = getTime()
let seed = now.toUnix + now.nanosecond
var generator = initRand(seed)

const timeFmt = "yyyy-MM-dd HH:mm:ss"
const oneDay: Duration = initDuration(days=1)
const spawnIntervals: array[EntityKind, int] = [5, 20, 50]
const directionChangeInterval: int = 10
const msPerRound = 500

type
    PlanetObj = object
        dimensions: Vector2
        age: int
        cells: seq[Cell]
        entities: seq[Entity]
        lastProcessed: DateTime
        paused: bool

    Planet* = ref PlanetObj


proc `%`*(p: Planet): JsonNode =
    return %*{
        "dimensions": p.dimensions,
        "age": p.age,
        "cells": p.cells,
        "entities": p.entities,
        "lastProcessed": p.lastProcessed.format(timeFmt),
        "paused": p.paused
    }


proc emptyPlanet*(w: int, h: int): Planet =
    let dimensions = (w, h)
    let entities: seq[Entity] = newSeq[Entity]()
    var cells: seq[Cell] = newSeq[Cell](w * h)

    let seed = generator.rand(uint32.high).uint32
    let noise = newNoise(seed.uint32, 1, 0.5)

    for x in 0..<w:
        for y in 0..<h:
            cells[x + y * w] = newCell(noise.perlin(x, y).noiseToCellKind, nil)

    result = Planet(
        dimensions: dimensions,
        age: 0,
        cells: cells,
        entities: entities,
        lastProcessed: now().utc,
        paused: false,
    )


proc pause*(p: var Planet) {.discardable.} =
    p.paused = true


proc unpause*(p: var Planet) {.discardable.} =
    p.paused = false
    p.lastProcessed = now().utc


func getCell(p: Planet, pos: Vector2): Cell =
    if pos.x >= p.dimensions.x or pos.y >= p.dimensions.y or pos.x < 0 or pos.y < 0:
        return emptyCell()
    return p.cells[pos.x + pos.y * p.dimensions.x]


func mgetCell(p: var Planet, pos: Vector2): var Cell =
    return p.cells[pos.x + pos.y * p.dimensions.x]


proc createEntity*(p: var Planet, kind: EntityKind, pos: Vector2) {.discardable.} =
    ## properly creates entity and cell reference for it
    var cell: Cell = p.getCell(pos)
    if not (cell.isPassable and cell.isFree):
        return

    if kind == grass and not cell.isGrowable:
        return

    let e: Entity = newEntity(kind, pos, generator.sample(directions))
    p.entities.add(e)
    p.mgetCell(pos).entityRef = e


proc addEntity*(p: var Planet, e: Entity) {.discardable.} =
    ## adds entity reference to entities and cells
    ## unlike createEntity this skips all checks (used for loading a save)
    p.getCell(e.position).entityRef = e
    p.entities.add(e)


proc deleteEntity(p: var Planet, pos: Vector2, idx: int) {.discardable} =
    ## deletes entity reference from cells and entities
    p.mgetCell(pos).entityRef = nil
    p.entities.delete(idx)


proc moveEntity(p: var Planet, e: Entity, newPos: Vector2) {.discardable} =
    ## moves entity to a new position
    p.mgetCell(e.position).entityRef = nil
    e.position = newPos
    p.mgetCell(newPos).entityRef = e


proc setCellKind*(p: var Planet, kind: CellKind, pos: Vector2) {.discardable.} =
    ## also deletes entities at pos
    if pos.x >= p.dimensions.x or pos.y >= p.dimensions.y or pos.x < 0 or pos.y < 0:
        return
    p.mgetCell(pos).kind = kind
    let idx = p.entities.find(p.getCell(pos).entityRef)
    if idx >= 0:
        p.deleteEntity(pos, idx)


func getCellJson*(p: Planet, pos: Vector2): JsonNode =
    let cell = p.getCell(pos)
    result = %*{
        "pos": pos,
        "cell_kind": cell.kind,
        "isFree": cell.isFree,
        "isPassable": cell.isPassable,
        "isGrowable": cell.isGrowable,
    }

    if cell.entityRef != nil:
        result["entity"] = %cell.entityRef


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
        let targetCell = p.getCell(newPos)

        if targetCell.isPassable:
            if not targetCell.isFree:
                case targetCell.entityRef.kind:
                of grass:
                    # eat grass
                    e.addEnergy(targetCell.entityRef.energy)
                    return p.entities.find(targetCell.entityRef)
                of sheep:
                    # give birth
                    let birthPos = e.position + e.direction.nextDir
                    # let birthCell = p.getCell(birthPos)
                    # if (birthCell.isPassable and e.canBirth and targetCell.entityRef.canBirth):
                    #     e.energy = int(e.energy.float * 0.3)
                    #     targetCell.entityRef.energy = int(targetCell.entityRef.energy.float * 0.3)
                    #     p.createEntity(sheep, birthPos)
                    # e.direction = generator.sample(directions)
                else:
                    discard
            else:
                p.moveEntity(e, newPos)
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
        var entity = p.entities[i]
        let delIdx = stepEntity(p, entity)
        if delIdx > 0:
            p.deleteEntity(entity.position, delIdx)
        else:
            inc(i)

    # create grass if needed and the cell is free
    var pos: Vector2 = (generator.rand(p.dimensions.x - 1), generator.rand(p.dimensions.y - 1))
    var cell = p.getCell(pos)
    if cell.isGrowable and cell.isFree:
        if p.age mod spawnIntervals[grass] == 0:
            p.createEntity(grass, pos)

    # create sheep if needed and the cell is free
    pos = (generator.rand(p.dimensions.x - 1), generator.rand(p.dimensions.y - 1))
    cell = p.getCell(pos)
    if cell.isPassable and cell.isFree:
        if p.age mod spawnIntervals[sheep] == 0:
            p.createEntity(sheep, pos)


proc process*(p: var Planet) {.discardable.} =
    if p.paused:
        return

    let newNow: DateTime = now().utc
    echo "new now = ", newNow
    var dt: Duration = newNow - p.lastProcessed
    if dt > oneDay:
        dt = oneDay

    let numsteps = (dt.inMilliseconds.int / msPerRound).round.int
    if numsteps == 0:
        return

    if numsteps > 1:
        echo "processing steps ", numsteps

    for i in 0..<numsteps:
        if i mod 100 == 0:
            echo "processing step = ", i
        step(p)
    p.lastProcessed = newNow


proc newPlanetFromText*(s: string): Planet =
    ## create a planet from its text-json representation
    var node: JsonNode
    try:
        node = parseJson(s)
        result = emptyPlanet(node["dimensions"]["x"].getInt, node["dimensions"]["y"].getInt)
        result.lastProcessed = parse(node["lastProcessed"].getStr, timeFmt, utc())
        echo result.lastProcessed
        for idx, c in node["cells"].getElems:
            result.cells[idx].kind = parseEnum[CellKind](c.getStr)
        for n in node["entities"].getElems:
            let e: Entity = newEntityFromJson(n)
            result.addEntity(e)

    except JsonParsingError, KeyError, ValueError:
        echo "failed to parse planet data from text: ", getCurrentExceptionMsg()
        return result


when isMainModule:
    let t0 = cpuTime()

    var p: Planet = emptyPlanet(50, 50);
    for i in 0..100000:
        if i mod 100 == 0:
            echo "processing step = ", i, " num entities = ", p.entities.len
        step(p)

    echo cpuTime() - t0
