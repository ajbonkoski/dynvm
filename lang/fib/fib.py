#!/usr/bin/python
from sys import argv

def fib(n):
    SZ = 2**63

    i = 0
    a, b = 1, 0
    while i < n:
        t = b
        b = (a+b) & 0x7fffffffffffffff;
        a = t
        i += 1

    return b

if __name__ == '__main__':
    print fib(int(argv[1]))
