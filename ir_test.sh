#!/bin/bash
for i in `seq 1 255`;
do
./test_message $i 0
sleep .1
done
