#!/bin/bash +x

echo "111111111"
echo $1

echo "2222222222222"
echo $2

echo "3333333333333"
echo $3

planner-scripts/limit.sh -t 600 -m 8000000 -- "planner-scripts/fd-latest-clean -o '$1' -- $2 $3"
