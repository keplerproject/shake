-- Shake runner that uses CGILua to offer a drill down of the test results
--
-- This file acts as the general controller for the application using URLs like:
-- /shake/all - Shakes all the modules in SHAKE_TESTS
-- /shake/module - Shake a specific module in SHAKE_TESTS
-- /shake/... - Processes the resource as a path to a file in the Shake app home directory

require"shake"

-- get the optional configuration
cgilua.doif("shake_conf.lua")

-- load output helper functions
cgilua.doif("helper.lua")

local SHAKE_TESTS = SHAKE_TESTS or KEPLER_CONF.."/tests"

local path_info = cgilua.script_vpath
local cmd, rest = cgilua.splitonfirst(path_info)

cmd = cmd or "all"

-- Finds all available modules
local modules = {}
for dir in lfs.dir(SHAKE_TESTS) do
   local attr = lfs.attributes (SHAKE_TESTS.."/"..dir)
   if attr.mode == "directory" and dir ~= "." and dir ~= ".." then
       table.insert(modules, dir)
   end
end
table.sort(modules)

local run = shake.runner()
local curr_dir = lfs.currentdir ()

if cmd == "all" then
	-- Shakes all modules
	for _, module_name in ipairs(modules) do
	    lfs.chdir(SHAKE_TESTS.."/"..module_name)
	    run:test("test.lua", module_name)
	    lfs.chdir("..")
	end
	lfs.chdir(curr_dir)
	local env = {
		SHAKE_TESTS = SHAKE_TESTS, ListModules = ListModules(modules), ReportModules = ReportModules(run),
		ShakeSummary = ShakeSummary(run), cgilua = cgilua
	}
	cgilua.handlelp("shake.lp", env)
elseif cmd == "module" then
	-- Shakes a single module
	local module_name = cgilua.splitonfirst(rest)
	lfs.chdir(SHAKE_TESTS.."/"..module_name)
	run:test("test.lua", module_name)
	lfs.chdir(curr_dir)
	local env = {
		SHAKE_TESTS = SHAKE_TESTS, module_name = module_name, ListModules = ListModules(modules),
		ReportModule = ReportModule(run, module_name), ModuleSummary = ModuleSummary(run, module_name),
		ShakeSummary = ShakeSummary(run), cgilua = cgilua
	}
	cgilua.handlelp("shake_suite.lp", env)
else
	-- processes resource URLs
	cgilua.handle(cgilua.script_pdir..path_info)
end

return true