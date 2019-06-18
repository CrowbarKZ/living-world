const grassInitialEnergy = 10
const grassEnergyIncrement = 5


type
    Vector2* = tuple
        x, y: int

    EntityKind* = enum
        grass, sheep, human

    Entity* = tuple
        kind: EntityKind
        position: Vector2
        direction: Vector2
        energy: int


proc createEntity*(pos: Vector2, kind: EntityKind): Entity =
    case kind:
    of grass:
        result = (
            kind: grass,
            position: pos,
            direction: (0, 0),
            energy: grassInitialEnergy,
        )
    else:
        result = (
            kind: grass,
            position: pos,
            direction: (0, 0),
            energy: 10,
        )


proc step*(e: var Entity) {.discardable.} =
    case e.kind:
    of grass:
        e.energy += grassEnergyIncrement
    of sheep:
        discard
    of human:
        discard



