# lua-3.2-number-to-bits
A library-less script converting a double-precision floating point number (IEEE-754) to its binary representation consisting of sign,exponent and fraction for lua 3.2.

# Library
There are two functions that are of primary interest:

# doubleToBits(number)
Takes a number (double-precision floating point number (IEEE 753)) and returns the bits split into the three segments of a double-precision number (sign,exponent,mantisse)

Returns up to 5 variables in the following order:
- sign
  - The bit value of the sign bit (0 for positive number, 1 for negative number)
- exponentBitTable
  - An 11 element table containing the **biased** (number + 1023) bits of the exponent part of the given number
- fractionBitTable 
  - A 52 element table containing the bits of the  mantisse of the given number
- exponentValue 
  - The integer representation of the exponentBitTable.
- fractionValue
  - The decimal representation of the mantisse. [1,2] for normalized values, [0,1) for unnormalized values
  
# bitsToDouble(sign,exponentBits,fractionBits)
Takes a combination of signbit (number. 0 for +, 1 for -), exponentBits (table of 11 bits), fractionBits (table of 52 bits) to calculate and return the corresponding double-precision IEEE 754 number


# Example
```lua
local myNumber = 10.5
-- ignore exponentValue and fractionValue for this example.
-- sign = 0 (positive)
-- ex = {1,0,0,0,0,0,0,0,0,1,0} (unbiased 1026; biased: 1026 - 1023 = 3)
-- fr = {0,1,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0} (1.3125)
-- (according to calculation, this number should be -1^sign * 2^exponent * fraction = -1^0 * 2^3 * 1.3125 = 10.5)
local sign,ex,fr = doubleToBits(myNumber)


--example 1, changing sign bit
print(bitsToDouble(1,ex,fr)) -- we modify the sign bit and now get -10.5

--example 2, changing exponent bit
-- modify
ex[11] = 1 -- exponent 3 => 4 (technically myNumber * 2)
print(bitsToDouble(sign,ex,fr)) -- from 10.5, we now get 21, so it did what we expected it to :)

```

# Restraints 
As it is not possible to convert from NaN (Not a Number) back to any possible calculation or identificcation, it is not possible to modify/read any number with value NaN. If your number becomes NaN the information of the object has been lost. Make sure that your number never reaches exp=1024 && fraction != 0 (for example by forcefully setting an exponent bit to 0)
