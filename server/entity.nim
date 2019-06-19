type
    Vector2* = tuple
        x, y: int

    DirectionName* = enum
        north, east, south, west

    EntityKind* = enum
        grass, sheep, human

    Entity* = tuple
        kind: EntityKind
        position: Vector2
        direction: Vector2
        energy: int
        age: int

let directions*: array[DirectionName, Vector2] = [
    (0, 1),  # north
    (1, 0),  # east
    (0, -1),  # south
    (-1, 0),  # west
]

const initialEnergy*: array[EntityKind, int] = [5, 50, 50]
const energyIncrement*: array[EntityKind, int] = [5, -1, -1]
const maxEnergy*: array[EntityKind, int] = [100, 100, 100]
const birthingAge: array[EntityKind, int] = [50, 50, 50]


proc `+`*(v1: Vector2, v2: Vector2): Vector2 =
    result = (v1.x + v2.x, v1.y + v2.y)


proc nextDir*(dir: Vector2): Vector2 =
    let idx = directions.find(dir)
    let newIdx = (idx + 1) mod directions.len
    return directions[newIdx.DirectionName]


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
