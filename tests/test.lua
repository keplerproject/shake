-------------------------------------------------------------------------------
-- Test suite for Shake
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: test.lua,v 1.1 2007/10/23 02:39:40 carregal Exp $
-------------------------------------------------------------------------------
require"shake"

local run
local summary
local results

-- checks if correct tests passes
local run = shake.runner()
run:test("test1_ok.lua")
run:test("test2_ok.lua")

results = run.results
assert(results.passed == 3, "Unexpected tests in results!")
assert(results.failed == 0, "Unexpected failures in results!")
assert(results.errors == 0, "Unexpected errors in results!")
assert(#results.suites == 2, "Unexpected suites in results!") 
assert(#results.suites[1].contexts == 1, "Unexpected groups in results!")

summary = run:summary()
assert(string.find(summary, "failed!") == nil, "Summary contains a failure message")
assert(string.find(summary, "has an error!!!") == nil, "Summary contains an error message")

-- checks if Shake is detecting failures
run = shake.runner()
run:test("test1_fail.lua")

results = run.results
assert(results.passed == 0, "Unexpected tests in results!")
assert(results.failed == 2, "Unexpected failures in results!")
assert(results.errors == 0, "Unexpected errors in results!")

summary = run:summary()
assert(string.find(summary, "failed!"), "Summary does not contains a failure message")
assert(string.find(summary, "has an error!!!") == nil, "Summary contains an error message")


-- checks if Shake is detecting errors
run = shake.runner()
run:test("test1_error.lua")

results = run.results
assert(results.passed == 0, "Unexpected tests in results!")
assert(results.failed == 0, "Unexpected failures in results!")
assert(results.errors == 1, "Unexpected errors in results!")
print(results.failed, results.errors)

summary = run:summary()
assert(string.find(summary, "failed!") == nil, "Summary contains a failure message")
assert(string.find(summary, "has an error!!!"), "Summary does not contains an error message")

