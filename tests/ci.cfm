<cffunction name="runit">
	<cfset var properties = structNew() />
	<cfset var target = "tests.build.start.run.stop.ifnew" />
	<cfset variables.buildDirectory = getDirectoryFromPath(getCurrentTemplatePath()) & "../build/" />
	<cfset properties["temp.dir"] = getDirectoryFromPath(getCurrentTemplatePath()) & "builds" />
	<cftry>
		<cfdirectory action="delete" directory="#properties["temp.dir"]#" recurse="true" /> 
		<cfcatch></cfcatch>
	</cftry>
	<cfdirectory action="create" directory="#properties["temp.dir"]#" /> 
	<cfset properties["cfdistro.target.build.dir"] = variables.buildDirectory />
	<cfset properties["runwar.port"] = "8191" />
	<cfset properties["runwar.stop.socket"] = "8192" />
	<cf_antrunner antfile="#variables.buildDirectory#build.xml" properties="#properties#" target="#target#">
	<cfdump var="#cfantrunner#" />
</cffunction>

<cfoutput>#runit()#</cfoutput>
