-------------------------------------------------------------------------------
-- Shake, a simple test engine for Lua
--
-- Authors: Andre Carregal, Humberto dos Anjos
-- Copyright (c) 2007 Kepler Project
--
-- $Id: shake.lua,v 1.22 2008/07/17 17:12:58 carregal Exp $
-------------------------------------------------------------------------------

local io = require "io"
local lfs = require "lfs"
local table = require "table"
local string = require "string"

local _G, error, unpack, loadstring, pcall, xpcall, ipairs, setmetatable, setfenv,
       loadfile, dofile, tostring, type, pairs, print =
      _G, error, unpack, loadstring, pcall, xpcall, ipairs, setmetatable, setfenv, loadfile,
       dofile, tostring, type, pairs, print

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

_COPYRIGHT = "Copyright (C) 2007 Kepler Project"
_DESCRIPTION = "Shake is a simple and transparent test engine for Lua that assumes that tests only use standard assert and print calls."
_VERSION = "Shake 1.0.2"

----------- local functions ------------

-- Returns a new suite
local function _newsuite(s, filename, title, errmsg)
    local source = {}
    filename = filename or ""
    if not errmsg then
        for line in s:gmatch("(.-)\r?\n") do
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
        test.msg = msg
        test.passed = PASSED
        test.linenumber = getinfo(2, "l").currentline
        test.traceback = traceback("", 2)
        return PASSED, msg
    end
end

local _loadstring = function() end

-- Version of loadfile that stirs the file before compiling it
local function _loadfile(self, filename, title)
    local file, func, errmsg
    file, errmsg = io.open(filename)
    if not file then
        return nil, errmsg
    else
        local str = file:read'*a'
        func, errmsg = _loadstring(self, str, filename, title)
    end
    return func, errmsg
end

-- Version of dofile that stirs the file before executing it
local function _dofile(self, filename, title)
    local results = {pcall(_loadfile(self, filename, title))}
    if results[1] then
        table.remove(results, 1)
    end
    return unpack(results)
end

