#!/bin/bash
for i in `seq 1 100000`;
do
./test_message 0 $i
sleep .00001
done
