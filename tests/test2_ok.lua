-------------------------------------------------------------------------------
-- Fake test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test2_ok.lua,v 1.3 2008/07/17 17:12:58 carregal Exp $
-------------------------------------------------------------------------------

print("This simple test always passes")
assert(true == true, "true went postal!")

print("Agrouping contexts")
print("(for a pass)")
assert (true)

print("Trying to load a non existent file")
local f, err = loadfile("__N_0_f_i_l_3")
assert (f == nil)
assert (err)

--print("Trying to call an user assert function")
--local t = {["assert"] = function() end}
--t.assert(x == true) -- should be shaken but not stirred
