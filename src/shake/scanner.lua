-- basic modules
local _G      = _G
local string  = string

-- basic functions
local assert    = assert
local pairs     = pairs
local print     = print
local require   = require
local tonumber  = tonumber
local type      = type

-- imported modules
local m     = require 'lpeg'
local util  = require 'shake.util'

-- module declaration
module 'shake.scanner'

------------------------------ PATTERNS ---------------------------------------

-- digit pattern
local N = m.R'09'

-- alphanumeric pattern
local AZ = m.R('__','az','AZ','\127\255')     -- llex.c uses isalpha()


------------------------------ FUNCTIONS --------------------------------------

--[[
Returns a function which throws lexical errors.

**Parameters:**
* `msg`: the message to be concatenated to the error message.

**Returns:**
* A function built to be used as a <a href="http://www.inf.puc-rio.br/~roberto/lpeg.html#lpeg">LPeg pattern</a>, as it has the proper signature `function (subject, i)`. It will throw an error when matched.

Pattern usage example:
<example>
patt = intended_pattern^0 %* (EOF + error'invalid character')
</example>

It may also be used as a normal function:
<example>
function (subject, i)
  if bad_condition then
    error'bad condition'(subject, i)
  end
end
</example>
--]]
function error (msg)
	return function (subject, i)
		local line = util.lines(string.sub(subject,1,i))
    print(string.sub(subject,1,i))
    
		_G.error('Lexical error in line '..line..', near "'..(subject:sub(i-10,i)):gsub('\n','EOL')..'": '..msg)
	end
end

--[[
Strips all prefixing `--` and enclosing `--[=%*[` from comment tokens.

**Parameters:**
* `comment`: the comment to strip.

**Returns:**
* the text without comment marking syntax.
--]]
function comment2text (comment) -- TEMP: usar lpeg
	local ret, i, brackets = comment:find('^%-%-%[(=*)%[', i)
	if ret then
		comment = comment:gsub('^%-%-%['..brackets..'%[', '')  -- removes "--[===["
		comment = comment:gsub('%]'..brackets..'%]$', '')      -- removes "]===]"
		comment = '\n' .. comment
		comment = comment:gsub('\n\n', '\n%-%-\n')             -- adjust empty lines
		comment = comment:gsub('\n%s*%-%-+ ?', '\n' )          -- removes "--+ " prefix from lines
		comment = comment:gsub('^\n\n?', '')                   -- removes empty prefix lines
		comment = comment:gsub('\n$', '')                      -- removes empty sufix lines
	else
		comment = comment:gsub('^%-%-+%s*', '')
	end
	return comment
end

