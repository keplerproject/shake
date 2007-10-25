-------------------------------------------------------------------------------
-- Shake, a simple test engine for Lua
--
-- Authors: Andre Carregal, Humberto dos Anjos
-- Copyright (c) 2007 Kepler Project
--
-- $Id: shake.lua,v 1.5 2007/10/25 23:14:57 carregal Exp $
-------------------------------------------------------------------------------

local io = require "io"
local lfs = require "lfs"
local table = require "table"
local string = require "string"

local _G, error, loadstring, pcall, xpcall, ipairs, setmetatable, setfenv =
      _G, error, loadstring, pcall, xpcall, ipairs, setmetatable, setfenv

require "shake.stir"

-- tries to get the debug table
local debug = debug

if not next(debug) then
    -- uses a stub when debug information is not available
    debug = {
        getinfo = function() return {linenumber = "???"} end,
        traceback = function() return "No traceback information: debug is not available" end,
    }
end

local getinfo = debug.getinfo
local traceback = debug.traceback

module(...)

----------- local functions ------------

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
    return function(val1, op, val2, msg, exp1, exp2, comments)
        if comments then
            context = _newcontext(comments)
            suite.contexts[#suite.contexts + 1] = context
        end        
      
        local test = { message = msg or "" }
        context.tests[#context.tests + 1] = test

        local PASSED = false

        if not op then
          PASSED = val1
        elseif op == '==' then
          PASSED = val1 == val2
        elseif op == '~=' then
          PASSED = val1 ~= val2
        end

        if PASSED then
          context.passed = context.passed + 1
          suite.passed = suite.passed + 1
        else
          context.failed = context.failed + 1
          suite.failed = suite.failed + 1
        end

        test.val1 = val1
        test.op = op
        test.val2 = val2
        test.exp1 = exp1
        test.exp2 = exp2

        test.passed = PASSED
        test.linenumber = getinfo(2, "l").currentline
        test.traceback = traceback("", 2)
        return PASSED, msg
    end
end

-------------------------------------------------------------------------------
-- Runs a suite of tests from filename using a title
-- Test results are added to the results table
-------------------------------------------------------------------------------
local function _test(self, filename, title)
    local f
    local file = io.open(filename)
    if not file then
        return
    else
        local s = file:read'*a'
        s = string.gsub(s, "^#![^\n]*\n", "-- keeps one line in place of the #! one\n")
        s = stir(s)
        f, errmsg = loadstring(s, filename)
    end
    local results = self.results
    title = title or ""
    if not f then
        -- error loading the file
        errmsg = string.gsub(errmsg, '%[string "'..filename..'"%]', filename)
        results.suites[#results.suites + 1] = _newsuite(filename, title, errmsg)
        results.errors = results.errors + 1
    else
        -- runs the test suite
        local _print = _G.print
        local _write = _G.io.write
        local ___STIR_assert = _G.___STIR_assert
        local suite = _newsuite(filename, title)

        local context = _newcontext("")
        _G.___STIR_assert = _newassert(suite, context) -- so assertions works even without a previous context
        suite.contexts[#suite.contexts + 1] = context
        
        -- separate contexts at every print or io.write
        -- keeping the output stored in the context table
        _G.print = function(...)
            local context = suite.contexts[#suite.contexts]
            if context.passed + context.failed > 0 then
                -- create a new context if there was an assert before the previous context
                context = _newcontext(...)
                suite.contexts[#suite.contexts + 1] = context
            else
                context.output[#context.output + 1] = table.concat({...})
            end
            _G.___STIR_assert = _newassert(suite, context)
        end
        
        _G.io.write = _G.print
        
        -- executes the suite
        local res, errmsg = xpcall(f, function(err) return err end)
        if not res then
            -- error executing the suite
            errmsg = errmsg or ""
            suite.error = string.gsub(errmsg, '%[string "'..filename..'"%]', filename)
            results.errors = results.errors + 1
        end
        results.passed = results.passed + suite.passed
        results.failed = results.failed + suite.failed
        results.suites[#results.suites + 1] = suite
        
        _G.print = _print
        _G.io.write = _write
        _G.___STIR_assert = ___STIR_assert
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
            for cg, context in ipairs(suite.contexts) do
                if context.failed > 0 then
                    out[#out + 1] = ""
                    for _, output in ipairs(context.output) do
                        out[#out + 1] = output
                    end
                    if context.comments then
                      out[#out + 1] = context.comments
                    end
                    for ct, test in ipairs (context.tests) do
                        if not test.passed then
                            if suite.source[test.linenumber] then
                                out[#out + 1] = "   #"..test.linenumber.." "..suite.source[test.linenumber]
                            end
                            
                            if not isTerminal(test.exp1, test.val1) then
                                out[#out + 1] = "   "..test.exp1.." -> ".._G.tostring(test.val1)
                            end
                            
                            if not isTerminal(test.exp2, test.val2) then
                                out[#out + 1] = "   "..test.exp2.." -> ".._G.tostring(test.val2)
                            end
                        end
                    end
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



---------- public functions --------------


-------------------------------------------------------------------------------
-- Returns a new runner
-------------------------------------------------------------------------------
function runner()
    local runner = {results = {passed = 0, failed = 0, errors = 0, suites = {} } }
    setmetatable(runner, {__index = {test = _test, summary = _summary} })
    return runner
end

-------------------------------------------------------------------------------
-- Checks if an expression is a terminal value
-------------------------------------------------------------------------------
function isTerminal(exp, val)
    if not exp then return true end
    local chunk = loadstring('return '..exp)
    local env = {}
    setmetatable(env, {__index = function() return "___nil___" end})
    setfenv(chunk, env)
    local status, ret = pcall(chunk)
    if status then
        return ret == val
    end
end
