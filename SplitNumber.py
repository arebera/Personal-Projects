## Function to split a decimal number into specified number of constituents
import random

def splitNumber(x,n):

    # Converting rainfall measurement to integer
    x = int(x * 100)
    i = 1
    splitList = list()

    # Find constituent values of a number
    while i < n:
        split = random.randrange(0, x)
        x = x - split
        i += 1
        split = float(split / 100)
        print(split)
        splitList.append(split)

    x = float(x / 100)
    print(x)
    splitList.append(x)

    return splitList