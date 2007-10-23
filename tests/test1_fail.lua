-------------------------------------------------------------------------------
-- Fake test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test1_fail.lua,v 1.1 2007/10/23 02:39:33 carregal Exp $
-------------------------------------------------------------------------------

print("Forcing a failure")
assert(true == false, "true went south!")

print("Agrouping contexts")
print("(for a failure)")
assert(true == false, "true went south!")