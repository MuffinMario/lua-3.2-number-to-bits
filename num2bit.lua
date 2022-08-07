
-----------------------------------------
--
--    CONSTANTS
--
------------------------------------------
DOUBLE_INF = 2^1024
DOUBLE_NEG_INF= -2^1024

MAX_BITSIZE = 53 -- 64 bit IEEE 754 cannot represent 2^53 + 1, see https://stackoverflow.com/a/3793950 for explanation. Unused, but needed for future stuff


-----------------------------------------
--
--    UTILITY FUNCTIONS
--
------------------------------------------


-------------------------
-- Floors number, THIS IS NOT ACCURATE FOR BIG NUMBERS
-- TODO: replace with -1^sign * 2^exponent * <fractions min(52,exponent)>
-------------------------
function floorNumber(floatNumber)
  local stringmyValue = tostring(floatNumber)
  if strfind(stringmyValue, "(%.+)") ~= nil then
      local valuestring = strsub(stringmyValue, 1, strfind(stringmyValue, "(%.+)"))
      return tonumber(valuestring)
  else
      return floatNumber
  end
end

-------------------------
-- Rounds number up or down depending on <x.5 or >= x.5
-------------------------
function round(num)
  return floorNumber(num+0.5)
end

-------------------------
-- calculate modulo of two small numbers (NOT ACCURATE FOR BIG NUMBERS (>52 bits needed))
-------------------------
function mod_sn(a,b)
  return round((a/b - floorNumber(a/b)) * b)
end

-------------------------
-- Returns the absolute value of a number
-------------------------
function abs(a)
  return a >= 0 and a or (-1 * a)
end

-------------------------
-- Calculates the exponent of a number, basically just ceil(log2(dbl))-1 if I'm not mistaken
-------------------------
function calcExp(dbl)
  -- infinity, -infinity, NaN
  if dbl == DOUBLE_INF or dbl == DOUBLE_NEG_INF or dbl ~= dbl then
    return 1024
  end

  local e = 0
  local val = abs(dbl)
  -- unnormalized numbers
  if val <= 2^-1023 then -- NULL or denormalized
    return -1023
  end

  if val > 1 then
    while val >= 2 do
      e = e + 1
      val = val / 2
    end
  elseif val == 0 then
    return -1023 -- unnormalized 0
  elseif val < 1 then
    while val < 1 do
      e = e - 1
      val = val * 2
    end
  end

  return e --+ 1023 -- double bias exponent value
end

-------------------------
--  Returns the fraction of a number given the number and exponent of the number
-- Assumes value is not NaN
-------------------------
function calcFrac(dbl,ex)
  if ex < 1024 and ex > -1023 then
    return abs(dbl)/(2^ex)
  elseif ex == 1024 then
    return 0 -- inf to prevent overload
  else
    return abs(dbl) -- denormalized number, no exponent. or null
  end
end


-------------------------
--  Returns table of bits of a given 11 unsigned bit number
-------------------------
function expToBits(int)
  if int > 1024 or int < -1023 then
    return nil
  end

  local a = abs(int+1023)
  local bits = { 0,0,0, 0,0,0, 0,0,0, 0,0}
  local bit = 11

  while a >= 1 do
    local bitval = mod_sn(a,2)
    bits[bit] = bitval
    bit = bit - 1
    a = (a-bitval)/2 -- do we need -bitval here?
  end
  return bits
