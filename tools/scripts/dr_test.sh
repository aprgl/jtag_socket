#!/bin/bash
for i in `seq 1 100000`;
do
../send_message 8 $i
echo $i
sleep .005
done