-------------------------------------------------------------------------------
-- Prepares a suite of tests from a string using an optional title
-- When running, test results are added to the results table
-------------------------------------------------------------------------------
function _loadstring(self, s, chunckname, title)
    local s2 = string.gsub(s, "^#![^\n]*\n", "-- keeps one line in place of an eventual one with a #! at the start\n")
    s2 = stir(s2)
    f, errmsg = loadstring(s2, chunckname)

    local results = self.results
    title = title or ""
    if not f then
        -- error loading the string
        errmsg = string.gsub(errmsg, '%[string "'..chunckname..'"%]', chunckname)
        results.suites[#results.suites + 1] = _newsuite(s, chunckname, title, errmsg)
        results.errors = results.errors + 1
    else return function(...)
        -- runs the test suite
        local _print = _G.print
        local _write = _G.io.write
        local ___STIR_assert = _G.___STIR_assert
        
        local lf = _G.loadfile
        local df = _G.dofile
		local ls = _G.loadstring

        _G.loadfile = function(name) return _loadfile(self, name, title) end
        _G.dofile = function (name) return _dofile(self, name, title) end
		_G.loadstring = function(str, name) return _loadstring(self, str, name, title) end
	
        
        local suite = _newsuite(s, chunckname, title)

        local context = _newcontext("")
        _G.___STIR_assert = _newassert(suite, context) -- so assertions works even without a previous context
	_G.___STIR_error = error
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
		-- converts all parameters to strings
		local temp = {}
		for i = 1, _G.select('#',...) do
			table.insert(temp, _G.tostring(_G.select(i,...)))
		end
		-- and concatenates them
		context.output[#context.output + 1] = table.concat(temp, "\t")
            end
            _G.___STIR_assert = _newassert(suite, context)
        end
        
        _G.io.write = _G.print
        
        -- executes the suite
        local res, errmsg = xpcall(f, function(err) return err end)
        if not res then
            -- error executing the suite
            errmsg = errmsg or ""
            suite.error = string.gsub(errmsg, '%[string "'..chunckname..'"%]', chunckname)
            results.errors = results.errors + 1
        end
        results.passed = results.passed + suite.passed
        results.failed = results.failed + suite.failed
        results.suites[#results.suites + 1] = suite

        -- restores the environment
        _G.loadfile = lf
        _G.dofile = df
		_G.loadstring = ls
        _G.print = _print
        _G.io.write = _write
        _G.___STIR_assert = ___STIR_assert
        end -- returned function
    end
end

-------------------------------------------------------------------------------
-- Displays values as nice strings
-------------------------------------------------------------------------------
local function _tostring(s)
	if _G.type(s) == "string" then
		return [["]]..s..[["]]
	else
		return _G.tostring(s)
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
                        out[#out + 1] = _G.tostring(output)
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
                                out[#out + 1] = "   "..test.exp1.." -> ".._tostring(test.val1)
                            end
                            
                            if not isTerminal(test.exp2, test.val2) then
                                out[#out + 1] = "   "..test.exp2.." -> ".._tostring(test.val2)
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


-- Returns a new context
local function _newcontext_tsc(...)
   local args = { ... }
   for i = 1, #args do args[i] = tostring(args[i]) end
   return { parent = 0, name = table.concat(args, ", "), context = true }
end

local function transform_comments(s)
  return s:gsub("%-%-%s*", ""):gsub("\n", ", "):gsub("\r", "")
end

-- Returns a contextualized assert()
--

function _newassert_tsc(contexts, context)
    local parent = #contexts
    return function(val1, op, val2, msg, exp1, exp2, comments, str, func)
        if context then context.has_asserts = true end

        if comments then
            context = _newcontext_tsc(transform_comments(comments))
            contexts[#contexts + 1] = context
            parent = #contexts
        end        
        
	if not msg then
	  if op then msg = (exp1 .. ' ' .. op .. ' ' .. exp2) else msg = exp1 end
	end

        local test = { parent = parent, name = msg, test = func }
        contexts[#contexts + 1] = test

        --test.linenumber = getinfo(2, "l").currentline
        --test.traceback = traceback("", 2)
      end, function (str1, op, str2, msg, com, str, e)
	     if not msg then
	       if op then msg = (str1 .. ' ' .. op .. ' ' .. str2) else msg = str1 end
	     end
	     contexts[#contexts + 1] =
	       { parent = parent, name = msg, test = function () error(e) end } 
	   end
end

local function _loadstring_tsc(s, name)
    local s2 = string.gsub(s, "^#![^\n]*\n", 
        "-- keeps one line in place of an eventual one with a #! at the start\n")
    s2 = stir(s2) ; --print(s2)
    return loadstring(s2, name)
end

-- Version of loadfile that stirs the file before compiling it
local function _loadfile_tsc(filename)
    local file, func, errmsg
    file, errmsg = io.open(filename)
    if not file then
        return nil, errmsg
    else
        local str = file:read'*a'
        func, errmsg = _loadstring_tsc(str, filename)
    end
    return func, errmsg
end

-------------------------------------------------------------------------------
-- Runs a suite of tests from filename using a title
-- Test results are added to the results table
-------------------------------------------------------------------------------
local function _test(filename, contexts)
    f, errmsg = _loadfile_tsc(filename)
    if not f then
       error("cannot load file " .. filename .. ": " .. errmsg)
    else
        -- runs the test suite
        local _print = _G.print
        local _write = _G.io.write
        local ___STIR_assert = _G.___STIR_assert
        --local lf = _G.loadfile
        --local df = _G.dofile
        --local ls = _G.loadstring
        --local ds = _G.dostring
        --_G.loadfile = _loadfile
        --_G.dofile = _dofile
        --_G.loadstring = _loadstring
        --_G.dostring = _dostring
        
        local context 
        _G.___STIR_assert, _G.___STIR_error = _newassert_tsc(contexts, context) -- so assertions works even without a previous context
        
        -- separate contexts at every print or io.write
        -- keeping the output stored in the context table
        _G.print = function(...)
            if (not context) or context.has_asserts then
                -- create a new context if there was an assert before the previous context
                context = _newcontext_tsc(...)
                contexts[#contexts + 1] = context
            else
                -- converts all parameters to strings
                local temp = {}
                local args = { context.name, ... }
                for i = 1, #args do 
                   local s = tostring(args[i])
                   if s ~= "" then temp[#temp + 1] = s end
                end
                -- and concatenates them
                context.name = table.concat(temp, ", ")
            end
            _G.___STIR_assert = _newassert_tsc(contexts, context)
        end
        
        _G.io.write = _G.print
        
        -- executes the suite
        local res, errmsg = xpcall(f, function(err) return err end)
        if not res then
            -- error executing the suite
            error("cannot load contexts from file " .. filename .. ": " .. errmsg)
        end

        -- restores the environment
        --_G.loadfile = lf
        --_G.dofile = df
        --_G.loadstring = ls
        --_G.dostring = ds
        _G.print = _print
        _G.io.write = _write
        _G.___STIR_assert = ___STIR_assert
    end
end

----------                    Public functions                   --------------


-------------------------------------------------------------------------------
-- Returns a new runner with the functions
-- test(filename)
-- summary()
-------------------------------------------------------------------------------
function runner()
    local runner = {results = {passed = 0, failed = 0, errors = 0, suites = {} } }
    setmetatable(runner, {__index = {test = _dofile, summary = _summary} })
    return runner
end

function load_contexts(filename, contexts)
  _test(filename, contexts)
end


-------------------------------------------------------------------------------
-- Checks if an expression string represents a terminal value
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
