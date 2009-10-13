-- basic modules
local _G     = _G
local string = string
local table  = table

-- basic functions
local ipairs = ipairs
local pairs = pairs
local print = print
local require = require
local tostring = tostring
local type = type

-- imported modules
local m       = require 'lpeg'

local scanner = require 'leg.scanner'
local parser  = require 'leg.parser'
local grammar = require 'leg.grammar'

-- module declaration
module 'shake'

-- HELPER VALUES AND FUNCTIONS ------------

-- matches one or more "ignorable" strings (spaces or comments)
local S = scanner.IGNORED

-- matches all space characters
local SPACES = scanner.SPACE^0

-- pretty-prints a list on screen, here for debugging purposes
local function list2string(t, level)
  level = level or 0
  local indent = string.rep('  ', level)
  
  if type(t) == 'string' then
    return string.format('%q', tostring(t))
    --return scanner.text2string(t)
  elseif type(t) ~= 'table' then
    return tostring(t)
  else
    local str = '{'
    
    for k, v in pairs(t) do
      str = str..'\n'..indent..'  ['..list2string(k)..'] = '
        ..list2string(v, level + 1)
    end
    
    return str..'\n'..indent..'}'
  end
end

-- removes the final newline character from comments
local function removeNewline(comment)
  if type(comment) == 'string' then -- it's a single comment
    if comment:sub(-1, -1) == '\n' then
      return comment:sub(1, -2)
    else
      return comment
    end
  elseif type(comment) == 'table' then -- it's a list of comments
    for i, v in ipairs(comment) do
      comment[i] = removeNewline(v) 
    end
    
    return comment
  end
end

-- Lua 5.1 operator precedence table
local ops = {
  ['or'] =  { precedence = 1, left = true, arity = 2 },
  ['and'] = { precedence = 2, left = true, arity = 2 },
  ['=='] =  { precedence = 3, left = true, arity = 2 },
  ['~='] =  { precedence = 3, left = true, arity = 2 },
  ['<='] =  { precedence = 3, left = true, arity = 2 },
  ['>='] =  { precedence = 3, left = true, arity = 2 },
  ['<'] =   { precedence = 3, left = true, arity = 2 },
  ['>'] =   { precedence = 3, left = true, arity = 2 },
  ['..'] =  { precedence = 4, right = true, arity = 2 },
  ['+'] =   { precedence = 5, left = true, arity = 2 },
  ['-'] =   { precedence = 5, left = true, arity = 2 },
  ['*'] =   { precedence = 6, left = true, arity = 2 },
  ['/'] =   { precedence = 6, left = true, arity = 2 },
  ['%'] =   { precedence = 6, left = true, arity = 2 },
  ['not'] = { precedence = 7, arity = 1 },
  ['#'] =   { precedence = 7, arity = 1 },
  ['unm'] = { precedence = 7, arity = 1 },
  ['^'] =   { precedence = 8, right = true, arity = 2 }
}


