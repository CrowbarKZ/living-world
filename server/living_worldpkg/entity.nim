import types

## Entity (of ecs)
## is a uint16 id serving as a way to find components

func newEntityManager*(): EntityManager =
    return EntityManager(
        releasedIds: newSeq[uint16](),
        firstFreeId: 1.uint16,
    )


proc newEntity*(em: EntityManager): uint16 =
    if em.releasedIds.len > 0:
        return em.releasedIds.pop()
    else:
        if em.firstFreeId >= planetSize:
            raise newException(IndexError, "No free entity ids left")
        result = em.firstFreeId
        inc(em.firstFreeId)
        return result


proc deleteEntity*(em: EntityManager, id: uint16) {.discardable.} =
    em.releasedIds.add(id)
