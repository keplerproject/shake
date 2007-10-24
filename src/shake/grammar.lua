-- basic functions
local assert  = assert
local pairs   = pairs
local type    = type

-- imported modules
local lpeg = require 'lpeg'

-- module declaration
module 'shake.grammar'

--[[
Creates a <a href="http://en.wikipedia.org/wiki/Shallow_copy">shallow copy</a> of `grammar`.

**Parameters:**
* `grammar`: a regular table.

**Returns:**
* a newly created table, with `grammar`'s keys and values.
--]]
function copy(grammar)
	_grammar = {}
	for k, v in pairs(grammar) do
		_grammar[k] = v
	end
	return _grammar
end

--[[
<a href="#Completing">Completes</a> `dest` with `orig`.

**Parameters:**
* `dest`: the new grammar. Must be a table.
* `orig`: the original grammar. Must be a table.

**Returns:**
* `dest`, with new rules inherited from `orig`.
--]]
function complete (dest, orig)
	for rule, patt in pairs(orig) do
		if not dest[rule] then
			dest[rule] = patt
		end
	end
  
	return dest
end

--[[
<a href="#Piping">Pipes</a> the captures in `orig` to the ones in `dest`.

`dest` and `orig` should be tables, with each key storing a capture function. Each capture in `dest` will be altered to use the results for the matching one in `orig` as input, using function composition. Should `orig` possess keys not in `dest`, `dest` will copy them.

**Parameters:**
* `dest`: a capture table.
* `orig`: a capture table.

**Returns:**
* `dest`, suitably modified.
--]]
function pipe (dest, orig)
	for k, vorig in pairs(orig) do
		local vdest = dest[k]
		if vdest then
			dest[k] = function(...) return vdest(vorig(...)) end
		else
			dest[k] = vorig
		end
	end
	
	return dest
end

--[[
<a href="#Completing">Completes</a> `rules` with `grammar` and then <a href="#Applying">applies</a> `captures`. 

`rules` can either be:
* a single pattern, which is taken to be the new initial rule, 
* a possibly incomplete LPeg grammar, as per @#complete@, or 
* `nil`, which means no new rules are added.

`captures` can either be:
* a capture table, as per @#pipe@, or
* `nil`, which means no captures are applied.

**Parameters:**
* `grammar`: the old grammar. It stays unmodified.
* `rules`: optional, the new rules. 
* `captures`: optional, the final capture table.

**Returns:**
* the new grammar.
--]]
function apply (grammar, rules, captures)
	if rules ~= nil then
		if type(rules) ~= 'table' then
			rules = { rules }
		end
    
    grammar = complete(rules, grammar)
    
		if type(grammar[1]) == 'string' then
			rules[1] = lpeg.V(grammar[1])
		end
	end

	if captures ~= nil then
		assert(type(captures) == 'table', 'captures must be a table')
    
		for rule, cap in pairs(captures) do
			grammar[rule] = grammar[rule] / cap
		end
	end
  
	return grammar
end
