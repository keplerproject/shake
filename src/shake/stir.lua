-- módulos básicos
local _G = _G
local string = string
local table = table

-- funções básicas
local ipairs = ipairs
local pairs = pairs
local print = print
local require = require
local tostring = tostring
local type = type

-- módulos importados
local m       = require 'lpeg'
local scanner = require 'shake.scanner'
local parser  = require 'shake.parser'
local grammar = require 'shake.grammar'

-- declaração de módulo
module 'shake'

-- FUNÇÕES E VALORES AUXILIARES ------------

-- casa com um ou mais caracteres "ignoráveis" (espaços e comentários)
local S = scanner.IGNORE

-- casa com espaços
local SPACES = scanner.SPACE^0

-- casa com todos os caracteres até achar delim, ignorando espaços
local function matchUntil(delim)
  delim = m.P(delim) -- garantindo que delim é um padrão LPeg

  -- evitando capturar espaços entre a expressão e delim
  return (1 - (S* delim))^0 
end

-- só para imprimir o conteúdo de uma lista na tela
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

-- tabela de precedência de operadores em Lua 5.1
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


-- algoritmo de precedência de operadores, modificado para achar o índice do 
-- operador mais externo
local function getOuterOp(list)
  local queue = {}
  local stack = {}
  
  local function makeNode(index, node)
    return { index = index, node = node }
  end
  
  for i, v in ipairs(list) do
    if ops[v] then -- é um operador binário
      local top, op = stack[#stack], ops[v]
      while top 
        and ((op.right and op.precedence < ops[top.node].precedence)
          or (op.left and op.precedence <= ops[top.node].precedence)) do
        
        queue[#queue + 1] = table.remove(stack)
        top = stack[#stack]
      end
      
      stack[#stack + 1] = makeNode(i, v)
    else
      queue[#queue + 1] = v
    end
  end
  
  -- getting the outmost operator's index
  return stack[1] and stack[1].index
end

-- TOKENS ESPECIAIS ------------------------
-- OBS.:
-- espaços foram incluidos nos tokens para evitar escrever *S* a toda hora

-- abre parênteses
local OPEN = S* m.P'('

-- fecha parênteses
local CLOSE = S* m.P')'

-- vírgula
local COMMA = S* m.P','

-- capturando o operador especial, que pode ser ~= ou ==
local OP = S* m.C(m.P'~=' + m.P'==')

-- casa e captura uma expressão
local EXP = S* (grammar.apply(parser.rules, 
  m.C(m.V'_SimpleExp') * (S* m.C(m.V'BinOp') *S* m.C(m.V'_SimpleExp'))^0,
  {
    [1] = function (...)
      local infix = { ... }
      local outerOp = getOuterOp(infix)
      
      if OP:match(infix[outerOp] or '') then
        return table.concat(infix, ' ', 1, outerOp - 1), 
               infix[outerOp],
               table.concat(infix, ' ', outerOp + 1)
      else
        return table.concat(infix, ' ')
      end
    end,
  })) 

-- casa e captura a mensagem
local MSG = S* m.C(matchUntil(CLOSE))

-- casa e captura um comentário
local COMMENT = m.C((scanner.COMMENT * m.P'\n'^-1) ^ 1)

-- para facilitar a captura de padrões opcionais
local EPSILON = m.P'' / function() return nil end

-- PADRÕES ---------------------------------

-- um padrão que casa com EXP OP EXP ou EXP
local LINE = EXP / function (exp1, op, exp2)
  return { exp1 = exp1, op = op, exp2 = exp2 }
end

-- um padrão que casa com uma chamada a assert no nosso formato
local ASSERT = ((COMMENT + EPSILON) *SPACES* m.Cp() * m.P'assert' * OPEN * LINE 
             * ((COMMA * MSG) + EPSILON) * CLOSE * m.Cp()) 
             / function (comment, start, line, msg, finish)
              return {
                start = start,
                comment = (comment ~= nil) and util.removeNewline(comment) or nil,
                exp = line,
                msg = msg,
                finish = finish,
              }
            end

-- um padrão que acha todas as instâncias de ASSERT em um dado programa
local ALL = m.Ct((ASSERT + 1)^0)

-- FUNÇÕES ---------------------------------

-- pega uma captura de ASSERT e produz a chamada new_assert equivalente
local function buildNewAssert(info)
  local exp1, op, exp2 = info.exp.exp1, info.exp.op, info.exp.exp2
  local comment, msg, text = info.comment, info.msg, info.text
  
  local newassert = ''
  
  local str1 = scanner.text2string(exp1)
  local str2 = (exp2 == nil) and 'nil' or scanner.text2string(exp2)
  local com = (comment == nil) and 'nil' or scanner.text2string(comment)
  local textStr = scanner.text2string(text)
  return newassert..'___STIR_assert('..exp1
    ..', '..(op and '"'..op..'"' or 'nil')
    ..', '..(exp2 or 'nil')
    ..', '..(msg or 'nil')
    ..', '..str1
    ..', '..str2
    ..', '..com
    ..', '..textStr
    ..')'
end

-- substitui a substring de str de i a j pela new_str
local function sub(str, new_str, i, j)
  i, j = i or 1, j or #str
  
  return str:sub(1, i - 1)..new_str..str:sub(j)
end

-- substitui todos os asserts em input pelos new_asserts equivalentes
function stir(input)
  local asserts = ALL:match(input)
  
  for i = #asserts, 1, -1 do
    local v = asserts[i]
    
    v.text = input:sub(v.start, v.finish)
    input = sub(input, buildNewAssert(v), v.start, v.finish)
  end
  
  return input
end

-- TESTES ----------------------------------
local args = { ... }

---[===[


-- imprimindo o teste abaixo
--[=====[
local input = args[1] or [==[
local m = require 'lpeg'

local chunk = assert(loadstring('file.luac'), 'The chunk was not loaded!')

--[=[ testando assert
será que funciona?
mesmo com --[[ e --]====] no meio?
e com espaços entre a chamada de assert e o comentário de contexto?
--]=]


assert  (  exp ~= -8, 
      'slkklajs')

-- aqui não captura o comentário, não é mesmo?
local c = assert((asjksaklj == alklaksj) + a and 4)
]==]
--]=====]
--[=[
local input = [[
-- this is a multiline assert. If stir does not handle it right, the
-- displayed line
-- will be the comment in the middle
assert(
x -- this should no be displayed
==
nil
)
assert(
x
-- 1
==
-- 2
5
-- 3
)
-- 4
x = "If this line shows up, stir lost the line count"
]]
--]=]
--[=[
local input = [[
if type(x) ~= "table" then assert(x == y) end
assert(n == # "t" and table.concat(t) == "alo")
]]
--]=]
--[[
local output = stir(input)


print('input', '\n'..input)
print('\noutput', '\n'..output)
--print(list2string { ALL:match(input) })
--]]

--[[
-- Essa função fica no shake.lua
-- out é definido fora da função
local function toOutput(str)
  out = out or {} -- se ele não tinha valor, agora tem
 
  local lines = util.split(str, '\n')
 
  for _, v in ipairs(lines) do
    out[#out + 1] = v
  end
end

-- Essa função fica no util.lua, pois usa LPeg
-- Retorna a lista de substrings str separadas por sep.
function split(str, sep)
  sep = m.P(sep)
  local elem = m.C((1 - sep)^0)
  local p = m.Ct(elem * (sep * elem)^0)
 
  return p:match(s)
end
--]]
