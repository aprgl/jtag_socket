#!/bin/bash
for i in `seq 1 100000`;
do
./test_message 9 0
./test_message 37 0
./test_message 26 0
sleep .005
done
