
n = 100000

i = 0
a, b = 1, 0
while i < n:
    t = b
    b += a
    a = t
    i += 1

print b
