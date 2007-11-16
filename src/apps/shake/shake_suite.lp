<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
   "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
    <title>Shake Tests</title>
    <link rel="stylesheet" href="<%= cgilua.mkurlpath("css/doc.css") %>" type="text/css"/>
    <link rel="stylesheet" href="<%= cgilua.mkurlpath("css/shake.css") %>" type="text/css"/>
	<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
</head>

<body>

<div id="container">

<div id="product">
	<div id="product_logo"><a href="http://shake.luaforge.net">
		<img src="<%= cgilua.mkurlpath("img/shake.gif") %>" alt="Shake Logo" /></a>
    </div>
	<div id="product_name"><big><strong></strong></big></div>
	<div id="product_description">Shake Tests</div>
</div> <!-- id="product" -->

<div id="navigation">

<h1>Shake</h1>
	<ul>
        <li><strong><a href="<%= cgilua.mkurlpath("all") %>">All</a></strong>
        <ul>
            <% ListModules() %>
        </ul>
        </li>
	</ul>
</div> <!-- id="navigation" -->

<div id="content">

<h1>Shake details for the <%= module_name %> module</h1>

<p>Here you have a more detailed view of the <%= module_name %> module tests results:</</p>

<table class="shake">
    <thead>
        <tr>
            <th scope="col"></th>
            <th scope="col"><strong>Tests</strong></th>
            <th scope="col"><strong>Failures</strong></th>
            <th scope="col"><strong>Errors</strong></th>
        </tr>
    </thead>
    <% ModuleSummary() %>
</table>

<% ReportModule() %>

<% ShakeSummary() %>

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
	<p><small>$Id: shake_suite.lp,v 1.4 2007/11/16 16:26:10 carregal Exp $</small></p>
</div> <!-- id="about" -->

</div> <!-- id="container" -->
</body>
</html>
