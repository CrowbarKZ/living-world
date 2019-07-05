- sheep should not walk on water. They also should eat grass
- sheep breeding
- more consistent terrain coloring. Tie grass growing height threshold to snowy threshold
- fix save/load

Notes for blog
- simulation runs slow with about 10k entities :( (100 steps take longer than a second)
- data oriented design = https://www.youtube.com/watch?v=yy8jQgmhbAU

- getting rid of classes sped up things considerably
- rand call inside loop is expensive, goes from

```
processing step = 199900 num organisms = 33005 time taken = 0.0003379209999999633
processing step = 200000 num organisms = 33012 time taken = 0.0003454700000000699
```

to (50x slowdown)

```
processing step = 29900 num organisms = 6940 time taken = 0.01687572499999979
processing step = 30000 num organisms = 6962 time taken = 0.01673505300000011
```

fast way:
```
let turnSeed = p.generator.rand(3)
for y in 0.uint8..uint8.high:
    for x in 0.uint8..uint8.high:
        let pos: uint16 = x.uint16 + y.uint16 * planetWidth
        let entityId = p.idx[pos]
        if (entityId != 0 and p.organisms[entityId].kind == sheep):
            # calculate a new position 1 cell away vertically or horizontally
            var nx: uint8 = x
            var ny: uint8 = y
            # let a = p.generator.rand(3)
            let dirKey = (turnSeed.uint16 + entityId) mod 4
```

- writing to array is expensive
