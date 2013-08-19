#!/usr/bin/python
from sys import argv

def cpa(n):
  a = 5*9
  b = 3*4
  c = 3/2*2

  i = 0

  while i<n:
    a = a - b + 5 - 6 + c - 1
    i = i+1

  return a

if __name__ == '__main__':
  print cpa(int(argv[1]))
