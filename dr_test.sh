#!/bin/bash
for i in `seq 1 100000`;
do
./test_message 8 $i
sleep .005
done
