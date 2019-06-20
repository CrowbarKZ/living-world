import json
import vector

type
    EntityKind* = enum
        grass, sheep, human

    Entity* = tuple
        kind: EntityKind
        position: Vector2
        direction: Vector2
        energy: int
        age: int

const initialEnergy*: array[EntityKind, int] = [5, 50, 50]
const energyIncrement*: array[EntityKind, int] = [5, -1, -1]
const maxEnergy*: array[EntityKind, int] = [100, 100, 100]
const birthingAge: array[EntityKind, int] = [50, 50, 50]


proc `%`*(e: Entity): JsonNode =
    return %*{
        "kind": e.kind,
        "position": e.position,
        "direction": e.direction,
        "energy": e.energy,
        "age": e.age,
    }


proc createEntity*(kind: EntityKind, pos: Vector2, dir: Vector2): Entity =
    result = (
        kind: kind,
        position: pos,
        direction: dir,
        energy: initialEnergy[kind],
        age: 0,
    )


proc addEnergy*(e: var Entity, amount: int) {.discardable.} =
    e.energy += amount
    if e.energy > maxEnergy[e.kind]:
        e.energy = maxEnergy[e.kind]


proc canBirth*(e: Entity): bool =
    return e.age > birthingAge[e.kind] and e.energy > int(maxEnergy[e.kind] / 2)
