# lua-3.2-number-to-bits
A library-less script converting a double-precision floating point number (IEEE-754) to its binary representation consisting of sign,exponent and fraction for lua 3.2. With very slight changes to the names of the lua string functions used, this can also be used in any lua version as it mostly relies on arithmetic calculation. 

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

# Drift-Off: Floating-point number representations
The implementation of floating point numbers can cover a very big range of numbers. This comes at a cost of a few things: complexity, computing power and the fact that not every number between the smallest and highest number can be represented.
In our example we are dealing with 64-bit (double-precision) floating point numbers, so I will use these to explain the following.
Every 64-bit floating point number (in the IEEE 754 standard) consists of three things:
- The sign bit flag. A 1 bit sized segment of the number determining if the number is negative (1) or positive (0)
- An 11 bit segment representing the exponent. This segment is read as any other integer in binary. But since we also want to represent really small numbers, we set the bias of this number to -1023. So the integer will be subtracted by 1023, which will result in the final exponent we are going to use.
- A 52 bit segment representing the mantisse/fraction of this number. It is the "comma" part of the number. Implicitly we always have a 1. infront of the fraction to reduce redundancy. Basically every nth bit (starting from 1) in this segment is representative of the value 1/(2^n). so for example 0100... would be the number 0.25 (1.25 with implicit 1)

Now that we know all that, we can finally go and actually calculate a number. To calculate a number with this information we simply calculate (-1)^(signbit) * 2^(exponent-1023) * fraction giving us a number to calculate. If you take a minute to think about it. You'll see that it is not possible to calculate the number 0 (fraction is always >= 1, exponent can only go as low as -1023). Now this is where we have special cases to cover these issues. In the IEEE-754 standard, there are 4 special cases to cover various issues.

- Case 1 & 2: exponent = 0 (biased: -1023)
  - Fraction = 0: Value = 0 (or -0 if sign bit is 1)
  - Fraction != 0: Value is [denormalized](https://en.wikipedia.org/wiki/Subnormal_number) (fraction does not have 1. in the front, exponent is interpreted as -1022 still)
- Case 3 & 4: exponent = 2047 (biased: 1024)
  - Fraction = 0: Value is either +infinity or -infinity
  - **Fraction != 0: Value is Not a Number (NaN)**



# Restraints 
Now that we know all of this, let's go back to the library. It is not possible do any calculations with NaN (Not a Number) to any possible number and hence it is not possible to modify/read any number with value NaN. If your number becomes NaN the information of the object has been lost. Make sure that your number never reaches exp=1024 && fraction != 0 (for example by forcefully setting an exponent bit to 0). 
