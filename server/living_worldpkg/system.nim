import random, sets, strformat
import types, entity

const spawnGrassInterval: int = 5  # turns
const initialGrassEnergy: int = 1
const spawnGrassMaxHeight: int = 7000


proc growGrass*(p: Planet) {.discardable.} =
    if p.age mod spawnGrassInterval == 0:
        let pos: uint16 = p.generator.rand(planetSize - 1).uint16
        # can't grow if something is already there
        if p.idx[pos] != 0:
            return

        # can't grow in water
        if p.heights[pos] <= p.waterLevelHeight:
            return

        # can't grow at high altitudes
        if p.heights[pos] >= spawnGrassMaxHeight:
            return

        try:
            let entityId: uint16 = p.entityManager.newEntity()
            p.idx[pos] = entityId
            p.organisms[entityId] = (grass, initialGrassEnergy, 0)
        except IndexError:
            return


proc spawnSheep*(p: Planet) {.discardable.} =
    if p.age mod 1 == 0:
        let pos: uint16 = p.generator.rand(planetSize - 1).uint16
        # can't spawn if something is already there
        if p.idx[pos] != 0:
            return

        # can't spawn in water
        if p.heights[pos] <= p.waterLevelHeight:
            return

        try:
            let entityId: uint16 = p.entityManager.newEntity()
            p.idx[pos] = entityId
            p.organisms[entityId] = (sheep, initialGrassEnergy, 0)
        except IndexError:
            return



proc grow*(p: Planet) {.discardable.} =
    discard


proc roam*(p: Planet) {.discardable.} =
    let turnSeed = p.generator.rand(3)
    var procseedIds = initHashSet[uint16]()
    for y in 0.uint8..uint8.high:
        for x in 0.uint8..uint8.high:
            let pos: uint16 = x.uint16 + y.uint16 * planetWidth
            let entityId = p.idx[pos]
            if (entityId == 0) or (entityId in procseedIds):
                continue
            if p.organisms[entityId].kind == sheep:
                # calculate a new position 1 cell away vertically or horizontally
                var nx: uint8 = x
                var ny: uint8 = y

                let dirKey = (turnSeed.uint16 + entityId) mod 4
                case dirKey:
                of 0:
                    nx += 1.uint8
                of 1:
                    nx -= 1.uint8
                of 2:
                    ny += 1.uint8
                else:
                    ny -= 1.uint8

                let newPos: uint16 = nx.uint16 + ny.uint16 * planetWidth

                if p.idx[newPos] == 0:  # new place is free
                    p.idx[newPos] = entityId
                    p.idx[pos] = 0
                    procseedIds.incl(entityId)
