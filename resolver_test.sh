#!/bin/bash
for i in `seq 1 100000`;
do
./test_message 9 0
sleep .005
done
