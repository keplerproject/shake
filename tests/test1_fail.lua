-------------------------------------------------------------------------------
-- Fake test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test1_fail.lua,v 1.2 2007/10/24 23:41:05 carregal Exp $
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