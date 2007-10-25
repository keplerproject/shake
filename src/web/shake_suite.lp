<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>Shake Tests</title>
    <link rel="stylesheet" href="css/doc.css" type="text/css"/>
    <link rel="stylesheet" href="css/shake.css" type="text/css"/>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
</head>

<%
-- This is an example of a Shake runner that uses CGILua to offer a drill down of the test results
-- This file should not be considered an example of a good CGILua application, since it tries to
-- do everything in a single .lp file. The best solution would be to use a .lua file for the code

-- test directory
local KEPLER_TESTS = KEPLER_TESTS or ""
local target = cgilua.QUERY.s

%>

<body>

<div id="container">

<div id="product">
	<div id="product_logo"><a href="http://www.keplerproject.org">
		<img src="img/keplerproject.gif" alt="Kepler Project logo" /></a>
    </div>
	<div id="product_name"><big><strong></strong></big></div>
	<div id="product_description">Kepler Shake Tests</div>
</div> <!-- id="product" -->

<div id="main">

<div id="navigation">

<% 
local suites = {}
for dir in lfs.dir(KEPLER_TESTS) do
    local attr = lfs.attributes (KEPLER_TESTS.."/"..dir)
    if attr.mode == "directory" and dir ~= "." and dir ~= ".." then
        table.insert(suites, dir)
    end
end
table.sort(suites)
%>

<h1>Shake</h1>
	<ul>
        <li><strong><a href="shake.lp">All</a></strong>
        <ul>
            <%
            for _,suite in ipairs(suites) do
            %>
            <li><strong><a href="shake_suite.lp?s=<%= suite %>"><%= suite %></a></strong></li>
            <%
            end
            if not next(suites) then
            %>
            <li><strong>(None)</strong></li>
            <%
            end
            %>
        </ul>
        </li>
	</ul>
</div> <!-- id="navigation" -->

<div id="content">

<h1>Shake details for the <%= target %> suite</h1>

<p>Here you a more detailed view of the <%= target %> tests results:</</p>

<%
local run = shake.runner()
lfs.chdir(KEPLER_TESTS.."/"..target)
run:test("test.lua", target)
%>

<table class="shake">
    <thead>
        <tr>
            <th scope="col"></th>
            <th scope="col"><strong>Tests</strong></th>
            <th scope="col"><strong>Failures</strong></th>
            <th scope="col"><strong>Errors</strong></th>
        </tr>
    </thead>
<%
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
%>
</table>

<%
    local results = run.results
    for _, suite in ipairs(results.suites) do
        if suite.error then
            cgilua.put("<p><strong>ERROR</strong>:</p>")
            cgilua.put("<p>"..suite.error.."</p>")
        else
            for _, context in ipairs(suite.contexts) do
                if next(context.tests) then
                    cgilua.put("<p>")
                    for _, output in ipairs(context.output) do
                        cgilua.put(output.."<br />")
                    end
                    if context.comments then
                        cgilua.put(context.comments.."<br />")
                    end
                    cgilua.put("</p>")
%>
                    <table class="shake">
                        <thead>
                            <tr>
                                <th scope="col">Line #</th>
                                <th scope="col"></th>
                                <th scope="col"><strong>Expected</strong></th>
                                <th scope="col"><strong>Actual</strong></th>
                                <th scope="col"><strong>Message</strong></th>
                            </tr>
                        </thead>
<%                    
                    for _, test in ipairs (context.tests) do
                        local linenumber = test.linenumber or "???"
                        local op = test.op
                        local val2 = tostring(test.val2)
                        
                        if not op then
                            val2 = "<em>True</em>"
                        end
                        
                        if not op or op == "==" then
                            op = ""
                        end
                        
                        cgilua.put("<tr>")
                        cgilua.put("<td>"..linenumber.."</td>")
                        cgilua.put("<td>"..test.exp1.."</td>")
                        cgilua.put("<td>"..op..val2.."</td>")
                        cgilua.put("<td>"..tostring(test.val1).."</td>")
                        cgilua.put("<td>"..(test.msg or "").."</td>")
                        cgilua.put("</tr>")
                    end
%>
                    </table>
<%
                end
            end
        end
    end
%>

<% if results.errors > 0 or results.failed > 0 then %>
<p>Shake output:</p>
<pre class="example">
<%= run:summary() %>
</pre>
<% end  %>

<br />
<br />
<br />
<br />
<br />
<br />

</div> <!-- id="content" -->

</div> <!-- id="main" -->

<div id="about">
	<p><a href="http://validator.w3.org/check?uri=referer">Valid XHTML 1.0</a></p>
	<p><small>$Id: shake_suite.lp,v 1.1 2007/10/25 23:15:34 carregal Exp $</small></p>
</div> <!-- id="about" -->

</div> <!-- id="container" -->
</body>
</html>
