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
	<div id="product_logo"><a href="http://www.keplerproject.org">
		<img src="<%= cgilua.mkurlpath("img/keplerproject.gif") %>" alt="Kepler Project logo" /></a>
    </div>
	<div id="product_name"><big><strong></strong></big></div>
	<div id="product_description">Kepler Shake Tests</div>
</div> <!-- id="product" -->

<div id="main">

<div id="navigation">

<h1>Shake</h1>
	<ul>
        <li><strong><a href="<%= cgilua.mkurlpath("shake") %>">All</a></strong>
        <ul>
            <% ListSuites() %>
        </ul>
        </li>
	</ul>
</div> <!-- id="navigation" -->

<div id="content">

<h1>Shake details for the <%= suite %> suite</h1>

<p>Here you have a more detailed view of the <%= suite %> tests results:</</p>

<table class="shake">
    <thead>
        <tr>
            <th scope="col"></th>
            <th scope="col"><strong>Tests</strong></th>
            <th scope="col"><strong>Failures</strong></th>
            <th scope="col"><strong>Errors</strong></th>
        </tr>
    </thead>
    <% SuiteSummary() %>
</table>

<% ReportSuite() %>

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
	<p><small>$Id: shake_suite.lp,v 1.1 2007/11/08 22:50:17 carregal Exp $</small></p>
</div> <!-- id="about" -->

</div> <!-- id="container" -->
</body>
</html>
