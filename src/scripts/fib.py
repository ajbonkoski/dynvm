
n = 100000
SZ = 2**64

i = 0
a, b = 1, 0
while i < n:
    t = b
    b = (b + a) % SZ
    a = t
    i += 1

print b
