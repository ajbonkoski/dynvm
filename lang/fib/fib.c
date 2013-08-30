#include <stdio.h>
#include <stdlib.h>
typedef unsigned long ulong;

int main(int argc, char *argv[])
{
    ulong SZ = (1L<<32);
    ulong n = atoi(argv[1]);
    ulong a = 1;
    ulong b = 0;
    ulong t;

    for(ulong i = 0; i < n; i++) {
        t = b;
        b = (a+b)%SZ;
        a = t;
    }

    printf("%lu\n", b);
    return 0;
}
