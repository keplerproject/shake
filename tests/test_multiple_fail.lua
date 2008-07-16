-------------------------------------------------------------------------------
-- Test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test_multiple_fail.lua,v 1.1 2008/07/16 18:32:10 carregal Exp $
-------------------------------------------------------------------------------

-- Testing the use of multiple files for tests

local func, msg

func, msg = loadfile("test1_fail.lua")
func()