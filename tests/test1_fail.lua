-------------------------------------------------------------------------------
-- Fake test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test1_fail.lua,v 1.4 2008/07/17 17:12:58 carregal Exp $
-------------------------------------------------------------------------------

print("Forcing a failure")
assert(true == false, "booleans went south!")

print("Agrouping contexts")
assert(x == 3)

print("using print")
assert(true == false, "true went south!")

-- testing the comments for a new context
assert(x == 2, "what x?")

print("this should not create a new context")
print("nor this")
print("but this one should")
assert (function() return end == 4 + 34)


-- and you can create contexts
-- by using a multi line comment
-- too
assert(x == 6, "see?")

local str = [[This is a multiline
text that involves
more than one line
indeed]]

print("Testing multiline asserts that fails")
assert(str == [[This is
a multiline
text that
fails]], "Multiline failed, but expectedly")

print("Testing multiline asserts that fails - part 2")
assert(str == [[This is
a multiline text that also fails,
but the point is what line numbers are
reported]], "Multiline failed, but expectedly")

print("Forcing a failure so we can check line number counting")
assert(2 == 3, "What?")

-- The tests below do not work yet, since Leg is considering the second assert as a single line
--print("Testing multiline asserts that fails - part 3")
--assert(nil, 1)
--assert(nil
--   , 2)
--assert(0 == 1, 4)
--assert(1 == 2, 5)

--print("Trying to call an user assert function")
--local t = {["assert"] = function() end}
--t.assert(x == 2) -- should be shaken but not stirred

--print("Trying to call the global assert but disguised as a table field")
--local base = _G
--base.assert(x == true) -- Should be captured as a valid test but without the metadata

-- last test
assert(x == false)
