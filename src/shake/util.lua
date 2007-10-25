-- basic modules
local _G      = _G
local debug   = debug
local math    = math
local package = package
local string  = string
local table   = table

-- imported modules
local m      = require 'lpeg'

-- basic functions
local assert = assert
local getmetatable = getmetatable
local ipairs = ipairs
local pairs = pairs
local print = print
local select = select
local setmetatable = setmetatable
local type = type

-- module declaration
module 'shake.util'

--[[
Converts *'\n'* to *'\r\n'*.

**Parameters:**
* `subject`: the string to convert.

**Returns:** 
* the converted string.
--]]
function unix2dos (subject)
	return (subject:gsub('\n', '\r\n'))
end

--[[
Converts *'\r\n'* to *'\n'*.

**Parameters:**
* `subject`: the string to convert.

**Returns:** 
* the converted string.
--]]
function dos2unix (subject)
	return (subject:gsub('\r\n', '\n'))
end

--[[ 
Checks if `subject` contains *'\r\n'*.

**Parameters:**
* `subject`: a string.

**Returns:**
* the first position in `subject` where *'\r\n'* was found, or `nil` if it wasn't.
--]]
function isdos (subject)
	return (subject:find('\r\n'))
end

--[[
Counts the number of lines (separated by *'\n'*) in `subject`.

**Parameters:**
* `subject`:  a string.

**Returns:**
* the number of lines in `subject`.
--]]
function lines (subject)
	local inc = function (l) return l + 1 end
	local L = m.Ca( m.Cc(1) * (m.P'\n'/inc + m.P(1)) ^0 )
	return L:match(subject)
end

--[[
Prints the table `t` in a pretty fashion, using @#tostring@.

**Parameters:**
* `t`: a table.

**Returns:**
* nothing.
--]]
function pr (t)
	print(tostring(t))
end

--[[
--]]
function removeNewline(comment)
  if type(comment) == 'string' then -- é um comentário isolado
    if comment:sub(-1, -1) == '\n' then
      return comment:sub(1, -2)
    else
      return comment
    end
  elseif type(comment) == 'table' then -- é uma lista de comentários
    for i, v in ipairs(comment) do
      comment[i] = removeNewline(v) 
    end
    
    return comment
  end
end

--[[
Converts the table `t` into a properly indented string, showing all its keys and values. 
String keys are always shown first, followed by numeric keys

This is how Lua values are "stringified":
* Booleans and numbers are merely converted to strings;
* Strings pass through <a href="http://www.lua.org/manual/5.1/manual.html#pdf-string.format">`string.format`</a>, with option *'%q'*;
* All functions just stringify to the string *'function'*;
* Tables are treated recursively, with table loops (`a.i = a`, for instance) returning only *'(table loop)'*.

The example below illustrates this function in action:
<example>
> t = { 'a', function() end, 
  whatever = false, 
  why_do_I_still_bother = 42, 
  [true] = 'BOOM!', 
  To_be_or_not_to_be = { "that", "is", "the", "question", { "isn't", "it", "?" } } }
> t[3] = t                  -- recursive field
> print(util.tostring(t))   -- util.pr could be used here too
{
  ["To_be_or_not_to_be"] = {
    [1]      = "that",
    [2]      = "is",
    [3]      = "the",
    [4]      = "question",
    [5]      = {
      [1]      = "isn't",
      [2]      = "it",
    },
  },
  ["whatever"] = false,
  ["why_do_I_still_bother"] = 42,
  [1]      = "a",
  [2]      = function,
  [3]      = (table loop),
  [true]   = "BOOM!",
}
</example>

**Parameters:**
* `t`: a table.
* `tab`: optional, it's a number which marks the indentation level. 0 means that no indentation will be done.
* `loops`: optional, and used for internal recursion only, it's a list used to detect possible loops.
* `noloops`: optional, it's a boolean used to signal if loops are to be simply marked as such (putting `false`) or navigated (passing `true`).

**Returns:**
* an indented string, which shows `t`'s contents.
--]]
function tostring (t, tab, loops, noloops)
	if not tab then tab = 1 end
	if tab == 0 then tab = -1 end
	loops = loops or {}
	local out = ''

	local stringifier = {
		['nil'] = function (t, tab)
			return _G.tostring(t)
		end,

		['boolean'] = function (t, tab)
			return _G.tostring(t)
		end,

		['string'] = function (t, tab)
			return ( t == '__nil__' and 'nil' ) or string.format( '%q', t )
		end,

		['number'] = function (t, tab)
			return t..''
		end,

		['function'] = function (t, tab)
			return 'function' --string.dump(t)
		end,

		['table'] = function (t, tab, loops, noloops)
      if not noloops then
        if loops[t] then
          return '(table loop)'
        else
          loops[t] = true
        end
      end
			local sorted = {}
			table.foreach( t, function(k,_) table.insert(sorted, k) end )
			table.sort( sorted, function(a,b)
									local n1, n2, s1, s2 = _G.tonumber(a), _G.tonumber(b), tostring(a,nil,loops,noloops), tostring(b,nil,loops,noloops)
									if n1 and not n2 then return true end
									if n2 and not n1 then return false end
									if n1 and n2 then return n1 < n2 end	-- primeiro tenta ordem numerica
									return s1 < s2							-- depois alfabetica
								end )
			local out = '{\n'
			for _,k in ipairs(sorted) do
				--assert( contains( { 'string', 'number', 'boolean' }, type(k) ), 'Invalid key type: '..type(k)..'.' )
				v = t[k]
				out = out .. string.rep('  ',tab) ..string.format("%-8s = ", '['..tostring(k,nil,loops,noloops)..']') .. tostring(v, tab+1,loops,noloops) .. ',\n'
			end
			out = out .. string.rep('  ',tab-1) .. '}'
			if tab == -1 then out = string.gsub(out, '\n', '') out = string.gsub(out, ' +', ' ') end
			return out
		end,
	}
	_G.setmetatable( stringifier, { __index = function(t, id) _G.error("Invalid type: "..id..".") end } )
	return stringifier[type(t)]( t, tab, loops, noloops )
