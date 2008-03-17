-------------------------------------------------------------------------------
-- Fake test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test1_ok.lua,v 1.2 2008/03/17 20:03:51 carregal Exp $
-------------------------------------------------------------------------------

print("This simple test always passes")
assert(true == true, "true went postal!")

local str = [[This is a multiline
text that involves
more than one line
indeed]]

print("Testing multiline asserts that works")
assert(str == [[This is a multiline
text that involves
more than one line
indeed]], "Multiline failed")

