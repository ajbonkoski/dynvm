#!/usr/bin/node

if(process.argv.length != 3)
    process.exit()

var n = process.argv[2];
var a = 1;
var b = 0;
var SZ = Math.pow(2,32);

for(var i = 0; i < n; i++) {
    t = b;
    b = (a+b)%SZ;
    a = t;
}

console.log(b);
