-- Helper file for the CGILua based Shake runner
--

-- Auxiliary formating function for tables (shows only the first level)
local function _expandtable(t)
    local s = "{"
    for i,v in pairs (t) do
        s = s.."<br />\n"
        if type(v) == "table" then
            local vv = "{<br />\n"
            for a,b in pairs(v) do
                vv = string.format ("%s  %s = %s,<br />\n", vv, a, tostring(b))
            end
            v = vv.." },"
            s = s..string.format (" %s = %s", i, tostring(v))
        else
            s = s..string.format (" %s = %s,", i, tostring(v))
        end
    end
    if next(t) then
        s = s.."<br />\n"
    end
    s = s.."}<br />\n"
    return s
end

-- Auxiliary formating function
local function _tostring(obj)
    if type(obj) == "table" then
        return _expandtable(obj)
    else
        return tostring(obj)
    end
end

-- Lists the available test modules using a <li>..</li> format
function ListModules(modules)
	return function()
		if not next(modules) then
		    cgilua.put("<li><strong>(No modules)</strong></li>")
		else
		    for _, module_name in ipairs(modules) do
		        cgilua.put([[<li><strong><a href="]]..cgilua.mkurlpath("module/"..module_name)..
		        	[[">]]..module_name..[[</a></strong></li>]])
		    end
		end
	end
end

-- Report the Shake results for all the modules as a HTML table
function ReportModules(run)
   return function()
   local results = run.results
   for cs, suite in ipairs(results.suites) do
       cgilua.put("<tr>\n")
       cgilua.put("<th><strong>"..[[<a href="]]..cgilua.mkurlpath("module/"..suite.title)..[[">]]..suite.title..[[</a></strong></th>]].."\n".."</strong></th>\n")
       if suite.error then
           cgilua.put([[<td>]]..suite.passed + suite.failed.."</td>\n")
           cgilua.put([[<td]]..(((suite.failed > 0) and [[ class="failed">]]..suite.failed) or ">").."</td>\n")
           cgilua.put([[<td class="error">1</td>]].."\n")
       elseif suite.failed > 0 then
           cgilua.put([[<td>]]..suite.passed + suite.failed.."</td>\n")
           cgilua.put([[<td class="failed">]]..suite.failed.."</td>\n")
           cgilua.put([[<td class="noerror"></td>]].."\n")
       else
           cgilua.put([[<td class="passed">]]..suite.passed + suite.failed.."</td>\n")
           cgilua.put([[<td class="passed"></td>]].."\n")
           cgilua.put([[<td class="noerror"></td>]].."\n")
       end
       cgilua.put("</tr>\n")
   end
   cgilua.put("<tfoot>")
   cgilua.put("<tr>\n")
   cgilua.put("<th><strong>Totals</strong></th>\n")
   cgilua.put("<td>"..results.failed + results.passed.."</td>\n")
   cgilua.put([[<td class="]]..((results.failed > 0) and ([[failed">]]..results.failed) or [[passed">]]).."</td>\n")
   cgilua.put([[<td class="]]..((results.errors > 0) and ([[error">]]..results.errors) or [[noerror">]]).."</td>\n")
   cgilua.put("</tr>\n")
   cgilua.put("</tfoot>")
   end
end

-- Report Shake results of single Module run as a table
function ReportModule(run)
   return function()
       local results = run.results
       for _, suite in ipairs(results.suites) do
           if suite.error == -1 then
               cgilua.put("<p><strong>ERROR</strong>:</p>")
               cgilua.put("<p>"..suite.error.."</p>")
           else
               for _, context in ipairs(suite.contexts) do
                   if next(context.tests) then
                       if context.output[1] ~= "" or context.comments then
                           cgilua.put([[<div class="shakecontext">]].."\n")
                           for _, output in ipairs(context.output) do
                               if output and output ~= "" then
                                   cgilua.put([[<div class="shakeoutput">]]..tostring(output).."</div>\n")
                               end
                           end
                           if context.comments and context.comments ~= "" then
                               cgilua.put([[<div class="shakecomment">]]..context.comments.."</div>\n")
                           end
                           cgilua.put("</div>")
                       end
                       cgilua.put([[
                       <table class="shake">
                           <thead>
                               <tr>
                                   <th scope="col">Line #</th>
                                   <th scope="col"></th>
                                   <th scope="col"><strong>Expected</strong></th>
                                   <th scope="col"><strong>Actual</strong></th>
                                   <th scope="col"><strong>Message</strong></th>
                               </tr>
                           </thead>]])
                       for _, test in ipairs (context.tests) do
                           local linenumber = test.linenumber or "???"
                           local op = test.op
                           local val2 = tostring(test.val2)
                           
                           if not op then
                               val2 = "<em><strong>True value</strong></em>"
                           end
                           
                           if not op or op == "==" then
                               op = ""
                           end
                           
                           cgilua.put("<tr>")
                           local testclass = "passed"
                           if not test.passed then
                               testclass = "failed"
                           end
                           cgilua.put([[<td class="]]..testclass..[[">]]..linenumber.."</td>")
                           cgilua.put([[<td class="]]..testclass..[[">]]..test.exp1.."</td>")
                           cgilua.put([[<td class="]]..testclass..[[">]]..op..val2.."</td>")
                           cgilua.put([[<td class="]]..testclass..[[">]].._tostring(test.val1).."</td>")
                           if not test.passed then
                               cgilua.put([[<td class="]]..testclass..[[">]]..(test.msg or "").."</td>")
                           else
                               cgilua.put([[<td class="]]..testclass..[[">]].."</td>")
                           end
                           cgilua.put("</tr>")
                       end
                       cgilua.put("</table>")
                   end
               end
           end
       end
   end
end

-- Reports a module Shake summary as a HTML table
function ModuleSummary(run)
   return function()
   local results = run.results
   for cs, suite in ipairs(results.suites) do
       cgilua.put("<tr>\n")
       cgilua.put("<th><strong>"..suite.title.."</strong></th>\n")
       if suite.error then
           cgilua.put([[<td>]]..suite.passed + suite.failed.."</td>\n")
           cgilua.put([[<td]]..(((suite.failed > 0) and [[ class="failed">]]..suite.failed) or ">").."</td>\n")
           cgilua.put([[<td class="error">1</td>]].."\n")
       elseif suite.failed > 0 then
           cgilua.put([[<td>]]..suite.passed + suite.failed.."</td>\n")
           cgilua.put([[<td class="failed">]]..suite.failed.."</td>\n")
           cgilua.put([[<td class="noerror"></td>]].."\n")
       else
           cgilua.put([[<td class="passed">]]..suite.passed + suite.failed.."</td>\n")
           cgilua.put([[<td class="passed"></td>]].."\n")
           cgilua.put([[<td class="noerror"></td>]].."\n")
       end
       cgilua.put("</tr>\n")
   end
   end
end

-- Reports the full Shake summary as HTML
function ShakeSummary(run)
	return function()
		local results = run.results
		if results.errors > 0 or results.failed > 0 then
		    cgilua.put("<p>Shake output:</p>")
		    cgilua.put([[<pre class="example">]])
		    cgilua.put(run:summary())
		    cgilua.put("</pre>")
		end
	end
end
