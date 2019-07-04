import random
import types, entity

const spawnGrassInterval: int = 10  # turns
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
            echo "spawned grass at ", pos
        except IndexError:
            return



proc grow*(p: Planet) {.discardable.} =
    discard


proc roamSystem(p: Planet) {.discardable.} =
    discard
