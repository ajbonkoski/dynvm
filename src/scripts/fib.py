
def fib(n):
    SZ = 2**64

    i = 0
    a, b = 1, 0
    while i < n:
        t = b
        b = (b + a) % SZ
        a = t
        i += 1

    return b

if __name__ == '__main__':
    print fib(100000)
