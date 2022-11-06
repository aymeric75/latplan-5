#!/bin/bash

vari="$(cat essai.txt)"

echo $vari

if (( $(echo "$vari == 0.0" |bc -l) ))
then
    echo "equal zero"
fi