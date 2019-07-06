import random, times, json

const planetHeight*: uint16= uint8.high.uint16 + 1
const planetWidth*: uint16 = uint8.high.uint16 + 1
const planetSize*: uint32 = uint16.high.uint32 + 1

type
    # ecs - managers
    EntityManagerObj = object
        releasedIds*: seq[uint16]
        firstFreeId*: uint16

    EntityManager* = ref EntityManagerObj

    # ecs - components
    OrganismKind* = enum
        grass, sheep, human

    Organism* = tuple
        kind: OrganismKind
        energy: int
        age: int
        direction: int

    # main datastructure, singleton per player
    PlanetObj = object
        entityManager*: EntityManager
        generator*: Rand
        age*: int
        waterLevelHeight*: int
        heights*: array[planetSize, int]
        organisms*: array[planetSize, Organism]
        entityIds*: array[planetSize, uint16]
        lastProcessed*: DateTime
        paused*: bool
        trackedEntityId*: uint16

    Planet* = ref PlanetObj


func `%`*(o: Organism): JsonNode =
    return %*{
        "kind": o.kind.int,
        "energy": o.energy,
        "age": o.age,
        "direction": o.direction,
    }


when isMainModule:
    echo planetHeight
    echo planetSize
    let a: uint8 = 2.uint8

    echo a
    echo a + 1.uint8
    echo a + 255.uint8
