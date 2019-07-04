import random, times

const planetHeight*: uint8 = uint8.high
const planetWidth*: uint8 = uint8.high
const planetSize*: uint16 = planetHeight.int * planetWidth.int

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

    # main datastructure, singleton per player
    PlanetObj = object
        entityManager*: EntityManager
        generator*: Rand
        age*: int
        waterLevelHeight*: int
        heights*: array[planetSize, int]
        organisms*: array[planetSize, Organism]
        idx*: array[planetSize, uint16]
        lastProcessed*: DateTime
        paused*: bool

    Planet* = ref PlanetObj
