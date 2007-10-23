-------------------------------------------------------------------------------
-- Fake test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test2_ok.lua,v 1.1 2007/10/23 02:39:40 carregal Exp $
-------------------------------------------------------------------------------

print("This simple test always passes")
assert(true == true, "true went postal!")

print("Agrouping contexts")
print("(for a pass)")
assert (true)