end
-------------------------
-- Returns table of bits of a given fraction (number from 1.0000000002 - 1.999999999998 (number of 0's and 9's may not be accurate))
-------------------------
function fracToBits(fra,exponent)
  if exponent > -1023 or fra == 0 then -- FP + inf + NULL case
    local begin = 1.5  --100000000000 (number of 0's may be inaccurate)
    local bit = 1
    local fracval = fra

    local bits = {}

    -- iterate all bits of fraction
    -- this goes from 1.5    (1000000000000000000000000000000000000000000000000000)
    -- to 1.0000000000000002 (0000000000000000000000000000000000000000000000000001)
    while begin >= 1.0000000000000002 do --000000000001(number of 0's may be inaccurate... again :p)
      -- check if our fraction has at least this value. if yes this means bit at current point is 1, else 0
      if fracval >= begin then
        -- subtract that fraction at bit so we can compare next again
        fracval = fracval - begin + 1
        bits[bit] = 1
      else
        bits[bit] = 0
      end

      bit = bit + 1
      begin = begin - (begin-1)/2
    end

    return bits
  else -- unnormalized case [2^-51 to 2^-1]
    local begin = 2^-1023 -- 100...0000 mant 000000000 exp


    local bits = {}
    local bit = 1

    local its = 52 -- bits

    while bit <= its do
      --print(fra,begin)
      if fra >= begin then
        bits[bit] = 1
        fra = fra - begin
      else
        bits[bit] = 0
      end

      -- prevent messy comparison, just compare if we reached the end
      if begin == ending then
        loopEnded = 1
      end
      bit = bit + 1
      begin = begin / 2
    end
    return bits
  end
end



---------------------
-- Returns fraction value from bit sequence (52 bits)
--------------------
function bitsToDoubleFraction(fragBits,normalized)
  if normalized then
    local begin = 1.5  --100000000000 (number of 0's may be inaccurate)
    local bit = 1
    local fracval = 1

    local bits = {}

    -- iterate all bits of fraction
    -- this goes from 1.5    (1000000000000000000000000000000000000000000000000000)
    -- to 1.0000000000000002 (0000000000000000000000000000000000000000000000000001)
    while begin >= 1.0000000000000002 do
      fracval = fracval + fragBits[bit] * (begin-1)

      bit = bit + 1
      begin = begin - (begin-1)/2
    end
    return fracval
  else -- denormalized (exp = 0)
    local begin = 2^-1023
    local bit = 1
    local fracval = 0

    local bits = {}

    local its = 52 -- bits

    while bit <= its do
      if fragBits[bit] == 1 then
        fracval = fracval + begin
      end

      -- prevent messy comparison, just compare if we reached the end
      if begin == ending then
        loopEnded = 1
      end
      bit = bit + 1
      begin = begin / 2
    end
    return fracval
  end
end

---------------------
-- Returns exponent value from bit sequence (11 bits)
--------------------
function bitsToDoubleExponent(expBits)
  local value = 0
  local i = 0
  while i < 11 do
    value = value + expBits[11-i] * 2^i
    i = i + 1
  end
  return value - 1023
end

-------------------------
-- Returns true if a parameter given is type number and not NaN
------------------------
function canReadNumber(number)
  return type(number) == 'number' and
    not (number ~= number)-- IEEE 754 standard says NaN is not equal to itself and we cannot work with NaN
end









------------------------------------------------------------------
--
--    CORE FUNCTIONS
--
------------------------------------------------------------------

----------------------
-- Takes a number (double-precision floating point number (IEEE 753))
-- And returns the bits for the sign, the exponent and the fraction
-- In format sign, exponent, fraction
-- additional return values contain the actual exponent value and then the actual fraction
-- to receive all values this function returns, do
-- sign,exponentBits,fractionBits,exponentValue,fractionValue
--
-- number has to fit into certain restrictions:
-- - cannot be NaN
-- - has to be type 'number'
----------------------
function doubleToBits(number)
    -- Check if we can read this number
    if not canReadNumber(number) then
      return nil
    end

    local sign = strbyte(number,1) == 45 -- '-' = 45      --(number >= 0)
                    and 1 or 0 -- 0 +     1 -
    local exponent = calcExp(number)
    local fraction = calcFrac(number,exponent)
    local exponentbits = expToBits(exponent)
    local fracbits = fracToBits(fraction,exponent)

    --print(  --"actual value",number,"\nsign",sign,"\nexponent",exponent,"\nfraction",fraction,
    --"\nresulting calculation -1^" ..tostring(sign) .. " x ".. tostring(fraction) .. " x 2^" .. tostring(exponent) .. " = " .. tostring(number) )
    return sign,exponentbits,fracbits,exponent,fraction
end

----------------------
-- Takes a combination of signbit (number. 0 for +, 1 for -), exponentBits (table of 11 bits), fractionBits (table of 52 bits)
-- to calculate the corresponding IEEE 754 number
--
-- will return nil if format fits NaN result
-- no boundary check. make sure your parameters are correct format + size
----------------------
function bitsToDouble(sign,exponentBits,fractionBits)

  local signfactor = (sign > 0) and -1 or 1
  local exponent = bitsToDoubleExponent(exponentBits)
  local fraction = bitsToDoubleFraction(fractionBits,exponent ~= -1023)

  -- NaN is nil. a loss of data is unavoidable
  if exponent == 1024 and fraction ~= 1 then return nil end

  --unnormalized case
  if exponent == -1023 and fraction ~= 0 then
    return signfactor * fraction
  elseif exponent == -1023 then
    return signfactor * 0
  end

  return signfactor * 2^exponent * fraction
end


---------------------------------
--  Converts a bit table to an integer.
--  Warning: loss at 54 bits
---------------------------------
function bitsToInt(bits)
  local val = 0
  local bitcount = getn(bits)
  local i = 1
  while i <= bitcount do
    val = val + 2^(i-1) * bits[bitcount - i + 1]
    i = i + 1
  end
  return val
end