-- operator precedence algorithm, adapted to find the outmost binary operator's
-- index in list
local function getOuterOp(list)
  local stack = {}
  
  local function makeNode(index, node)
    return { index = index, node = node }
  end
  
  for i, v in ipairs(list) do
    if ops[v] then -- it's an operator, and in this case, binary
      local top, op = stack[#stack], ops[v]
      while top 
        and ((op.right and op.precedence < ops[top.node].precedence)
          or (op.left and op.precedence <= ops[top.node].precedence)) do
        
        table.remove(stack)
        
        top = stack[#stack]
      end
      
      stack[#stack + 1] = makeNode(i, v)
    end
  end
  
  -- getting the outmost operator's index
  return stack[1] and stack[1].index
end

-- SPECIAL TOKENS ------------------------

-- pretty obvious, isn't it?
local OPEN = S* m.P'('

-- same here
local CLOSE = S* m.P')'

-- self explaining pattern
local COMMA = S* m.P','

-- the special operators, here == and ~=
local OP = S* m.C(m.P'~=' + m.P'==')

-- matches and captures a Lua expression. The capture may return either a 
-- single expression or an expression, an operator (matched by OP) and an 
-- expression
local EXP = S* (grammar.apply(parser.rules, 
  m.C(m.V'_SimpleExp') * (S* m.C(m.V'BinOp') *S* m.C(m.V'_SimpleExp'))^0,
  { -- the capture table
    [1] = function (...)
      local infix = { ... }
      local outerOp = getOuterOp(infix)
      
      if OP:match(infix[outerOp] or '') then
        -- return the left side, the operator, and the right side separately
        return table.concat(infix, ' ', 1, outerOp - 1), 
               infix[outerOp],
               table.concat(infix, ' ', outerOp + 1)
      else -- return the whole expression
        return table.concat(infix, ' ')
      end
    end,
  })) 

-- matches and captures the message
local MSG = S* m.C(grammar.apply(parser.rules, m.V'Exp'))

-- matches and captures one or more comments, separated at most by one newline
local COMMENT = m.C((scanner.COMMENT * m.P'\n'^-1) ^ 1)

-- makes it easier for optional patterns with overarching captures
local EPSILON = m.P'' / function() return nil end

-- PATTERNS ---------------------------------

-- matches an expression EXP and packages its captures in a table
local LINE = EXP / function (exp1, op, exp2)
  return { exp1 = exp1, op = op, exp2 = exp2 }
end

-- matches an assert call and packages all relevant information in a table
local ASSERT = ((COMMENT + EPSILON) *SPACES* m.Cp() * m.P'assert' * OPEN * LINE 
             * ((COMMA * MSG) + EPSILON) * CLOSE * m.Cp()) 
             / function (comment, start, line, msg, finish)
              return {
                start = start,
                comment = (comment ~= nil) and removeNewline(comment) or nil,
                exp = line,
                msg = msg,
                finish = finish,
              }
            end

-- matches all ASSERTs in a given input and packages them in a list
local ALL = m.Ct((ASSERT + 1)^0)

-- FUNCTIONS ---------------------------------

-- takes an ASSERT capture and builds the equivalent [assertName] call
local function buildNewAssert(info, assertName, errorName)
  local exp1, op, exp2 = info.exp.exp1, info.exp.op, info.exp.exp2
  local comment, msg, text = info.comment, info.msg, info.text
  
  local newassert = ''
  
  local str1 = scanner.text2string(exp1)
  local str2 = (exp2 == nil) and 'nil' or scanner.text2string(exp2)
  local com = (comment == nil) and 'nil' or scanner.text2string(comment)
  local textStr = scanner.text2string(text)
  local func
  if not op then
    func = [[(function () assert_not_nil(a) end)]]
  elseif op == '==' then
    func = [[(function () assert_equal(a, b) end)]]
  elseif op == '~=' then
    func = [[(function () assert_not_equal(a, b) end)]]
  end
  local stir = [[xpcall((function () local a = ]] .. exp1 .. [[; local b = ]] ..
      (exp2 or 'nil') .. [[; return ]]..newassert..assertName..'(a'
    ..', '..(op and '"'..op..'"' or 'nil')
    ..', b '
    ..', '..(msg or 'nil')
    ..', '..str1
    ..', '..str2
    ..', '..com
    ..', '..textStr
    ..', '..func
  ..[[) end), (function (e) ]]..newassert..errorName..[[(]] 
    ..str1
    ..', '..(op and '"'..op..'"' or 'nil')
    ..', '..str2
    ..', '..(msg or 'nil')
    ..', '..com
    ..', '..textStr .. [[, debug.traceback()) end))]]
  --print(stir)
  return stir
end

-- replaces str's substring from i to j with new_str
local function sub(str, new_str, i, j)
  i, j = i or 1, j or #str
  
  return str:sub(1, i - 1)..new_str..str:sub(j)
end

-- replaces all asserts in input by their ___STIR_assert counterparts
function stir(input, assertName, errorName)
  assertName = assertName or '___STIR_assert'
  errorName = errorName or '___STIR_error'
  local asserts = ALL:match(input)
  
  for i = #asserts, 1, -1 do
    local v = asserts[i]
    
    v.text = input:sub(v.start, v.finish)
    input = sub(input, buildNewAssert(v, assertName, errorName), v.start, v.finish)
  end
  
  return input
end