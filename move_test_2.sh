#!/bin/bash
./test_message 4 1
for j in `seq 1 10`;
do
for i in `seq 1 1024`;
do
let var=$(($i\*2))
./test_message 15 $var
./test_message 9 0
sleep .005
done
done
./test_message 4 0
./test_message 4 0
./test_message 4 0
./test_message 4 0
