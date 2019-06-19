var s: seq[int] = @[1,2,3,4,5,6,7,8,9]
var i = 0
let idx_delete: Natural = 1
while i < len(s):
    echo s[i]
    i += 1
    if i == 5:
        s.delete(idx_delete)
        if idx_delete < i:
            i -= 1

echo s

