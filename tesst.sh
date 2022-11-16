#!/bin/bash


nb_pbs_test='9'

counter=0
for i in {1..50}
do

    ((counter++))
    echo $counter
    if [[ "$counter" == $nb_pbs_test ]]
    then
        break
    fi

done