--[[
Encloses the text with comment markers.

**Parameters:**
* `text`: the text to comment.

**Returns:**
* the text with comment marking syntax.
--]]
function text2comment (text)
	local function anywhere(patt)
    return m.P { m.P(patt) + 1 * m.V(1) }
  end
  
  -- searching for the largest [(=)*[ in the text
  local max = -1
  
  local updateMax = function (c) if max < #c then max = #c end end
  local openPatt = m.P'[' * m.C((m.P'=')^0) * m.P'[' / updateMax
  local closePatt = m.P']' * m.C((m.P'=')^0) * m.P']' / updateMax
  
  anywhere(openPatt):match(text)
  anywhere(closePatt):match(text)
  
  -- enclosing text with --[(=)^(max+1)[ and --](=)^(max + 1)]
  local equals = string.rep('=', max + 1)
	return '--['..equals..'[\n'..text..'--]'..equals..']'
end

-- used for escape processing in string2text
local escapeTable = {
  ['\\n'] = '\n',
  ['\\t'] = '\t',
  ['\\r'] = '\r',
  ['\\v'] = '\v',
  ['\\a'] = '\a',
  ['\\b'] = '\b',
  ['\\f'] = '\f',
  ['\\"'] = '"',
  ["\\'"] = "'",
  ['\\\\'] = '\\',
}

-- used for escape processing in text2string
reverseEscapeTable = {}

for k, v in pairs(escapeTable) do
  reverseEscapeTable[v] = k
  reverseEscapeTable[string.byte(v)] = k
end

--[=[
Strips all enclosing `'`, `"`, and `[[=%*[[` from string tokens, and processes escape characters.

**Parameters:**
* `str`: the string to strip.

**Returns:**
* the text without string enclosers.
--]=]
function string2text(str)
  --print('string2text', str)
  local escapeNum = m.C(N^-3) / tonumber
  local escapePatt = (
      (m.P'\\' * m.S[[ntrvabf'"\\]]) / escapeTable
    + (m.P'\\' * escapeNum) / string.char
  )
  
  local openDQuote, openQuote = m.P'"' / '', m.P"'" / ''
  local closeDQuote, closeQuote = openDQuote, openQuote
  
  local start, l = "[" * m.P"="^0 * "[", nil
  local longstring = #(m.P'[' * m.S'[=') * m.P(function (s, i)
    l = start:match(s, i)
    if not l then return nil end
    
    local p = m.P("]"..string.rep("=", l - i - 2).."]")
    p = (1 - p)^0 * p
    
    return p:match(s, l)
  end)
  
  
	local patt = m.Cs(
      (openDQuote * ((escapePatt + 1) - closeDQuote)^0 * closeDQuote)
    + (openQuote * ((escapePatt + 1) - closeQuote)^0 * closeQuote)
    + longstring / function (c) return string.sub(c, l, -l) end
  )
  
  local result = patt:match(str)
  --print('result', result)
  return result
end

--[[
Transforms a text into a syntactically valid Lua string. Similar to string.format with the '%%q' option, but inserting escape numbers and escape codes where applicable.

This function is so that string2text(text2string(s)) == s.

**Parameters**
* `text`: a string containing the text.

**Returns:**
* a string, similar to string.format with option '%%q'.
--]]
function text2string(text)
  local function reverseEscape(char)
    local c = reverseEscapeTable[char]
    
    if c then 
      return c
    elseif AZ:match(char) or N:match(char) 
        or SPACE:match(char) or OPERATOR:match(char) then
      return char
    else
      return '\\'..string.byte(char)
    end
  end
  
  local escapePatt = m.P(1) / reverseEscape
  local patt = m.Cs(escapePatt^0)
  
  return '"'..patt:match(text)..'"'
end

------------------------------ TOKENS -----------------------------------------

--[[
-- The table with all token patterns. No captures are made.
--
-- **Reserved Keywords:**<pre>`and`    `break`   `do`        `else`    `elseif`  `end` 
-- `false`  `for`     `function`  `if`      `in`      `local` 
-- `nil`    `not`     `or`        `repeat`  `return`  `then` 
-- `true`   `until`   `while`
-- </pre>
-- 
-- **Other Symbols:**<pre>`+`    `-`   `%*`    `/`   `%`   `^`   `#`   `==`
-- `~=`   `&lt;=`  `&gt;=`   `&lt;`   `&gt;`   `=`   `(`   `)` 
-- `{`    `}`   `[`    `]`   `;`   `:`   `.`   `..`   `...`
-- </pre>
-- 
-- **Variable tokens:**
-- 
-- `ID`, `NUMBER`, and `STRING`.
--
-- The table should be indexed as `tokens.WHILE` or `tokens['+']`.
--]]
--<exp>{ ... }</exp>
tokens = {}

-- Receives a vector of strings and creates a "literal pattern" of the same name
-- and value populating module "tokens" table.
-- If "minus" is passed, each pattern is concatenated to it.
-- Returns a pattern corresponding to the OR between all of them.
local function apply (t, minus)
	local ret = m.P(false)
	for _, v in _G.ipairs(t) do
		local UP = string.upper(v)
		tokens[UP] = m.P(v)
		if minus then
			tokens[UP] = tokens[UP] * minus
		end
		ret = tokens[UP] + ret
	end
	return ret
end

-- Matches any Lua keyword.
-- <exp>LPeg patt</exp>
KEYWORD = apply ({
	'and',      'break',    'do',       'else',     'elseif',
	'end',      'false',    'for',      'function', 'if',
	'in',       'local',    'nil',      'not',      'or',
	'repeat',   'return',   'then',     'true',     'until',    'while',
}, -(N + AZ) )

-- Matches any Lua operator.
-- <exp>LPeg patt</exp>
OPERATOR = apply {
	'+',     '-',     '*',     '/',     '%',     '^',     '#',
	'==',    '~=',    '<=',    '>=',    '<',     '>',     '=',
	'(',     ')',     '{',     '}',     '[',     ']',
	';',     ':',     ',',     '.',     '..',    '...',
}

-- special cases (needs lookahead)
tokens['-']  = tokens['-']  - '--'
--_G.error( m.print(tokens['-'] ) )
tokens['<']  = tokens['<']  - tokens['<=']
tokens['>']  = tokens['>']  - tokens['>=']
tokens['=']  = tokens['=']  - tokens['==']
tokens['[']  = tokens['[']  - '[' * m.S'[='
tokens['.']  = tokens['.']  - (tokens['..'] + N)
tokens['..'] = tokens['..'] - tokens['...']

-- ID
tokens.ID = AZ * (AZ+N)^0 - KEYWORD

-- NUMBER
-- tries to implement the same read_numeral() as in llex.c
local number = function (subject, i)
	--               [.\d]+     .. ( [eE]  ..   [+-]? )?    .. isalnum()*
	local patt = (m.P'.' + N)^1 * (m.S'eE' * m.S'+-'^-1)^-1 * (N+AZ)^0
	--patt = patt / function(num) print(num); if not tonumber(num) then error'malformed number'(subject,i) end end
  patt = patt / function (num) if not tonumber(num) then return nil end end
	return m.match(patt, subject, i)
end
tokens.NUMBER = (#(m.P'.' + N) - (tokens['..'] + tokens['...'])) * number

-- LONG BRACKETS
local start, l = "[" * m.P"="^0 * "[", nil

-- lookahead: call the function only if [[ or [= matches 
-- in the beginning (optimization)
local long_brackets = #(m.P'[' * m.S"[=") * m.P(function (s, i)
  l = start:match(s, i)
  if not l then return nil end
  
  local p = m.P("]" .. string.rep("=", l - i - 2) .. "]")
  p = (1 - p)^0 * p
  
  return p:match(s, l)
end)

--[[
local _LEVEL
local long_brackets = #(m.P'[' * m.P'='^0 * m.P'[') * function (subject, i1)
	local level = assert( subject:match('^%[(=*)%[', i1) )
	_LEVEL = level
	local _, i2 = subject:find(']'..level..']', i1, true)  -- true = plain "find substring"
	return (i2 and (i2+1)) or error("unfinished long brackets")(subject, i1)
end
--]]

-- STRING
do
	          --  OPEN  and  (    ( anything not line or CLOSE ) or (\?)      ) and    CLOSE
	local Str1 = m.P'"' * ( (1 - (m.S'\n\r"\f\\')) + (m.P'\\' * 1) )^0 * (m.P'"' + error'unfinished string')
	local Str2 = m.P"'" * ( (1 - (m.S"\n\r'\f\\")) + (m.P'\\' * 1) )^0 * (m.P"'" + error'unfinished string')
	local Str3 = long_brackets
	tokens.STRING = Str1 + Str2 + Str3
end

------------------------------ PATTERNS --------------------------------------
-- Some useful patterns (not in `tokens`)

-- Matches end of file.
-- <exp>LPeg patt</exp>
EOF = m.P(-1)
-- Matches UNIX's shebang `#!&lt;where Lua's interpreter is&gt;`.
-- <exp>LPeg patt</exp>
BANG = m.P'#!' * (m.P(1)-'\n')^0 * '\n'
-- Matches any space character.
-- <exp>LPeg patt</exp>
SPACE = m.S'\n \t\r\f'

local multi  = m.P'--' * long_brackets
local single = m.P'--' * (1 - m.P'\n')^0
-- Matches any type of comment.
-- <exp>LPeg patt</exp>
COMMENT = multi + single -- multi must be the first ( --[ this is a one line comment )

-- Matches any token in @#tokens@.
-- <exp>LPeg patt</exp>
TOKEN = m.P(false)
for k, v in pairs(tokens) do
	TOKEN = v + TOKEN
end

-- Matches any valid identifier, provided it's the only token in the subject.
IDENTIFIER = m.P(function (subject, i) 
  local result = tokens.ID:match(subject)
  
  if result == #subject + 1 then
    return result
  else
    return nil
  end
end)

-- Matches everything ignored by the parser, i.e. @#SPACE@s and @#COMMENT@s.
-- <exp>LPeg patt</exp>
IGNORE = (SPACE + COMMENT)^0

-- Matches any token, comment or space.
-- <exp>LPeg patt</exp>
ANY = TOKEN + COMMENT + SPACE -- TEMP: + error'invalid character'
