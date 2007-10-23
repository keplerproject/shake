-------------------------------------------------------------------------------
-- Shake, a simple test engine for Lua
--
-- Authors: Andre Carregal
-- Copyright (c) 2007 Kepler Project
--
-- $Id: shake.lua,v 1.1 2007/10/23 02:39:40 carregal Exp $
-------------------------------------------------------------------------------

local getinfo = debug.getinfo
local traceback = debug.traceback
local table = require "table"
local io = require "io"
local _G, error, loadfile, pcall, xpcall, ipairs, setmetatable = _G, error, loadfile, pcall, xpcall, ipairs, setmetatable

module(...)


-- Returns a new suite
local function _newsuite(filename, title, errmsg)
    local source = {}
    if not errmsg then
        for line in io.lines(filename) do
                source[#source + 1] = line
        end
    end
    return {title = title, filename = filename, passed = 0, failed = 0, error = errmsg, source = source, contexts = {} }
end

-- Returns a new context
local function _newcontext(...)
    return {output = {...}, passed = 0, failed = 0, tests = {} }
end

-- Returns a contextualized assert()

function _newassert(suite, context)
    return function(exp, msg)
        local test = {passed = exp, message = msg or ""}
        context.tests[#context.tests + 1] = test
        if exp then
            context.passed = context.passed + 1
            suite.passed = suite.passed + 1
        else
            context.failed = context.failed + 1
            suite.failed = suite.failed + 1
            test.linenumber = getinfo(2, "l").currentline
            test.traceback = traceback("", 2)
        end
        return exp
    end
end

-------------------------------------------------------------------------------
-- Runs a suite of tests from filename using a title
-- Test results are added to the results table
-------------------------------------------------------------------------------
local function _test(self, filename, title)
    local f, errmsg = loadfile(filename)
    local results = self.results
    title = title or ""
    if not f then
        -- error loading the file
        results.suites[#results.suites + 1] = _newsuite(filename, title, errmsg)
        results.errors = results.errors + 1
    else
        -- runs the test suite
        local _print = _G.print
        local _assert = _G.assert
        local _write = _G.io.write
        local suite = _newsuite(filename, title)
        local context = _newcontext("")
        _G.assert = _newassert(suite, context) -- so assert() works even without a previous context
        suite.contexts[#suite.contexts + 1] = context
        
        -- separate contexts at every print or io.write
        -- keeping the output stored in the context table
        _G.print = function(...)
            local context = suite.contexts[#suite.contexts]
            if context.passed + context.failed > 0 then
                -- create a new context if there was an assert before the previous context
                context = _newcontext(...)
                suite.contexts[#suite.contexts + 1] = context
                _G.assert = _newassert(suite, context)
            end
        end
        
        _G.io.write = _G.print
        -- executes the suite
        local res, errmsg = xpcall(f, function(err) return err end)
        if not res then
            -- error executing the suite
            suite.error = errmsg
            results.errors = results.errors + 1
        end
        results.passed = results.passed + suite.passed
        results.failed = results.failed + suite.failed
        results.suites[#results.suites + 1] = suite
        
        _G.print = _print
        _G.assert = _assert
        _G.io.write = _write
    end
end

-------------------------------------------------------------------------------
-- Returns a summary of the test results using an optional line separator
-------------------------------------------------------------------------------
local function _summary(self, sep)
    local out = {}
    local results = self.results
    sep = sep or "\n"
    for cs, suite in ipairs(results.suites) do
        if suite.error then
            out[#out + 1] = ">>>>>>>>>>>>>>>>   "..suite.title.." "..suite.filename.." has an error!!!".."   <<<<<<<<<<<<<<<<"
            out[#out + 1] = ""
            out[#out + 1] = suite.error
            out[#out + 1] = ""
        elseif suite.failed > 0 then
            out[#out + 1] = "----------------   "..suite.title.." "..suite.filename.." failed!".."   ----------------"
            out[#out + 1] = ""
            for cg, context in ipairs(suite.contexts) do
                if context.failed > 0 then
                    local output = table.concat(context.output)
                    if output ~= "" then
                        out[#out + 1] = output
                    end
                    local lines = ""
                    local traceback = ""
                    for ct, test in ipairs (context.tests) do
                        if not test.passed then
                            out[#out + 1] = "   #"..test.linenumber.." "..suite.source[test.linenumber]
                        end
                    end
                    out[#out + 1] = traceback
                end
            end
        else
            out[#out + 1] = "-> "..suite.title.." "..suite.filename.." OK!"
        end
    end
    out[#out + 1] = "_________________"
    out[#out + 1] = ""
    out[#out + 1] = "Tests: "..results.failed + results.passed
    out[#out + 1] = "Failures: "..results.failed
    out[#out + 1] = "Errors: "..results.errors
    out[#out + 1] = ""
    return table.concat(out, sep)
end 


-------------------------------------------------------------------------------
-- Returns a new runner
-------------------------------------------------------------------------------
function runner()
    local runner = {results = {passed = 0, failed = 0, errors = 0, suites = {} } }
    setmetatable(runner, {__index = {test = _test, summary = _summary} })
    return runner
end