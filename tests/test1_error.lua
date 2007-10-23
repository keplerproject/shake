-------------------------------------------------------------------------------
-- Fake test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test1_error.lua,v 1.1 2007/10/23 02:39:40 carregal Exp $
-------------------------------------------------------------------------------

print("Forcing an error")
assert(_not_a_table.field == 1, "Strings don't have fields!")

print("Agrouping contexts")
print("(for an error)")
assert(true, "this should not be considered a test since the previous error will stop the run")