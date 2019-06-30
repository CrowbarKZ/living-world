## Cell
## makes space on a planet
## can be inhabited only by 1 entity at any time

import json
import entity

type
    CellKind* = enum
        desert, land, water

    CellObj = object
        kind*: CellKind
        entityRef*: Entity  ## acts as index for searching entities by their position on a planet

    Cell* = ref CellObj


proc `%`*(c: Cell): JsonNode =
    return %c.kind


func newCell*(kind: CellKind, entityRef: Entity): Cell =
    return Cell(kind: kind, entityRef: entityRef)


func emptyCell*(): Cell =
    return Cell(kind: water, entityRef: nil)


func noiseToCellKind*(f: float): CellKind =
    ## converts perlin noise output 0..1 float to CellKind
    if f < 0.4:
        return desert
    elif f >= 0.4 and f <= 0.7:
        return land
    else:
        return water


func isPassable*(c: Cell): bool =
    return c.kind != water


func isGrowable*(c: Cell): bool =
    return c.kind == land


func isFree*(c: Cell): bool =
    return c.entityRef == nil