end

--[[
Interprets `str` as a byte sequence, and returns a string containing its <a href="http://en.wikipedia.org/wiki/Hex_dump">hex dump</a>.

**Parameters:**
* `str`: a string.

**Returns:**
* a string with the resulting hex dump. 
--]]
function tohexcode(str)
  local news = ''
  
  for i = 1, #str do
    local c = string.format('%X', string.byte(string.sub(str, i, i)))
    if #c == 1 then c = "0"..c end
    
    news = news..c
  end
  
  return news
end

--[[
Creates a <a href="http://en.wikipedia.org/wiki/Object_copy">deep copy</a> of `t`, including it's metatable, if there is one.

**Parameters:**
* `t`: any Lua value, but a copy will be made only if `t`'s a table.

**Returns:**
* a copy of `t`, if `t`'s a table, or `t` itself, if it's anything else. If `t` has a metatable, it will be shared with the new table.
--]]
function tablecopy(t)
  -- it's a table, copy its keys and values
  if type(t) == "table" then
    local newt = {}
    
    for k, v in pairs(t) do
      newt[tablecopy(k)] = tablecopy(v)
    end
    
    local mt = getmetatable(t)
    
    if mt then setmetatable(newt, mt) end
    
    return newt
  else 
    -- just return it, either it's an atomic value and Lua copies it on its own,
    -- or it's a function, thread or userdata, and there's no (non-hack) way of 
    -- changing it anyway.
    return t
  end
end

--[[
Searches for the last substring in `s` which matches `pattern`.

**Parameters:**
* `s`: a string.
* `pattern`: a string describing the <a href="http://www.lua.org/manual/5.1/manual.html#5.4.1">pattern</a> to be matched.

**Returns:**
* the last substring in `s` which matches `pattern`, or `nil` if none is found.
--]]
function rmatch(s, pattern)
  local match = nil
  
  for i = #s, 1, -1 do
    local lfind, rfind = string.find(s, pattern, i)
    
    if lfind and rfind then
      match = string.sub(s, lfind, rfind)
      break
    end
  end
  
  return match
end

--[[
Takes a string `subject` and returns it, substituting any diacritical 
marks for the equivalent HTML code.

Supported diacritical marks:

`á é í ó ú Á É Í Ó Ú à À â ê ô Â Ê Ô ç Ç ã õ Ã Õ ü Ü`

**Parameters:**
* `subject`: a string.

**Returns:**
* `subject`, with any supported diacritical marks replaced by their HTML equivalent.
--]]
function diacritical2html(subject)
  local mapping = {
    ['á'] = '&aacute;', ['é'] = '&eacute;', ['í'] = '&iacute;', 
    ['ó'] = '&oacute;', ['ú'] = '&uacute;', ['Á'] = '&Aacute;',
    ['É'] = '&Eacute;', ['Í'] = '&Iacute;', ['Ó'] = '&Oacute;',
    ['Ú'] = '&Uacute;', ['à'] = '&agrave;', ['À'] = '&Agrave;',
    ['â'] = '&acirc;',  ['Â'] = '&Acirc;',  ['ê'] = '&ecirc;',  
    ['ô'] = '&ocirc;',  ['Ê'] = '&Ecirc;',  ['Ô'] = '&Ocirc;',  
    ['ç'] = '&ccedil;', ['Ç'] = '&Ccedil;', ['ã'] = '&atilde;', 
    ['õ'] = '&otilde;', ['Ã'] = '&Atilde;', ['Õ'] = '&Otilde;', 
    ['ü'] = '&uuml;',   ['Ü'] = '&Uuml;',
  }
  
  for old, new in pairs(mapping) do
    subject = string.gsub(subject, old, new)
  end
  
  return subject
end

--[[
Checks if `module` is being called in standalone mode or loaded via `require`.
This function should be called before the module declaration.
--]]
function isstandalone(mod)
  return type(package.loaded[mod]) ~= 'userdata'
end

--[[
<project>
<title>Utilitaries</title>
<description>Auxiliary functions</description>
<author>Francisco Sant'Anna and Humberto Anjos</author>
</project>

# Description

A set of utilitary functions.

# Dependencies

* <a href="http://www.inf.puc-rio.br/~roberto/lpeg.html">LPeg</a>.
--]]