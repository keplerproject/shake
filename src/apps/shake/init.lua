-- This is an example of a Shake runner that uses CGILua to offer a drill down of the test results
require"shake"

local function init()
    local SHAKE_TESTS = KEPLER_CONF.."/tests"

    local suite, _ = cgilua.splitfirst(cgilua.script_vpath)

    cgilua.script_vpath = nil
    
    -- Finds all available suites
    local suites = {}
    for dir in lfs.dir(SHAKE_TESTS) do
        local attr = lfs.attributes (SHAKE_TESTS.."/"..dir)
        if attr.mode == "directory" and dir ~= "." and dir ~= ".." then
            table.insert(suites, dir)
        end
    end
    table.sort(suites)    

    local run = shake.runner()


    local function ListSuites()
        if not next(suites) then
            cgilua.put("<li><strong>(No suites)</strong></li>")
        else
            for _,suite in ipairs(suites) do
                cgilua.put([[<li><strong><a href="]]..cgilua.mkurlpath("shake/"..suite)..[[">]]..suite..[[</a></strong></li>]])
            end
        end
    end
    
    local function ReportSuites(run)
        return function()
        local results = run.results
        for cs, suite in ipairs(results.suites) do
            cgilua.put("<tr>\n")
            cgilua.put("<th><strong>"..[[<a href="]]..cgilua.mkurlpath("shake/"..suite.title)..[[">]]..suite.title..[[</a></strong></th>]].."\n".."</strong></th>\n")
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
    
    local function ReportSuite(run)
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
                                        cgilua.put([[<div class="shakeoutput">]]..output.."</div>\n")
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
                                cgilua.put([[<td class="]]..testclass..[[">]]..tostring(test.val1).."</td>")
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
    
    local function SuiteSummary(run)
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
    
    local function ShakeSummary()
        local results = run.results
        if results.errors > 0 or results.failed > 0 then
            cgilua.put("<p>Shake output:</p>")
            cgilua.put([[<pre class="example">]])
            cgilua.put(run:summary())
            cgilua.put("</pre>")
        end
    end

    local curr_dir = lfs.currentdir ()

    if suite == nil or suite == "" or suite == "all" then
        -- Runs all suites
        for _, suite in ipairs(suites) do
            lfs.chdir(SHAKE_TESTS.."/"..suite)
            run:test("test.lua", suite)
            lfs.chdir("..")
        end
        lfs.chdir(curr_dir)
        cgilua.handlelp("shake.lp", {SHAKE_TESTS = SHAKE_TESTS, ListSuites = ListSuites, ReportSuites = ReportSuites(run),
                                    ShakeSummary = ShakeSummary, cgilua = cgilua})
    else
        lfs.chdir(SHAKE_TESTS.."/"..suite)
        run:test("test.lua", suite)
        lfs.chdir(curr_dir)
        cgilua.handlelp("shake_suite.lp", {SHAKE_TESTS = SHAKE_TESTS, suite = suite, ListSuites = ListSuites,
                                    ReportSuite = ReportSuite(run), SuiteSummary = SuiteSummary(run, suite),
                                    ShakeSummary = ShakeSummary, cgilua = cgilua})
    end
    return true
end

return init()