dofile('num2bit.lua')
---------------------------------
--
--  TESTING AREA FEEL FREE TO EDIT
--
---------------------------------

function getBitsAsString(bittbl, ...)
  local str = ""

  if type(bittbl) == 'table' then
    local n = getn(bittbl)
    local i = 1
    while i <= n do
      str = str .. tostring(bittbl[i])
      i = i + 1
    end
  elseif type(bittbl) == 'number' then
    str = tostring(mod_sn(bittbl,2))
  end

  if(getn(arg) > 0) then
    str = str .. " " ..  call(getBitsAsString,arg)
  end
  return str
end

function test(val,verbose)
  if verbose == 1 then
    print("=========\nTesting Value Value: " .. val)
  end
  local s,e,f,ev,fv = doubleToBits(val)
  local back = bitsToDouble(s,e,f)
  local exponentDecoded = bitsToInt(e) - 1023
  local mantisseAsInt = bitsToInt(f)
  if verbose == 1 then
    if val ~= back then
      print("=>Not equal, got : ", back)
      print("\tbits:" .. getBitsAsString(s,f,e))
      print("\texp",ev,"frac",fv)
      print("",ev,fv)

    -- exponent can only be [-1023,1024] integer , fraction can only be [1,2] decimal for normalized, [0,1] for unnormalized
    elseif ev < -1023 or ev > 1024 or fv < 0 or fv > 2 then
      print ("=> equal, but exponent or fraction is unexpected value")
    else
      print("=> equal " .. back)
    end
    print()
  end
  return val == back and not (ev < -1023 or ev > 1024 or fv < 0 or fv > 2)
end


-----------------------------------------------
--  TESTS
-----------------------------------------------


-------------------------------
--  Test Runner func
-------------------------------
function runtests(generator,verbose)
  local testsCount = 0
  local failures = 0
  local failed = ""

  local num = generator()
  while num ~= nil do
    if not test(num,verbose) then
      failures = failures + 1
      failed = failed .. " " .. num
    end

    if not test(-num,verbose) then
      failures = failures + 1
      failed = failed .. " " .. -num
    end
    testsCount = testsCount + 2
    num = generator()
  end

  return failures,testsCount,failed
end

function runteststable(tbl,verbose)
  manualTestsIt = 0
  testTable = tbl
  return runtests(
    function()
      manualTestsIt = manualTestsIt + 1
      return testTable[manualTestsIt]
    end,
    verbose
  )
end

------------------------
--  MANUAL TESTS
------------------------

test_numbers = {
  10.5,
  0.000005,
  10000000000000.5,
  2^1023 * 1.9999999999999998,
  0,
  1*0,
  2^-1024+2^-1023, -- 2^-1022 * 2^-1 = 2^-1022 exp * 0.5 mant
  2^-1025, -- 2^-1022 * 2^-1 = 2^-1022 exp * 0.5 mant
  2^-1074, -- 2^-1022 * 2^-1 = 2^-1022 exp * 0.5 mant
  DOUBLE_INF,
  DOUBLE_NEG_INF,
  2^-1023, -- 2^-1022 * 2^-1 = 2^-1022 exp * 0.5 mant
}
-- 1 to 1000 cuz why NOT
do
  local i = 1
  while i <= 1000 do
    tinsert(test_numbers,i)
    i = i  +1
  end
end

-- full 1's denormalized number
do
  local i = 1
  local val = 0
  while i <= 52 do
    val = val + 2^(-1022-i)
    i = i + 1
  end
  tinsert(test_numbers,val)
end

local failures,its,failed = runteststable(test_numbers,0)
--------------------------
--  Random Tests
-------------------------

randomTestCount = 0
local rfailures,rits,rfailed = runtests(
  function()
    if randomTestCount >= 15000 then return nil end

    randomTestCount = randomTestCount + 1
    return random()
  end,0
)
------------------------------
-- Denormalized tests
-------------------------------
dVal = 2^-1023
local dfailures,dits,dfailed = runtests(
  function()
    if dVal == 0 then return nil end
    local v = dVal
    dVal = dVal / 2
    return v
  end,0
)

--------------------------------
--  Power Of Two's tests
--------------------------------

local p2s = {}

local i = -1023

while i <= 1024 do
  tinsert(p2s,2^i)
  i = i + 1
end

local pfailures,pits,pfailed = runteststable(p2s)

print("===================")
print("Tests completed, " .. (its - failures) .. " / " .. its .. " passed")
print("Random tests completed, " .. (rits - rfailures)  .. " / " .. rits .. " passed")
print("Denorm tests completed, " .. (dits - dfailures)  .. " / " .. dits .. " passed")
print("2^x tests completed, " .. (pits - pfailures)  .. " / " .. pits .. " passed")
print("Tests that failed:" .. failed)
print("Random Tests that failed:" .. rfailed)
print("Denorm Tests that failed:" .. dfailed)
print("2^x Tests that failed:" .. pfailed)
