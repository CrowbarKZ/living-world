import msgpack4nim, streams


type
    Vector2 = tuple
        x, y: int

    CellType* = enum
        land, water, desert

    Entity = tuple
        position: Vector2
        direction: Vector2
        energy: int

    Planet* = tuple
        dimensions: Vector2
        age: int
        cells: seq[CellType]
        entities: seq[Entity]


func createEmptyPlanet*(w: int, h: int): Planet =
    let dimensions = (w, h)
    let entities: seq[Entity] = newSeq[Entity](0)
    var cells: seq[CellType] = newSeq[CellType](w * h)
    result = (dimensions: dimensions, age: 0, cells: cells, entities: entities)


func toMsgPack*(p: Planet): string =
    result = pack(p)


when isMainModule:
    var planet = createEmptyPlanet(50, 50)
    planet.entities.add((position: (0, 0), direction: (0, 1), energy: 0))
    echo planet
