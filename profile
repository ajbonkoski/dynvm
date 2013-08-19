#!/bin/bash
make prof && cat $1 | ./bin/dynvm-profile - $2
