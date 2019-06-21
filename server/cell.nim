import json
import entity


type
    CellKind* = enum
        desert, land, water

    Cell* = tuple
        kind: CellKind
        entityRef: Entity


func emptyCell*(): Cell =
    return (kind: water, entityRef: nil)


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
