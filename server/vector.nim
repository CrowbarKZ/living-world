## 2D Vector routines

import json

type
    Vector2* = tuple
        x, y: int

    DirectionName* = enum
        north, east, south, west

let directions*: array[DirectionName, Vector2] = [
    (0, 1),  # north
    (1, 0),  # east
    (0, -1),  # south
    (-1, 0),  # west
]


proc `+`*(v1: Vector2, v2: Vector2): Vector2 =
    result = (v1.x + v2.x, v1.y + v2.y)


proc `%`*(v: Vector2): JsonNode =
    return %*{"x": v.x, "y": v.y}


proc nextDir*(dir: Vector2): Vector2 =
    ## returns next direction clockwise
    let idx = directions.find(dir)
    let newIdx = (idx + 1) mod directions.len
    return directions[newIdx.DirectionName]
