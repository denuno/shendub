<cfif structKeyExists(url,"cfe")>
	<cfset cfecall = createObject("java","org.cfeclipse.cfeclipsecall.CallClient") />
	<cfset doOpen = cfecall.doOpen("2342","/Users/denny/programs/eclipse-inst/eclipse35.command",url.cfe)>
	<cfabort />
</cfif>
<cfparam name="URL.output" default="html">
<cfparam name="url.quiet" default="false">
<cfparam name="url.email" default="true">
<cfparam name="url.emailfrom" default="valliantster@gmail.com">
<cfparam name="url.recipients" default="valliantster@gmail.com">
<!--- change this! --->
<cfset dir = expandPath(".") />
<cfoutput><h1>
		#dir# 
	</h1></cfoutput>
<cfset DTS = createObject("component","mxunit.runner.DirectoryTestSuite") />
<cfset excludes = "" />
<cfinvoke component="#DTS#" 
	method="run"
	directory="#dir#" 
	recurse="true" 
	excludes="#excludes#"
	returnvariable="Results"
	componentpath="tests">
<!---  [WEE]<-- Fill this in! This is the root component path for your tests. if your tests are at {webroot}/app1/test, then your componentpath will be app1.test   --->
<cfsetting showdebugoutput="true">
<cfoutput>
	<cfsavecontent variable="recenthtml">
		<cfif NOT StructIsEmpty(DTS.getCatastrophicErrors())>
			<cfdump var="#DTS.getCatastrophicErrors()#" expand="false" label="#StructCount(DTS.getCatastrophicErrors())# Catastrophic Errors" />
		</cfif>
		#results.getResultsOutput(URL.output)# 
<script language="JavaScript">
	var oXmlHttp
	var sDetail

	function openInEditor(file,line) {

		var url=<cfoutput>"#getContextRoot()#/mapping-tag/error.cfm?cfe="</cfoutput> + file + '|' + line;
			oXmlHttp=GetHttpObject(stateChanged)
			oXmlHttp.open("GET", url , true)
			oXmlHttp.send(null)
	}

	function stateChanged() {
		if (oXmlHttp.readyState==4 || oXmlHttp.readyState=="complete") {
		}
	}

	function GetHttpObject(handler) {
		try {
			var oRequester = new XMLHttpRequest();
				oRequester.onload=handler
				oRequester.onerror=handler
				return oRequester
		} catch (error) {
			try {
				var oRequester = new ActiveXObject("Microsoft.XMLHTTP");
				oRequester.onreadystatechange=handler
				return oRequester
			} catch (error) {
				return false;
			}
		}
	}
</script>
	</cfsavecontent>
</cfoutput>
<cfif NOT url.quiet>
	<cfoutput>#recenthtml#</cfoutput>
</cfif>
<cfif url.email>
	<!--- change this 'from' email! --->
	<cfmail from="#url.emailfrom#" to="#url.recipients#" subject="Test Results : #DateFormat(now(),'short')# @ #TimeFormat(now(),'short')#" type="html">
		#recenthtml# 
	</cfmail>
</cfif>
<cftry>
	<cfdirectory action="create" directory="#expandPath("/tests/")#/results">
	<cfcatch></cfcatch>
</cftry>
<cffile action="write" file="#expandPath("/tests/")#/results/#DateFormat(now(),'mm-dd-yyyy')#_#TimeFormat(now(),'hhmmss')#-results.html" output="#recenthtml#">
