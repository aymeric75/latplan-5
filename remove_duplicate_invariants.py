#!/usr/bin/env python3
import sys

def return_invariant_list(file):
    retour = []
    with open(file) as f:
        total_string = ",".join(line.strip() for line in f)
        arr_of_invariants = total_string.split("#")
        for inv in arr_of_invariants:
            arr_of_vars = inv.split(",")
            #print(arr_of_vars)
            inv_arr = list(filter(None, arr_of_vars))
            # if inv_var not empty
            if inv_arr:
                retour.append(inv_arr)
        return retour

#def construct_inv_file(liste):

def remove_duplicates(new_liste):
    # remove obvious duplicates
    # new_liste = list(dict.fromkeys(liste))

    last_list = []
    for i in range(len(new_liste)):
        has_duplicate = False
        for j in range(i+1, len(new_liste)):
            if (new_liste[i][0] in new_liste[j] and new_liste[i][1] in new_liste[j]):
                has_duplicate = True
        if not has_duplicate:
            last_list.append(new_liste[i])
    
    return last_list

def main():
    dup_list = return_invariant_list(sys.argv[1])
    print(dup_list)
    print(" ")
    print(" ")
    print(remove_duplicates(dup_list))

# DUPLICATE between two lists if l1 and l2
# if l1[0] in l2 && l1[1] in l2
 
if __name__ == '__main__':
    main()

