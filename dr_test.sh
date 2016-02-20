#!/bin/bash
for i in `seq 1 10000`;
do
./test_message 0 $i
sleep .25
done
