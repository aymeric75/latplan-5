#!/bin/bash


if grep -Fxq "adadededed" total_invariants.txt
then
    echo "str found"
    # code if found
else
    echo "not found"
    # code if not found
fi
