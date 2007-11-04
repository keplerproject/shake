require"shake"
KEPLER_TESTS = KEPLER_CONF.."/tests"

local name, rest = cgilua.splitfirst(cgilua.vpath)

if name == nil or name == "" then
    cgilua.script_path = KEPLER_WEB.."/shake.lp"
    cgilua.vpath = rest
    return true -- no response needed
end
    
