#!/bin/bash
for i in `seq 1 255`;
do
../send_message $i 0
echo $i
sleep .001
done
