import random, sets, strformat
import types, entity

# consts for grass, sheep, human
const spawnInterval = [5, 10, 20]  # turns
const spawnInitialEnergy = [1, 30, 30]
const spawnMaxHeight = [7000, 7000, 7000]
const energyIncrement = [1, -1, -1]
const directionChangeInterval = [0, 6, 6]


proc spawnEntityAt*(p: Planet, kind: OrganismKind, pos: uint16) {.discardable.} =
    # can't spawn if something is already there
    if p.entityIds[pos] != 0:
        return

    # can't spawn in water
    if p.heights[pos] <= p.waterLevelHeight:
        return

    # can't spawn at high altitudes
    if p.heights[pos] >= spawnMaxHeight[kind.int]:
        return

    try:
        let entityId: uint16 = p.entityManager.newEntity()
        p.entityIds[pos] = entityId
        p.organisms[entityId] = (kind, spawnInitialEnergy[kind.int], 0, 0)
    except IndexError:
        return


proc spawnGrass*(p: Planet) {.discardable.} =
    if p.age mod spawnInterval[grass.int] == 0:
        let pos: uint16 = p.generator.rand(planetSize - 1).uint16
        p.spawnEntityAt(grass, pos)


proc spawnSheep*(p: Planet) {.discardable.} =
    if p.age mod spawnInterval[sheep.int] == 0:
        let pos: uint16 = p.generator.rand(planetSize - 1).uint16
        p.spawnEntityAt(sheep, pos)


proc removeEntity(p: Planet, pos: uint16) {.discardable.} =
    let entityId = p.entityIds[pos]
    p.entityManager.deleteEntity(entityId)
    p.entityIds[pos] = 0

    if p.trackedEntityId == entityId:
        p.trackedEntityId = 0


proc processExistingOrganisms*(p: Planet) {.discardable.} =
    ## handle everything related to existing organisms in one place
    ## to avoid looping through entityIds several times
    let turnSeed = p.generator.rand(3)
    var procseedIds = initHashSet[uint16]()

    for y in 0.uint8..uint8.high:
        for x in 0.uint8..uint8.high:

            let pos: uint16 = x.uint16 + y.uint16 * planetWidth
            let entityId = p.entityIds[pos]

            # no entity at this idx, nothing to do
            if (entityId == 0) or (entityId in procseedIds):
                continue

            let kind = p.organisms[entityId].kind

            # increment energy and age
            p.organisms[entityId].age += 1
            p.organisms[entityId].energy += energyIncrement[kind.int]
            if p.organisms[entityId].energy <= 0:
                p.removeEntity(pos)
                continue

            if kind == sheep:
                # calculate a new position 1 cell away vertically or horizontally
                var nx: uint8 = x
                var ny: uint8 = y

                if p.age mod directionChangeInterval[sheep.int] == 0:
                    p.organisms[entityId].direction = int((turnSeed.uint16 + entityId) mod 4)

                case p.organisms[entityId].direction:
                of 0:
                    nx += 1.uint8
                of 1:
                    nx -= 1.uint8
                of 2:
                    ny += 1.uint8
                else:
                    ny -= 1.uint8
                let newPos: uint16 = nx.uint16 + ny.uint16 * planetWidth

                # if new place is free and walkable -> walk there
                if (p.entityIds[newPos] == 0 and p.heights[newPos] > p.waterLevelHeight):
                    p.entityIds[newPos] = entityId
                    p.entityIds[pos] = 0
                    procseedIds.incl(entityId)

                # if new place is taken by grass -> eat grass
                # if new place is taken by sheep -> try to breed
