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
        <li><strong><a href="shake.lp">All Suites</a></strong>
        <ul>
            <%
            for _,suite in ipairs(suites) do
            %>
            <li><strong><a href="shake_suite.lp?s=<%= suite %>"><%= suite %></a></strong></li>
            <%
            end
            if not next(suites) then
            %>
            <li><strong>(No suites)</strong></li>
            <%
            end
            %>
        </ul>
        </li>
	</ul>
</div> <!-- id="navigation" -->

<div id="content">

<h1>Shake Summary</h1>

<p>Here you have the number of tests, failures and errors for every test suite in <%= KEPLER_TESTS %></p>

<%
require"shake"
local run = shake.runner()
for _, suite in ipairs(suites) do
    lfs.chdir(KEPLER_TESTS.."/"..suite)
    run:test("test.lua", suite)
    lfs.chdir("..")
end
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
        cgilua.put("<th><strong>"..[[<a href="shake_suite.lp?s=]]..suite.title..[[">]]..suite.title..[[</a></strong></th>]].."\n".."</strong></th>\n")
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
%>
</table>

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
	<p><small>$Id: shake.lp,v 1.4 2007/10/29 20:19:05 carregal Exp $</small></p>
</div> <!-- id="about" -->

</div> <!-- id="container" -->
</body>
</html>
