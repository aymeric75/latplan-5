#!/usr/bin/env python3
import sys


#  return if str1 < str2


def main():
    nb1 = float(sys.argv[1])
    nb2 = float(sys.argv[2])
    #print(nb1)
    #print(nb2)
    if nb1 <= nb2:
        return 1
    else:
        return 0

if __name__ == '__main__':
    print(main())

