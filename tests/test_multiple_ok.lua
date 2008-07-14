-------------------------------------------------------------------------------
-- Test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test_multiple_ok.lua,v 1.1 2008/07/14 21:10:14 carregal Exp $
-------------------------------------------------------------------------------

-- Testing the use of multiple files for tests

local func, msg

func, msg = loadfile("test1_ok.lua")
print("first ok?")
assert(func)
func()

func, msg = loadfile("test2_ok.lua")
assert(func)
func()
