#!/usr/bin/python
from sys import argv

def fib(n):
    SZ = 2**32

    i = 0
    a, b = 1, 0
    while i < n:
        t = b
        b = (b + a) % SZ
        a = t
        i += 1

    return b

if __name__ == '__main__':
    print fib(int(argv[1]))
