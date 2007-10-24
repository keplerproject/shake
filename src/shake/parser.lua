-- basic modules
local _G     = _G
local table  = table
local string = string

-- imported modules
local m       = require 'lpeg'
local scanner = require 'shake.scanner'

-- module declaration
module 'shake.parser'

-- matches Var and FunctionCall from _PrefixExp
local prefix
local setPrefix = function (p)
	return function (_,i)
		prefix = p
		return i
	end
end

local matchPrefix = function (p)
	return function (_, i)
		return (prefix == p) and i
	end
end

local S = m.V'IGNORE'

-- <exp>{ ... }</exp>
-- See @#The Grammar@.
rules = {
	  IGNORE  = scanner.IGNORE  -- seen as S below
	, EPSILON = m.P(true)
	, EOF     = scanner.EOF
	, Name    = m.V'ID'

	, [1]     = m.V'CHUNK'
	, CHUNK   = scanner.BANG^-1 * m.V'Block'

	, Chunk   = (S* m.V'Stat' *S* m.V';'^-1)^0 
            *S* (m.V'LastStat' *S* m.V';'^-1)^-1
	, Block   = m.V'Chunk'

	-- STATS
	, Stat              = m.V'StatAssign' + m.V'FunctionCall' + m.V'StatDo' 
                      + m.V'StatWhile' + m.V'StatRepeat' + m.V'StatIf'
	                    + m.V'StatNumericFor' + m.V'StatGenericFor' 
                      + m.V'StatFunction' + m.V'StatLocalFunction' 
                      + m.V'StatLocalAssign'
	, StatAssign        = m.V'VarList' *S* m.V'=' *S* m.V'ExpList'
	, StatDo            = m.V'DO' *S* m.V'Block' *S* m.V'END'
	, StatWhile         = m.V'WHILE' *S* m.V'Exp' *S* m.V'DO' 
                      *S* m.V'Block' *S* m.V'END'
	, StatRepeat        = m.V'REPEAT' *S* m.V'Block' 
                      *S* m.V'UNTIL' *S* m.V'Exp'
	, StatIf            = m.V'IF' *S* m.V'Exp' *S* m.V'THEN' *S* m.V'Block'
	                    * (S* m.V'ELSEIF' *S* m.V'Exp' 
                      *S* m.V'THEN' *S* m.V'Block')^0
	                    * ((S* m.V'ELSE' * m.V'Block') + m.V'EPSILON')
	                    * S* m.V'END'
	, StatNumericFor    = m.V'FOR' *S* m.V'Name' *S* m.V'=' *S* m.V'Exp' 
                      *S* m.V',' *S* m.V'Exp' 
                      *S* ((m.V',' *S* m.V'Exp') + m.V'EPSILON')
	                    *S* m.V'DO' *S* m.V'Block' *S* m.V'END'
	, StatGenericFor    = m.V'FOR' *S* m.V'NameList' *S* m.V'IN' 
                      *S* m.V'ExpList' *S* m.V'DO' *S* m.V'Block' *S* m.V'END'
	, StatFunction      = m.V'FUNCTION' *S* m.V'FuncName' *S* m.V'FuncBody'
	, StatLocalFunction = m.V'LOCAL' *S* m.V'FUNCTION' *S* m.V'Name' 
                      *S* m.V'FuncBody'
	, StatLocalAssign   = m.V'LOCAL' *S* m.V'NameList' 
                      * (S* m.V'=' *S* m.V'ExpList')^-1
	, LastStat          = m.V'RETURN' * (S* m.V'ExpList')^-1
	                    + m.V'BREAK'

	-- LISTS
	, VarList  = m.V'Var' * (S* m.V',' *S* m.V'Var')^0
	, NameList = m.V'Name' * (S* m.V',' *S* m.V'Name')^0
	, ExpList  = m.V'Exp' * (S* m.V',' *S* m.V'Exp')^0

	-- EXP
	, Exp             = m.V'_SimpleExp' * (S* m.V'BinOp' *S* m.V'_SimpleExp')^0
	, _SimpleExp      = m.V'NIL' + m.V'FALSE' + m.V'TRUE' + m.V'NUMBER' 
                    + m.V'STRING' + m.V'...' + m.V'Function' + m.V'_PrefixExp' 
                    + m.V'TableConstructor' + (m.V'UnOp' *S* m.V'_SimpleExp')
	, _PrefixExp      = ( m.V'Name'               * setPrefix'Var'  -- Var
	                    + m.V'_PrefixExpParens'   * setPrefix(nil)) -- removes last prefix
	                    * (S* (
	                        m.V'_PrefixExpSquare' * setPrefix'Var'  -- Var
	                      + m.V'_PrefixExpDot'    * setPrefix'Var'  -- Var
	                      + m.V'_PrefixExpArgs'   * setPrefix'Call' -- FunctionCall
	                      + m.V'_PrefixExpColon'  * setPrefix'Call' -- FunctionCall
	                    )) ^ 0
	, _PrefixExpParens = m.V'(' *S* m.V'Exp' *S* m.V')'
	, _PrefixExpSquare = m.V'[' *S* m.V'Exp' *S* m.V']'
	, _PrefixExpDot    = m.V'.' *S* m.V'ID'
	, _PrefixExpArgs   = m.V'Args'
	, _PrefixExpColon  = m.V':' *S* m.V'ID' *S* m.V'_PrefixExpArgs'

	, Var          = m.V'_PrefixExp' * matchPrefix'Var'
	, FunctionCall = m.V'_PrefixExp' * matchPrefix'Call'

	-- FUNCTION
	, Function = m.V'FUNCTION' *S* m.V'FuncBody'
	, FuncBody = m.V'(' *S* (m.V'ParList'+m.V'EPSILON') *S* m.V')' 
             *S* m.V'Block' *S* m.V'END'
	, FuncName = m.V'Name' * (S* m.V'_PrefixExpDot')^0 
             * ((S* m.V':' *S* m.V'ID') + m.V'EPSILON')
	, Args     = m.V'(' *S* (m.V'ExpList'+m.V'EPSILON') *S* m.V')'
	           + m.V'TableConstructor' + m.V'STRING'
	, ParList  = m.V'NameList' * (S* m.V',' *S* m.V'...')^-1
	           + m.V'...'

	-- TABLE
	, TableConstructor = m.V'{' *S* (m.V'FieldList'+m.V'EPSILON') *S* m.V'}'
	, FieldList        = m.V'Field' * (S* m.V'FieldSep' *S* m.V'Field')^0 
                     * (S* m.V'FieldSep')^-1
	, Field            = m.V'_FieldSquare' + m.V'_FieldID' + m.V'_FieldExp'
	, _FieldSquare     = m.V'[' *S* m.V'Exp' *S* m.V']' *S* m.V'=' *S* m.V'Exp'
	, _FieldID         = m.V'ID' *S* m.V'=' *S* m.V'Exp'
	, _FieldExp        = m.V'Exp'
	                   
	, FieldSep         = m.V',' + m.V';'

	-- OPERATORS
	, BinOp    = m.V'+'   + m.V'-'  + m.V'*' + m.V'/'  + m.V'^'  + m.V'%'  
             + m.V'..'  + m.V'<'  + m.V'<=' + m.V'>' + m.V'>=' + m.V'==' 
             + m.V'~='  + m.V'AND' + m.V'OR'
	, UnOp     = m.V'-' + m.V'NOT' + m.V'#'
}

-- puts all tokens as grammar rules
for k, v in _G.pairs(scanner.tokens) do
  rules[k] = v
end
