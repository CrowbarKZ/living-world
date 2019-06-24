import json, oids
import vector

type
    EntityKind* = enum
        grass, sheep, human

    EntityObj = object
        kind*: EntityKind
        position*: Vector2
        direction*: Vector2
        energy*: int
        age*: int
        oid: Oid

    Entity* = ref EntityObj

const initialEnergy*: array[EntityKind, int] = [5, 20, 20]
const energyIncrement*: array[EntityKind, int] = [1, -1, -1]
const maxEnergy*: array[EntityKind, int] = [20, 200, 200]
const birthingAge: array[EntityKind, int] = [50, 100, 100]


proc `%`*(e: Entity): JsonNode =
    return %*{
        "kind": e.kind,
        "position": e.position,
        "direction": e.direction,
        "energy": e.energy,
        "age": e.age,
        "oid": $e.oid,
    }


proc newEntity*(kind: EntityKind, pos: Vector2, dir: Vector2): Entity =
    return Entity(
        kind: kind,
        position: pos,
        direction: dir,
        energy: initialEnergy[kind],
        age: 0,
        oid: genOid(),
    )


proc addEnergy*(e: Entity, amount: int) {.discardable.} =
    e.energy += amount
    if e.energy > maxEnergy[e.kind]:
        e.energy = maxEnergy[e.kind]


proc canBirth*(e: Entity): bool =
    return e.age > birthingAge[e.kind] and e.energy > int(maxEnergy[e.kind].float * 0.75)
