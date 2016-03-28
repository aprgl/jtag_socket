#!/bin/bash

for a in `seq 1 2`;
do
for i in `seq 1 30`;
do
./test_message 7 2
sleep .06
./test_message 7 1
sleep .06
./test_message 7 3
sleep .06
done

for i in `seq 1 30`;
do
./test_message 7 1
sleep .06
./test_message 7 2
sleep .06
./test_message 7 3
sleep .06
done
done
./test_message 7 0
