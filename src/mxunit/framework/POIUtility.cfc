<!--- ------------------------------------------------------------------------- ----

	Author:		Ben Nadel
	Desc:		Handles the reading an writing of Excel files using the POI
				package that ships with ColdFusion.

				Special thanks to Ken Auenson and his suggestions:
				http://ken.auenson.com/examples/func_ExcelToQueryStruct_POI_example.txt

				Special thanks to (the following) for helping me debug:

				Close File Input stream
				- Jeremy Knue

				Null cell values
				- Richard J Julia
				- Charles Lewis
				- John Morgan

				Not creating queries for empty sheets
				- Sophek Tounn

	Sample Code:

				N/A

	Update History:

				04/04/2007 - Ben Nadel
				Fixed several know bugs including:
				- Undefined query for empty sheets.
				- Handle NULL rows.
				- Handle NULL cells.
				- Closing file input stream to OS doesn't lock file.

				02/01/2007 - Ben Nadel
				Added new line support (with text wrap). Also set the sheet's
				default column width.

				01/21/2007 - Ben Nadel
				Added basic CSS support.

				01/15/2007 - Ben Nadel
				Laid the foundations for the CFC.

----- ---------------------------------------------------------------------//// --->

<cfcomponent
	displayname="POIUtility"
	output="false"
	hint="Handles the reading and writing of Microsoft Excel files using POI and ColdFusion.">


	<cffunction name="Init" access="public" returntype="POIUtility" output="false"
		hint="Returns an initialized POI Utility instance.">

		<!--- Return This reference. --->
		<cfreturn THIS />
	</cffunction>


	<cffunction name="GetCellStyle" access="private" returntype="any" output="false"
		hint="Takes the standardized CSS object and creates an Excel cell style.">

		<!--- Define arguments. --->
		<cfargument name="WorkBook" type="any" required="true" />
		<cfargument name="CSS" type="struct" required="true" />

		<cfscript>

			// Define the local scope.
			var local = StructNew();

			// Create a default cell style object.
			local.Style = ARGUMENTS.WorkBook.CreateCellStyle();

			// Check for background color.
			if (ListFindNoCase( "AQUA,BLACK,BLUE,BLUE_GREY,BRIGHT_GREEN,BROWN,CORAL,CORNFLOWER_BLUE,DARK_BLUE,DARK_GREEN,DARK_RED,DARK_TEAL,DARK_YELLOW,GOLD,GREEN,GREY_25_PERCENT,GREY_40_PERCENT,GREY_50_PERCENT,GREY_80_PERCENT,INDIGO,LAVENDER,LEMON_CHIFFON,LIGHT_BLUE,LIGHT_CORNFLOWER_BLUE,LIGHT_GREEN,LIGHT_ORANGE,LIGHT_TURQUOISE,LIGHT_YELLOW,LIME,MAROON,OLIVE_GREEN,ORANGE,ORCHID,PALE_BLUE,PINK,PLUM,RED,ROSE,ROYAL_BLUE,SEA_GREEN,SKY_BLUE,TAN,TEAL,TURQUOISE,VIOLET,WHITE,YELLOW", ARGUMENTS.CSS[ "background-color" ] )){

				// Set the background color.
				local.Style.SetFillForegroundColor(
					CreateObject(
						"java",
						"org.apache.poi.hssf.util.HSSFColor$#UCase( ARGUMENTS.CSS[ 'background-color' ] )#"
						).GetIndex()
					);


				// Check for background style.
				switch (ARGUMENTS.CSS[ "background-style" ]){

					case "dots":
						local.Style.SetFillPattern( local.Style.FINE_DOTS );
						break;

					case "vertical":
						local.Style.SetFillPattern( local.Style.THIN_VERT_BANDS );
						break;

					case "horizontal":
						local.Style.SetFillPattern( local.Style.THIN_HORZ_BANDS );
						break;

					default:
						local.Style.SetFillPattern( local.Style.SOLID_FOREGROUND );
						break;

				}

			}


			// Check for the bottom border size.
			if (Val( ARGUMENTS.CSS[ "border-bottom-width" ] )){

				// Check the type of border.
				switch (ARGUMENTS.CSS[ "border-bottom-style" ]){

					// Figure out what kind of solid border we need.
					case "solid":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-bottom-width" ] )){

							case 1:
								local.Style.SetBorderBottom( local.Style.BORDER_HAIR );
								break;

							case 2:
								local.Style.SetBorderBottom( local.Style.BORDER_THIN );
								break;

							case 3:
								local.Style.SetBorderBottom( local.Style.BORDER_MEDIUM );
								break;

							default:
								local.Style.SetBorderBottom( local.Style.BORDER_THICK );
								break;

						}

						break;

					// Figure out what kind of dotted border we need.
					case "dotted":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-bottom-width" ] )){

							case 1:
								local.Style.SetBorderBottom( local.Style.BORDER_DOTTED );
								break;

							case 2:
								local.Style.SetBorderBottom( local.Style.BORDER_DASH_DOT_DOT );
								break;

							default:
								local.Style.SetBorderBottom( local.Style.BORDER_MEDIUM_DASH_DOT_DOT );
								break;

						}

						break;

					// Figure out what kind of dashed border we need.
					case "dashed":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-bottom-width" ] )){

							case 1:
								local.Style.SetBorderBottom( local.Style.BORDER_DASHED );
								break;

							default:
								local.Style.SetBorderBottom( local.Style.BORDER_MEDIUM_DASHED );
								break;

						}

						break;

					// There is only one option for double border.
					case "double":
						local.Style.SetBorderBottom( local.Style.BORDER_DOUBLE );
						break;

				}

				// Check for a border color.
				if (ListFindNoCase( "AQUA,BLACK,BLUE,BLUE_GREY,BRIGHT_GREEN,BROWN,CORAL,CORNFLOWER_BLUE,DARK_BLUE,DARK_GREEN,DARK_RED,DARK_TEAL,DARK_YELLOW,GOLD,GREEN,GREY_25_PERCENT,GREY_40_PERCENT,GREY_50_PERCENT,GREY_80_PERCENT,INDIGO,LAVENDER,LEMON_CHIFFON,LIGHT_BLUE,LIGHT_CORNFLOWER_BLUE,LIGHT_GREEN,LIGHT_ORANGE,LIGHT_TURQUOISE,LIGHT_YELLOW,LIME,MAROON,OLIVE_GREEN,ORANGE,ORCHID,PALE_BLUE,PINK,PLUM,RED,ROSE,ROYAL_BLUE,SEA_GREEN,SKY_BLUE,TAN,TEAL,TURQUOISE,VIOLET,WHITE,YELLOW", ARGUMENTS.CSS[ "border-bottom-color" ] )){

					local.Style.SetBottomBorderColor(
						CreateObject(
							"java",
							"org.apache.poi.hssf.util.HSSFColor$#UCase( ARGUMENTS.CSS[ 'border-bottom-color' ] )#"
							).GetIndex()
						);

				}

			}


			// Check for the left border size.
			if (Val( ARGUMENTS.CSS[ "border-left-width" ] )){

				// Check the type of border.
				switch (ARGUMENTS.CSS[ "border-left-style" ]){

					// Figure out what kind of solid border we need.
					case "solid":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-left-width" ] )){

							case 1:
								local.Style.SetBorderLeft( local.Style.BORDER_HAIR );
								break;

							case 2:
								local.Style.SetBorderLeft( local.Style.BORDER_THIN );
								break;

							case 3:
								local.Style.SetBorderLeft( local.Style.BORDER_MEDIUM );
								break;

							default:
								local.Style.SetBorderLeft( local.Style.BORDER_THICK );
								break;

						}

						break;

					// Figure out what kind of dotted border we need.
					case "dotted":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-left-width" ] )){

							case 1:
								local.Style.SetBorderLeft( local.Style.BORDER_DOTTED );
								break;

							case 2:
								local.Style.SetBorderLeft( local.Style.BORDER_DASH_DOT_DOT );
								break;

							default:
								local.Style.SetBorderLeft( local.Style.BORDER_MEDIUM_DASH_DOT_DOT );
								break;

						}

						break;

					// Figure out what kind of dashed border we need.
					case "dashed":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-left-width" ] )){

							case 1:
								local.Style.SetBorderLeft( local.Style.BORDER_DASHED );
								break;

							default:
								local.Style.SetBorderLeft( local.Style.BORDER_MEDIUM_DASHED );
								break;

						}

						break;

					// There is only one option for double border.
					case "double":
						local.Style.SetBorderLeft( local.Style.BORDER_DOUBLE );
						break;

				}

				// Check for a border color.
				if (ListFindNoCase( "AQUA,BLACK,BLUE,BLUE_GREY,BRIGHT_GREEN,BROWN,CORAL,CORNFLOWER_BLUE,DARK_BLUE,DARK_GREEN,DARK_RED,DARK_TEAL,DARK_YELLOW,GOLD,GREEN,GREY_25_PERCENT,GREY_40_PERCENT,GREY_50_PERCENT,GREY_80_PERCENT,INDIGO,LAVENDER,LEMON_CHIFFON,LIGHT_BLUE,LIGHT_CORNFLOWER_BLUE,LIGHT_GREEN,LIGHT_ORANGE,LIGHT_TURQUOISE,LIGHT_YELLOW,LIME,MAROON,OLIVE_GREEN,ORANGE,ORCHID,PALE_BLUE,PINK,PLUM,RED,ROSE,ROYAL_BLUE,SEA_GREEN,SKY_BLUE,TAN,TEAL,TURQUOISE,VIOLET,WHITE,YELLOW", ARGUMENTS.CSS[ "border-left-color" ] )){

					local.Style.SetLeftBorderColor(
						CreateObject(
							"java",
							"org.apache.poi.hssf.util.HSSFColor$#UCase( ARGUMENTS.CSS[ 'border-left-color' ] )#"
							).GetIndex()
						);

				}

			}


			// Check for the right border size.
			if (Val( ARGUMENTS.CSS[ "border-right-width" ] )){

				// Check the type of border.
				switch (ARGUMENTS.CSS[ "border-right-style" ]){

					// Figure out what kind of solid border we need.
					case "solid":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-right-width" ] )){

							case 1:
								local.Style.SetBorderRight( local.Style.BORDER_HAIR );
								break;

							case 2:
								local.Style.SetBorderRight( local.Style.BORDER_THIN );
								break;

							case 3:
								local.Style.SetBorderRight( local.Style.BORDER_MEDIUM );
								break;

							default:
								local.Style.SetBorderRight( local.Style.BORDER_THICK );
								break;

						}

						break;

					// Figure out what kind of dotted border we need.
					case "dotted":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-right-width" ] )){

							case 1:
								local.Style.SetBorderRight( local.Style.BORDER_DOTTED );
								break;

							case 2:
								local.Style.SetBorderRight( local.Style.BORDER_DASH_DOT_DOT );
								break;

							default:
								local.Style.SetBorderRight( local.Style.BORDER_MEDIUM_DASH_DOT_DOT );
								break;

						}

						break;

					// Figure out what kind of dashed border we need.
					case "dashed":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-right-width" ] )){

							case 1:
								local.Style.SetBorderRight( local.Style.BORDER_DASHED );
								break;

							default:
								local.Style.SetBorderRight( local.Style.BORDER_MEDIUM_DASHED );
								break;

						}

						break;

					// There is only one option for double border.
					case "double":
						local.Style.SetBorderRight( local.Style.BORDER_DOUBLE );
						break;

				}

				// Check for a border color.
				if (ListFindNoCase( "AQUA,BLACK,BLUE,BLUE_GREY,BRIGHT_GREEN,BROWN,CORAL,CORNFLOWER_BLUE,DARK_BLUE,DARK_GREEN,DARK_RED,DARK_TEAL,DARK_YELLOW,GOLD,GREEN,GREY_25_PERCENT,GREY_40_PERCENT,GREY_50_PERCENT,GREY_80_PERCENT,INDIGO,LAVENDER,LEMON_CHIFFON,LIGHT_BLUE,LIGHT_CORNFLOWER_BLUE,LIGHT_GREEN,LIGHT_ORANGE,LIGHT_TURQUOISE,LIGHT_YELLOW,LIME,MAROON,OLIVE_GREEN,ORANGE,ORCHID,PALE_BLUE,PINK,PLUM,RED,ROSE,ROYAL_BLUE,SEA_GREEN,SKY_BLUE,TAN,TEAL,TURQUOISE,VIOLET,WHITE,YELLOW", ARGUMENTS.CSS[ "border-right-color" ] )){

					local.Style.SetRightBorderColor(
						CreateObject(
							"java",
							"org.apache.poi.hssf.util.HSSFColor$#UCase( ARGUMENTS.CSS[ 'border-right-color' ] )#"
							).GetIndex()
						);

				}

			}


			// Check for the top border size.
			if (Val( ARGUMENTS.CSS[ "border-top-width" ] )){

				// Check the type of border.
				switch (ARGUMENTS.CSS[ "border-top-style" ]){

					// Figure out what kind of solid border we need.
					case "solid":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-top-width" ] )){

							case 1:
								local.Style.SetBorderTop( local.Style.BORDER_HAIR );
								break;

							case 2:
								local.Style.SetBorderTop( local.Style.BORDER_THIN );
								break;

							case 3:
								local.Style.SetBorderTop( local.Style.BORDER_MEDIUM );
								break;

							default:
								local.Style.SetBorderTop( local.Style.BORDER_THICK );
								break;

						}

						break;

					// Figure out what kind of dotted border we need.
					case "dotted":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-top-width" ] )){

							case 1:
								local.Style.SetBorderTop( local.Style.BORDER_DOTTED );
								break;

							case 2:
								local.Style.SetBorderTop( local.Style.BORDER_DASH_DOT_DOT );
								break;

							default:
								local.Style.SetBorderTop( local.Style.BORDER_MEDIUM_DASH_DOT_DOT );
								break;

						}

						break;

					// Figure out what kind of dashed border we need.
					case "dashed":

						// Check the width.
						switch(Val( ARGUMENTS.CSS[ "border-top-width" ] )){

							case 1:
								local.Style.SetBorderTop( local.Style.BORDER_DASHED );
								break;

							default:
								local.Style.SetBorderTop( local.Style.BORDER_MEDIUM_DASHED );
								break;

						}

						break;

					// There is only one option for double border.
					case "double":
						local.Style.SetBorderTop( local.Style.BORDER_DOUBLE );
						break;

				}

				// Check for a border color.
				if (ListFindNoCase( "AQUA,BLACK,BLUE,BLUE_GREY,BRIGHT_GREEN,BROWN,CORAL,CORNFLOWER_BLUE,DARK_BLUE,DARK_GREEN,DARK_RED,DARK_TEAL,DARK_YELLOW,GOLD,GREEN,GREY_25_PERCENT,GREY_40_PERCENT,GREY_50_PERCENT,GREY_80_PERCENT,INDIGO,LAVENDER,LEMON_CHIFFON,LIGHT_BLUE,LIGHT_CORNFLOWER_BLUE,LIGHT_GREEN,LIGHT_ORANGE,LIGHT_TURQUOISE,LIGHT_YELLOW,LIME,MAROON,OLIVE_GREEN,ORANGE,ORCHID,PALE_BLUE,PINK,PLUM,RED,ROSE,ROYAL_BLUE,SEA_GREEN,SKY_BLUE,TAN,TEAL,TURQUOISE,VIOLET,WHITE,YELLOW", ARGUMENTS.CSS[ "border-top-color" ] )){

					local.Style.SetTopBorderColor(
						CreateObject(
							"java",
							"org.apache.poi.hssf.util.HSSFColor$#UCase( ARGUMENTS.CSS[ 'border-top-color' ] )#"
							).GetIndex()
						);

				}

			}


			// Get a font object from the workbook.
			local.Font = ARGUMENTS.WorkBook.CreateFont();

			// Check for color.
			if (ListFindNoCase( "AQUA,BLACK,BLUE,BLUE_GREY,BRIGHT_GREEN,BROWN,CORAL,CORNFLOWER_BLUE,DARK_BLUE,DARK_GREEN,DARK_RED,DARK_TEAL,DARK_YELLOW,GOLD,GREEN,GREY_25_PERCENT,GREY_40_PERCENT,GREY_50_PERCENT,GREY_80_PERCENT,INDIGO,LAVENDER,LEMON_CHIFFON,LIGHT_BLUE,LIGHT_CORNFLOWER_BLUE,LIGHT_GREEN,LIGHT_ORANGE,LIGHT_TURQUOISE,LIGHT_YELLOW,LIME,MAROON,OLIVE_GREEN,ORANGE,ORCHID,PALE_BLUE,PINK,PLUM,RED,ROSE,ROYAL_BLUE,SEA_GREEN,SKY_BLUE,TAN,TEAL,TURQUOISE,VIOLET,WHITE,YELLOW", ARGUMENTS.CSS[ "color" ] )){

				local.Font.SetColor(
					CreateObject(
						"java",
						"org.apache.poi.hssf.util.HSSFColor$#UCase( ARGUMENTS.CSS[ 'color' ] )#"
						).GetIndex()
					);

			}


			// Check for font family.
			if (Len( ARGUMENTS.CSS[ "font-family" ] )){

				local.Font.SetFontName(
					JavaCast( "string", ARGUMENTS.CSS[ "font-family" ] )
					);

			}


			// Check for font size.
			if (Val( ARGUMENTS.CSS[ "font-size" ] )){

				local.Font.SetFontHeightInPoints(
					JavaCast( "int", Val( ARGUMENTS.CSS[ "font-size" ] ) )
					);

			}


			// Check for font style.
			if (Len( ARGUMENTS.CSS[ "font-style" ] )){

				// Figure out which style we are talking about.
				switch (ARGUMENTS.CSS[ "font-style" ]){

					case "italic":
						local.Font.SetItalic(
							JavaCast( "boolean", true )
							);
						break;

				}

			}


			// Check for font weight.
			if (Len( ARGUMENTS.CSS[ "font-weight" ] )){

				// Figure out what font weight we are using.
				switch (ARGUMENTS.CSS[ "font-weight" ]){

					case "bold":
						local.Font.SetBoldWeight(
							local.Font.BOLDWEIGHT_BOLD
							);
						break;

				}

			}


			// Apply the font to the style object.
			local.Style.SetFont( local.Font );


			// Check for cell text alignment.
			switch (ARGUMENTS.CSS[ "text-align" ]){

				case "right":
					local.Style.SetAlignment( local.Style.ALIGN_RIGHT );
					break;

				case "center":
					local.Style.SetAlignment( local.Style.ALIGN_CENTER );
					break;

				case "justify":
					local.Style.SetAlignment( local.Style.ALIGN_JUSTIFY );
					break;

			}


			// Cehck for cell vertical text alignment.
			switch (ARGUMENTS.CSS[ "vertical-align" ]){

				case "bottom":
					local.Style.SetVerticalAlignment( local.Style.VERTICAL_BOTTOM );
					break;

				case "middle":
					local.Style.SetVerticalAlignment( local.Style.VERTICAL_CENTER );
					break;

				case "center":
					local.Style.SetVerticalAlignment( local.Style.VERTICAL_CENTER );
					break;

				case "justify":
					local.Style.SetVerticalAlignment( local.Style.VERTICAL_JUSTIFY );
					break;

				case "top":
					local.Style.SetVerticalAlignment( local.Style.VERTICAL_TOP );
					break;

			}


			// Set the cell to wrap text. This will allow new lines to show
			// up properly in the text.
			local.Style.SetWrapText(
				JavaCast( "boolean", true )
				);


			// Return the style object.
			return( local.Style );

		</cfscript>
	</cffunction>


	<cffunction name="GetNewSheetStruct" access="public" returntype="struct" output="false"
		hint="Returns a default structure of what this Component is expecting for a sheet definition when WRITING Excel files.">

		<!--- Define the local scope. --->
		<cfset var local = StructNew() />

		<cfscript>

			// This is the query that will hold the data.
			local.Query = "";

			// THis is the list of columns (in a given order) that will be
			// used to output data.
			local.ColumnList = "";

			// These are the names of the columns used when creating a header
			// row in the Excel file.
			local.ColumnNames = "";

			// This is the name of the sheet as it appears in the bottom Excel tab.
			local.SheetName = "";

			// Return the local structure containing the sheet info.
			return( local );

		</cfscript>
	</cffunction>


	<cffunction name="ParseRawCSS" access="private" returntype="struct" output="false"
		hint="This takes raw HTML-style CSS and returns a default CSS structure with overwritten parsed values.">

		<!--- Define arguments. --->
		<cfargument name="CSS" type="string" required="false" default="" />

		<cfscript>

			// Define the local scope.
			var local = StructNew();

			// Create a new CSS structure.
			local.CSS = StructNew();

			// Set default values.
			local.CSS[ "background-color" ] = "";
			local.CSS[ "background-style" ] = "";
			local.CSS[ "border-bottom-color" ] = "";
			local.CSS[ "border-bottom-style" ] = "";
			local.CSS[ "border-bottom-width" ] = "";
			local.CSS[ "border-left-color" ] = "";
			local.CSS[ "border-left-style" ] = "";
			local.CSS[ "border-left-width" ] = "";
			local.CSS[ "border-right-color" ] = "";
			local.CSS[ "border-right-style" ] = "";
			local.CSS[ "border-right-width" ] = "";
			local.CSS[ "border-top-color" ] = "";
			local.CSS[ "border-top-style" ] = "";
			local.CSS[ "border-top-width" ] = "";
			local.CSS[ "color" ] = "";
			local.CSS[ "font-family" ] = "";
			local.CSS[ "font-size" ] = "";
			local.CSS[ "font-style" ] = "";
			local.CSS[ "font-weight" ] = "";
			local.CSS[ "text-align" ] = "";
			local.CSS[ "vertical-align" ] = "";


			// Clean up the raw CSS values. We don't want to deal with complext CSS
			// delcarations like font: bold 12px verdana. We want each style to be
			// defined individually. Keep attacking the raw css and replacing in the
			// single-values. Clean the initial white space first.
			local.CleanCSS = ARGUMENTS.CSS.Trim().ToLowerCase().ReplaceAll(

				"\s+", " "

			// Make sure that all colons are right to the right of their types followed
			// by a single space to rhe right.
			).ReplaceAll(

				"\s*:\s*", ": "

			// Break out the full font declaration into parts.
			).ReplaceAll(

				"font: bold (\d+\w{2}) (\w+)",
				"font-size: $1 ; font-family: $2 ; font-weight: bold ;"

			// Break out the full font declaration into parts.
			).ReplaceAll(

				"font: italic (\d+\w{2}) (\w+)",
				"font-size: $1 ; font-family: $2 ; font-style: italic ;"

			// Break out the partial font declaration into parts.
			).ReplaceAll(

				"font: (\d+\w{2}) (\w+)",
				"font-size: $1 ; font-family: $2 ;"

			// Break out a font family name.
			).ReplaceAll(

				"font: (\w+)",
				"font-family: $1 ;"

			// Break out the full border definition into single values for each of the
			// four possible borders.
			).ReplaceAll(

				"border: (\d+\w{2}) (solid|dotted|dashed|double) (\w+)",
				"border-top-width: $1 ; border-top-style: $2 ; border-top-color: $3 ; border-right-width: $1 ; border-right-style: $2 ; border-right-color: $3 ; border-bottom-width: $1 ; border-bottom-style: $2 ; border-bottom-color: $3 ; border-left-width: $1 ; border-left-style: $2 ; border-left-color: $3 ;"

			// Break out a partial border definition into values for each of the four
			// possible borders. Set default color to black.
			).ReplaceAll(

				"border: (\d+\w{2}) (solid|dotted|dashed|double)",
				"border-top-width: $1 ; border-top-style: $2 ; border-top-color: black ; border-right-width: $1 ; border-right-style: $2 ; border-right-color: black ; border-bottom-width: $1 ; border-bottom-style: $2 ; border-bottom-color: black ; border-left-width: $1 ; border-left-style: $2 ; border-left-color: black ;"

			// Break out a partial border definition into values for each of the four
			// possible borders. Set default color to black and width to 2px.
			).ReplaceAll(

				"border: (solid|dotted|dashed|double)",
				"border-top-width: 2px ; border-top-style: $2 ; border-top-color: black ; border-right-width: 2px ; border-right-style: $2 ; border-right-color: black ; border-bottom-width: 2px ; border-bottom-style: $2 ; border-bottom-color: black ; border-left-width: 2px ; border-left-style: $2 ; border-left-color: black ;"

			// Break out full, single-border definitions into single values.
			).ReplaceAll(

				"(border-(top|right|bottom|left)): (\d+\w{2}) (solid|dotted|dashed|double) (\w+)",
				"$1-width: $3 ; $1-style: $4 ; $1-color: $5 ;"

			// Break out partial bord to single values. Set default color to black.
			).ReplaceAll(

				"(border-(top|right|bottom|left)): (\d+\w{2}) (solid|dotted|dashed|double)",
				"$1-width: $3 ; $1-style: $4 ; $1-color: black ;"

			// Break out partial bord to single values. Set default color to black and
			// default width to 2px.
			).ReplaceAll(

				"(border-(top|right|bottom|left)): (solid|dotted|dashed|double)",
				"$1-width: 2px ; $1-style: $3 ; $1-color: black ;"

			// Break 4 part width definition into single width definitions to each of
			// the four possible borders.
			).ReplaceAll(

				"border-width: (\d\w{2}) (\d\w{2}) (\d\w{2}) (\d\w{2})",
				"border-top-width: $1 ; border-right-width: $2 ; border-bottom-width: $3 ; border-left-width: $4 ;"

			// Break out full background in single values.
			).ReplaceAll(

				"background: (solid|dots|vertical|horizontal) (\w+)",
				"background-style: $1 ; background-color: $2 ;"

			// Break out the partial background style into a single value style.
			).ReplaceAll(

				"background: (solid|dots|vertical|horizontal)",
				"background-style: $1 ;"

			// Break out the partial background color into a single value style.
			).ReplaceAll(

				"background: (\w+)",
				"background-color: $1 ;"

			// Clear out extra semi colons.
			).ReplaceAll(

				"(\s*;\s*)+",
				" ; "

			);


			// Break the clean CSS into name-value pairs.
			local.Pairs = ListToArray( local.CleanCSS, ";" );

			// Loop over each CSS pair.
			for (
				local.PairIterator = local.Pairs.Iterator() ;
				local.PairIterator.HasNext() ;
				){

				// Break out the name value pair.
				local.Pair = ToString(local.PairIterator.Next().Trim() & " : ").Split( ":" );

				// Get the name and value values.
				local.Name = local.Pair[ 1 ].Trim();
				local.Value = local.Pair[ 2 ].Trim();

				// Check to see if the name exists in the CSS struct. Remember, we only
				// want to allow values that we KNOW how to handle.
				if (StructKeyExists( local.CSS, local.Name )){

					// This is cool, overwrite it. At this point, however, we might
					// not have exactly proper values. Not sure if I want to deal with that here
					// or during the CSS application.
					local.CSS[ local.Name ] = local.Value;

				}

			}


			// Return the default CSS object.
			return( local.CSS );

		</cfscript>
	</cffunction>


	<cffunction name="ReadExcel" access="public" returntype="any" output="false"
		hint="Reads an Excel file into an array of strutures that contains the Excel file information OR if a specific sheet index is passed in, only that sheet object is returned.">

		<!--- Define arguments. --->
		<cfargument
			name="FilePath"
			type="string"
			required="true"
			hint="The expanded file path of the Excel file."
			/>

		<cfargument
			name="HasHeaderRow"
			type="boolean"
			required="false"
			default="false"
			hint="Flags the Excel files has using the first data row a header column. If so, this column will be excluded from the resultant query."
			/>

		<cfargument
			name="SheetIndex"
			type="numeric"
			required="false"
			default="-1"
			hint="If passed in, only that sheet object will be returned (not an array of sheet objects)."
			/>

		<cfscript>

			// Define the local scope.
			var local = StructNew();


			// Create a file input stream to the given Excel file.
			local.FileInputStream = CreateObject( "java", "java.io.FileInputStream" ).Init( ARGUMENTS.FilePath );

			// Create the Excel file system object. This object is responsible
			// for reading in the given Excel file.
			local.ExcelFileSystem = CreateObject( "java", "org.apache.poi.poifs.filesystem.POIFSFileSystem" ).Init( local.FileInputStream );


			// Get the workbook from the Excel file system.
			local.WorkBook = CreateObject(
				"java",
				"org.apache.poi.hssf.usermodel.HSSFWorkbook"
				).Init(
					local.ExcelFileSystem
					);


			// Check to see if we are returning an array of sheets OR just
			// a given sheet.
			if (ARGUMENTS.SheetIndex GTE 0){

				// Read the sheet data for a single sheet.
				local.Sheets = ReadExcelSheet(
					local.WorkBook,
					ARGUMENTS.SheetIndex,
					ARGUMENTS.HasHeaderRow
					);

			} else {

				// No specific sheet was requested. We are going to return an array
				// of sheets within the Excel document.

				// Create an array to return.
				local.Sheets = ArrayNew( 1 );

				// Loop over the sheets in the documnet.
				for (
					local.SheetIndex = 0 ;
					local.SheetIndex LT local.WorkBook.GetNumberOfSheets() ;
					local.SheetIndex = (local.SheetIndex + 1)
					){

					// Add the sheet information.
					ArrayAppend(
						local.Sheets,
						ReadExcelSheet(
							local.WorkBook,
							local.SheetIndex,
							ARGUMENTS.HasHeaderRow
							)
						);

				}



			}


			// Now that we have crated the Excel file system,
			// and read in the sheet data, we can close the
			// input file stream so that it is not locked.
			local.FileInputStream.Close();

			// Return the array of sheets.
			return( local.Sheets );

		</cfscript>
	</cffunction>


	<cffunction name="ReadExcelSheet" access="public" returntype="struct" output="false"
		hint="Takes an Excel workbook and reads the given sheet (by index) into a structure.">

		<!--- Define arguments. --->
		<cfargument
			name="WorkBook"
			type="any"
			required="true"
			hint="This is a workbook object created by the POI API."
			/>

		<cfargument
			name="SheetIndex"
			type="numeric"
			required="false"
			default="0"
			hint="This is the index of the sheet within the passed in workbook. This is a ZERO-based index (coming from a Java object)."
			/>

		<cfargument
			name="HasHeaderRow"
			type="boolean"
			required="false"
			default="false"
			hint="This flags the sheet as having a header row or not (if so, it will NOT be read into the query)."
			/>

		<cfscript>

			// Define the local scope.
			var local = StructNew();

			// Set up the default return structure.
			local.SheetData = StructNew();

			// This is the index of the sheet within the workbook.
			local.SheetData.Index = ARGUMENTS.SheetIndex;

			// This is the name of the sheet tab.
			local.SheetData.Name = ARGUMENTS.WorkBook.GetSheetName(
				JavaCast( "int", ARGUMENTS.SheetIndex )
				);

			// This is the query created from the sheet.
			local.SheetData.Query = QueryNew( "" );

			// This is a flag for the header row.
			local.SheetData.HasHeaderRow = ARGUMENTS.HasHeaderRow;

			// This keeps track of the min number of data columns.
			local.SheetData.MinColumnCount = 0;

			// This keeps track of the max number of data columns.
			local.SheetData.MaxColumnCount = 0;


			// Get the sheet object at this index of the
			// workbook. This is based on the passed in data.
			local.Sheet = ARGUMENTS.WorkBook.GetSheetAt(
				JavaCast( "int", ARGUMENTS.SheetIndex )
				);

			// An array of header columns names.
			local.SheetData.ColumnNames = ArrayNew(1);
			local.SheetData.ColumnNames = getSheetColumnNames(Local.Sheet,Arguments.HasHeaderRow);

			// Loop over the rows in the Excel sheet. For each
			// row, we simply want to capture the number of
			// columns we are working with that are NOT blank.
			// We will then use that data to figure out how many
			// columns we should be using in our query.
			for (
				local.RowIndex = 0 ;
				local.RowIndex LTE local.Sheet.GetLastRowNum() ;
				local.RowIndex = (local.RowIndex + 1)
				){

				// Get a reference to the current row.
				local.Row = local.Sheet.GetRow(
					JavaCast( "int", local.RowIndex )
					);

				// Check to see if we are at an undefined row. If we are, then
				// our ROW variable has been destroyed.
				if (StructKeyExists( local, "Row" )){

					// Get the number of the last cell in the row. Since we
					// are in a defined row, we know that we must have at
					// least one row cell defined (and therefore, we must have
					// a defined cell number).
					local.ColumnCount = local.Row.GetLastCellNum();

					// Update the running min column count.
					local.SheetData.MinColumnCount = Min(
						local.SheetData.MinColumnCount,
						local.ColumnCount
						);

					// Update the running max column count.
					local.SheetData.MaxColumnCount = Max(
						local.SheetData.MaxColumnCount,
						local.ColumnCount
						);

				}

			}


			// ASSERT: At this point, we know the min and max
			// number of columns that we will encounter in this
			// excel sheet.


			// Loop over the number of column to create the basic
			// column structure that we will use in our query.
			for (
				local.ColumnIndex = 1 ;
				local.ColumnIndex LTE local.SheetData.MaxColumnCount ;
				local.ColumnIndex = (local.ColumnIndex + 1)
				){

				// Add the column. Notice that the name of the column is
				// the text "column" plus the column index. I am starting
				// my column indexes at ONE rather than ZERO to get it back
				// into a more ColdFusion standard notation.
				QueryAddColumn(
					local.SheetData.Query,
					local.SheetData.ColumnNames[local.ColumnIndex],
					"CF_SQL_VARCHAR",
					ArrayNew( 1 )
					);

			}


			// ASSERT: At this pointer, we have a properly defined
			// query that will be able to handle any standard row
			// data that we encouter.


			// Loop over the rows in the Excel sheet. This time, we
			// already have a query built, so we just want to start
			// capturing the cell data.
			for (
				local.RowIndex = 0 ;
				local.RowIndex LTE local.Sheet.GetLastRowNum() ;
				local.RowIndex = (local.RowIndex + 1)
				){


				// Get a reference to the current row.
				local.Row = local.Sheet.GetRow(
					JavaCast( "int", local.RowIndex )
					);


				// We want to add a row to the query so that we can
				// store the Excel cell values. The only thing we need to
				// be careful of is that we DONT want to add a row if
				// we are dealing with a header row.
				if (
					local.RowIndex OR
					(
						(NOT ARGUMENTS.HasHeaderRow) AND
						StructKeyExists( local, "Row" )
					)){

					// We wither don't have a header row, or we are no
					// longer in the first row... add record.
					QueryAddRow( local.SheetData.Query );

				}


				// Check to see if we have a row. If we requested an
				// undefined row, then the NULL value will have
				// destroyed our Row variable.
				if (StructKeyExists( local, "Row" )){

					// Get the number of the last cell in the row. Since we
					// are in a defined row, we know that we must have at
					// least one row cell defined (and therefore, we must have
					// a defined cell number).
					local.ColumnCount = local.Row.GetLastCellNum();

					// Now that we have an empty query, we are going to loop over
					// the cells COUNT for this data row and for each cell, we are
					// going to create a query column of type VARCHAR. I understand
					// that cells are going to have different data types, but I am
					// chosing to store everything as a string to make it easier.
					for (
						local.ColumnIndex = 0 ;
						local.ColumnIndex LT local.ColumnCount ;
						local.ColumnIndex = (local.ColumnIndex + 1)
						){

						// Check to see if we might be dealing with a header row.
						// This will be true if we are in the first row AND if
						// the user had flagged the header row usage.
						if (
							ARGUMENTS.HasHeaderRow AND
							(NOT local.RowIndex)
							){

							// Try to get a header column name (it might throw
							// an error). We want to take that cell value and
							// add it to the array of header values that we will
							// return with the sheet data.
							/*try {

								// Add the cell value to the column names.
								ArrayAppend(
									local.SheetData.ColumnNames,
									local.Row.GetCell(
										JavaCast( "int", local.ColumnIndex )
										).GetStringCellValue()
									);

							} catch (any ErrorHeader){

								// There was an error grabbing the text of the
								// header column type. Just add an empty string
								// to make up for it.
								ArrayAppend(
									local.SheetData.ColumnNames,
									""
									);

							}
							*/


						// We are either not using a Header row or we are no
						// longer dealing with the first row. In either case,
						// this data is standard cell data.
						} else {

							// When getting the value of a cell, it is important to know
							// what type of cell value we are dealing with. If you try
							// to grab the wrong value type, an error might be thrown.
							// For that reason, we must check to see what type of cell
							// we are working with. These are the cell types and they
							// are constants of the cell object itself:
					 		//
							// 0 - CELL_TYPE_NUMERIC
							// 1 - CELL_TYPE_STRING
							// 2 - CELL_TYPE_FORMULA
							// 3 - CELL_TYPE_BLANK
							// 4 - CELL_TYPE_BOOLEAN
							// 5 - CELL_TYPE_ERROR

							// Get the cell from the row object.
							local.Cell = local.Row.GetCell(
								JavaCast( "int", local.ColumnIndex )
								);

							// Check to see if we are dealing with a valid cell value.
							// If this was an undefined cell, the GetCell() will
							// have returned NULL which will have killed our Cell
							// variable.
							if (StructKeyExists( local, "Cell" )){

								// ASSERT: We are definitely dealing with a valid
								// cell which has some sort of defined value.

								// Get the type of data in this cell.
								local.CellType = local.Cell.GetCellType();


								// Get teh value of the cell based on the data type. The thing
								// to worry about here is cell forumlas and cell dates. Formulas
								// can be strange and dates are stored as numeric types. For
								// this demo, I am not going to worry about that at all. I will
								// just grab dates as floats and formulas I will try to grab as
								// numeric values.
								if (local.CellType EQ local.Cell.CELL_TYPE_NUMERIC) {

									// Get numeric cell data. This could be a standard number,
									// could also be a date value. I am going to leave it up to
									// the calling program to decide.
									local.CellValue = local.Cell.GetNumericCellValue();

								} else if (local.CellType EQ local.Cell.CELL_TYPE_STRING){

									local.CellValue = local.Cell.GetStringCellValue();

								} else if (local.CellType EQ local.Cell.CELL_TYPE_FORMULA){

									// Since most forumlas deal with numbers, I am going to try
									// to grab the value as a number. If that throws an error, I
									// will just grab it as a string value.
									try {

										local.CellValue = local.Cell.GetNumericCellValue();

									} catch (any Error1){

										// The numeric grab failed. Try to get the value as a
										// string. If this fails, just force the empty string.
										try {

											local.CellValue = local.Cell.GetStringCellValue();

										} catch (any Error2){

											// Force empty string.
											local.CellValue = "";

						 				}
									}

								} else if (local.CellType EQ local.Cell.CELL_TYPE_BLANK){

									local.CellValue = "";

								} else if (local.CellType EQ local.Cell.CELL_TYPE_BOOLEAN){

									local.CellValue = local.Cell.GetBooleanCellValue();

								} else {

									// If all else fails, get empty string.
									local.CellValue = "";

								}


								// ASSERT: At this point, we either got the cell value out of the
								// Excel data cell or we have thrown an error or didn't get a
								// matching type and just have the empty string by default.
								// No matter what, the object local.CellValue is defined and
								// has some sort of SIMPLE ColdFusion value in it.


								// Now that we have a value, store it as a string in the ColdFusion
								// query object. Remember again that my query names are ONE based
								// for ColdFusion standards. That is why I am adding 1 to the
								// cell index.
								local.SheetData.Query[ local.SheetData.ColumnNames[local.ColumnIndex+1] ][ local.SheetData.Query.RecordCount ] = JavaCast( "string", local.CellValue );

							}

						}

					}

				}

			}


			// Return the sheet object that contains all the Excel data.
			return(
				local.SheetData
				);

		</cfscript>
	</cffunction>
	
	<cffunction name="readExcelToArray" output="false" access="public" returntype="array" hint="returns a 2D array of data">
		<cfargument name="filePath" required="true" type="string" hint="full path to file">
		<cfargument name="hasHeaderRow" required="false" type="boolean" default="false" hint="whether the first row is a header row. If so, the values in the first row will be used as column names; otherwise, columns will be derived">
		<cfargument name="sheetIndex" required="false" type="numeric" default="0">
		<cfscript>
		var result = readExcel(filePath=arguments.filePath, hasHeaderRow=arguments.hasHeaderRow,sheetIndex=arguments.sheetIndex);
		var q = result.query; var cols = result.columnNames;
		var col = ""; var row = ""; var a = ArrayNew(2);
		for(row=1; row LTE q.RecordCount; row=row+1){
			for(col=1; col LTE ArrayLen(cols); col=col+1){
				a[row][col] = q[ cols[col] ][row];
			}			
		}
		return a;
		</cfscript>
	</cffunction>


	<cffunction name="WriteExcel" access="public" returntype="void" output="false"
		hint="Takes an array of 'Sheet' structure objects and writes each of them to a tab in the Excel file.">

		<!--- Define arguments. --->
		<cfargument
			name="FilePath"
			type="string"
			required="true"
			hint="This is the expanded path of the Excel file."
			/>

		<cfargument
			name="Sheets"
			type="any"
			required="true"
			hint="This is an array of the data that is needed for each sheet of the excel OR it is a single Sheet object. Each 'Sheet' will be a structure containing the Query, ColumnList, ColumnNames, and SheetName."
			/>

		<cfargument
			name="Delimiters"
			type="string"
			required="false"
			default=","
			hint="The list of delimiters used for the column list and column name arguments."
			/>

		<cfargument
			name="HeaderCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the header row (if a header row is used)."
			/>

		<cfargument
			name="RowCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the non-header rows."
			/>

		<cfargument
			name="AltRowCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the alternate non-header rows. This style overwrites parts of the RowCSS."
			/>

		<cfscript>

			// Set up local scope.
			var local = StructNew();

			// Create Excel workbook.
			local.WorkBook = CreateObject(
				"java",
				"org.apache.poi.hssf.usermodel.HSSFWorkbook"
				).Init();

			// Check to see if we are dealing with an array of sheets or if we were
			// passed in a single sheet.
			if (IsArray( ARGUMENTS.Sheets )){

				// This is an array of sheets. We are going to write each one of them
				// as a tab to the Excel file. Loop over the sheet array to create each
				// sheet for the already created workbook.
				for (
					local.SheetIndex = 1 ;
					local.SheetIndex LTE ArrayLen( ARGUMENTS.Sheets ) ;
					local.SheetIndex = (local.SheetIndex + 1)
					){


					// Create sheet for the given query information..
					WriteExcelSheet(
						WorkBook = local.WorkBook,
						Query = ARGUMENTS.Sheets[ local.SheetIndex ].Query,
						ColumnList = ARGUMENTS.Sheets[ local.SheetIndex ].ColumnList,
						ColumnNames = ARGUMENTS.Sheets[ local.SheetIndex ].ColumnNames,
						SheetName = ARGUMENTS.Sheets[ local.SheetIndex ].SheetName,
						Delimiters = ARGUMENTS.Delimiters,
						HeaderCSS = ARGUMENTS.HeaderCSS,
						RowCSS = ARGUMENTS.RowCSS,
						AltRowCSS = ARGUMENTS.AltRowCSS
						);

				}

			} else {

				// We were passed in a single sheet object. Write this sheet as the
				// first and only sheet in the already created workbook.
				WriteExcelSheet(
					WorkBook = local.WorkBook,
					Query = ARGUMENTS.Sheets.Query,
					ColumnList = ARGUMENTS.Sheets.ColumnList,
					ColumnNames = ARGUMENTS.Sheets.ColumnNames,
					SheetName = ARGUMENTS.Sheets.SheetName,
					Delimiters = ARGUMENTS.Delimiters,
					HeaderCSS = ARGUMENTS.HeaderCSS,
					RowCSS = ARGUMENTS.RowCSS,
					AltRowCSS = ARGUMENTS.AltRowCSS
					);

			}


			// ASSERT: At this point, either we were passed a single Sheet object
			// or we were passed an array of sheets. Either way, we now have all
			// of sheets written to the WorkBook object.


			// Create a file based on the path that was passed in. We will stream
			// the work data to the file via a file output stream.
			local.FileOutputStream = CreateObject(
				"java",
				"java.io.FileOutputStream"
				).Init(

					JavaCast(
						"string",
						ARGUMENTS.FilePath
						)

					);

			// Write the workout data to the file stream.
			local.WorkBook.Write(
				local.FileOutputStream
				);

			// Close the file output stream. This will release any locks on
			// the file and finalize the process.
			local.FileOutputStream.Close();

			// Return out.
			return;

		</cfscript>
	</cffunction>


	<cffunction name="WriteExcelSheet" access="public" returntype="void" output="false"
		hint="Writes the given 'Sheet' structure to the given workbook.">

		<!--- Define arguments. --->
		<cfargument
			name="WorkBook"
			type="any"
			required="true"
			hint="This is the Excel workbook that will create the sheets."
			/>

		<cfargument
			name="Query"
			type="any"
			required="true"
			hint="This is the query from which we will get the data."
			/>

		<cfargument
			name="ColumnList"
			type="string"
			required="false"
			default="#ARGUMENTS.Query.ColumnList#"
			hint="This is list of columns provided in custom-ordered."
			/>

		<cfargument
			name="ColumnNames"
			type="string"
			required="false"
			default=""
			hint="This the the list of optional header-row column names. If this is not provided, no header row is used."
			/>

		<cfargument
			name="SheetName"
			type="string"
			required="false"
			default="Sheet #(ARGUMENTS.WorkBook.GetNumberOfSheets() + 1)#"
			hint="This is the optional name that appears in this sheet's tab."
			/>

		<cfargument
			name="Delimiters"
			type="string"
			required="false"
			default=","
			hint="The list of delimiters used for the column list and column name arguments."
			/>

		<cfargument
			name="HeaderCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the header row (if a header row is used)."
			/>

		<cfargument
			name="RowCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the non-header rows."
			/>

		<cfargument
			name="AltRowCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the alternate non-header rows. This style overwrites parts of the RowCSS."
			/>

		<cfscript>

			// Set up local scope.
			var local = StructNew();

			// Set up data type map so that we can map each column name to
			// the type of data contained.
			local.DataMap = StructNew();

			// Get the meta data of the query to help us create the data mappings.
			local.MetaData = GetMetaData( ARGUMENTS.Query );

			// Loop over meta data values to set up the data mapping.
			for (
				local.MetaIndex = 1 ;
				local.MetaIndex LTE ArrayLen( local.MetaData ) ;
				local.MetaIndex = (local.MetaIndex + 1)
				){

				// Map the column name to the data type.
				local.DataMap[ local.MetaData[ local.MetaIndex ].Name ] = local.MetaData[ local.MetaIndex ].TypeName;
			}


			// Create standardized header CSS by parsing the raw header css.
			local.HeaderCSS = ParseRawCSS( ARGUMENTS.HeaderCSS );

			// Get the header style object based on the CSS.
			local.HeaderStyle = GetCellStyle(
				WorkBook = ARGUMENTS.WorkBook,
				CSS = local.HeaderCSS
				);


			// Create standardized row CSS by parsing the raw row css.
			local.RowCSS = ParseRawCSS( ARGUMENTS.RowCSS );

			// Get the row style object based on the CSS.
			local.RowStyle = GetCellStyle(
				WorkBook = ARGUMENTS.WorkBook,
				CSS = local.RowCSS
				);


			// Create standardized alt-row CSS by parsing the raw alt-row css.
			local.AltRowCSS = ParseRawCSS( ARGUMENTS.AltRowCSS );

			// Now, loop over alt row css and check for values. If there are not
			// values (no length), then overwrite the alt row with the standard
			// row. This is a round-about way of letting the alt row override
			// the standard row.
			for (local.Key in local.AltRowCSS){

				// Check for value.
				if (NOT Len( local.AltRowCSS[ local.Key ] )){

					// Since we don't have an alt row style, copy over the standard
					// row style's value for this key.
					local.AltRowCSS[ local.Key ] = local.RowCSS[ local.Key ];

				}

			}

			// Get the alt-row style object based on the CSS.
			local.AltRowStyle = GetCellStyle(
				WorkBook = ARGUMENTS.WorkBook,
				CSS = local.AltRowCSS
				);


			// Create the sheet in the workbook.
			local.Sheet = ARGUMENTS.WorkBook.CreateSheet(
				JavaCast(
					"string",
					ARGUMENTS.SheetName
					)
				);

			// Set the sheet's default column width.
			local.Sheet.SetDefaultColumnWidth(
				JavaCast( "int", 23 )
				);


			// Set a default row offset so that we can keep add the header
			// column without worrying about it later.
			local.RowOffset = -1;

			// Check to see if we have any column names. If we do, then we
			// are going to create a header row with these names in order
			// based on the passed in delimiter.
			if (Len( ARGUMENTS.ColumnNames )){

				// Convert the column names to an array for easier
				// indexing and faster access.
				local.ColumnNames = ListToArray(
					ARGUMENTS.ColumnNames,
					ARGUMENTS.Delimiters
					);

				// Create a header row.
				local.Row = local.Sheet.CreateRow(
					JavaCast( "int", 0 )
					);

				// Set the row height.
				/*
				local.Row.SetHeightInPoints(
					JavaCast( "float", 14 )
					);
				*/


				// Loop over the column names.
				for (
					local.ColumnIndex = 1 ;
					local.ColumnIndex LTE ArrayLen( local.ColumnNames ) ;
					local.ColumnIndex = (local.ColumnIndex + 1)
					){

					// Create a cell for this column header.
					local.Cell = local.Row.CreateCell(
						JavaCast( "int", (local.ColumnIndex - 1) )
						);

					// Set the cell value.
					local.Cell.SetCellValue(
						JavaCast(
							"string",
							local.ColumnNames[ local.ColumnIndex ]
							)
						);

					// Set the header cell style.
					local.Cell.SetCellStyle(
						local.HeaderStyle
						);

				}

				// Set the row offset to zero since this will take care of
				// the zero-based index for the rest of the query records.
				local.RowOffset = 0;

			}

			// Convert the list of columns to the an array for easier
			// indexing and faster access.
			local.Columns = ListToArray(
				ARGUMENTS.ColumnList,
				ARGUMENTS.Delimiters
				);

			// Loop over the query records to add each one to the
			// current sheet.
			for (
				local.RowIndex = 1 ;
				local.RowIndex LTE ARGUMENTS.Query.RecordCount ;
				local.RowIndex = (local.RowIndex + 1)
				){

				// Create a row for this query record.
				local.Row = local.Sheet.CreateRow(
					JavaCast(
						"int",
						(local.RowIndex + local.RowOffset)
						)
					);

				/*
				// Set the row height.
				local.Row.SetHeightInPoints(
					JavaCast( "float", 14 )
					);
				*/


				// Loop over the columns to create the individual data cells
				// and set the values.
				for (
					local.ColumnIndex = 1 ;
					local.ColumnIndex LTE ArrayLen( local.Columns ) ;
					local.ColumnIndex = (local.ColumnIndex + 1)
					){

					// Create a cell for this query cell.
					local.Cell = local.Row.CreateCell(
						JavaCast( "int", (local.ColumnIndex - 1) )
						);

					// Get the generic cell value (short hand).
					local.CellValue = ARGUMENTS.Query[
						local.Columns[ local.ColumnIndex ]
						][ local.RowIndex ];

					// Check to see how we want to set the value. Meaning, what
					// kind of data mapping do we want to apply? Get the data
					// mapping value.
					local.DataMapValue = local.DataMap[ local.Columns[ local.ColumnIndex ] ];

					// Check to see what value type we are working with. I am
					// not sure what the set of values are, so trying to keep
					// it general.
					if (REFindNoCase( "int", local.DataMapValue )){

						local.DataMapCast = "int";

					} else if (REFindNoCase( "long", local.DataMapValue )){

						local.DataMapCast = "long";

					} else if (REFindNoCase( "double|decimal|numeric", local.DataMapValue )){

						local.DataMapCast = "double";

					} else if (REFindNoCase( "float|real|date|time", local.DataMapValue )){

						local.DataMapCast = "float";

					} else if (REFindNoCase( "bit", local.DataMapValue )){

						local.DataMapCast = "boolean";

					} else if (REFindNoCase( "char|text|memo", local.DataMapValue )){

						local.DataMapCast = "string";

					} else if (IsNumeric( local.CellValue )){

						local.DataMapCast = "float";

					} else {

						local.DataMapCast = "string";

					}

					// Set the cell value using the data map casting that we
					// just determined and the value that we previously grabbed
					// (for short hand).
					//
					// NOTE: Only set the cell value if we have a length. This
					// will stop us from improperly attempting to cast NULL values.
					if (Len( local.CellValue )){

						local.Cell.SetCellValue(
							JavaCast(
								local.DataMapCast,
								local.CellValue
								)
							);
					}
					
					// Get a pointer to the proper cell style. Check to see if we
					// are in an alternate row.
					if (local.RowIndex MOD 2){
						// Set standard row style.
						local.Cell.SetCellStyle(
							local.RowStyle
							);
					} else {
						// Set alternate row style.
						local.Cell.SetCellStyle(
							local.AltRowStyle
							);
					}
				}
			}
			
			// Return out.
			return;
		</cfscript>
	</cffunction>
	
	<cffunction name="WriteSingleExcel" access="public" returntype="void" output="false" hint="Write the given query to an Excel file.">
		<!--- Define arguments. --->
		<cfargument
			name="FilePath"
			type="string"
			required="true"
			hint="This is the expanded path of the Excel file."
			/>
		<cfargument
			name="Query"
			type="query"
			required="true"
			hint="This is the query from which we will get the data for the Excel file."
			/>
		<cfargument
			name="ColumnList"
			type="string"
			required="false"
			default="#ARGUMENTS.Query.ColumnList#"
			hint="This is list of columns provided in custom-order."
			/>
		<cfargument
			name="ColumnNames"
			type="string"
			required="false"
			default=""
			hint="This the the list of optional header-row column names. If this is not provided, no header row is used."
			/>
		<cfargument
			name="SheetName"
			type="string"
			required="false"
			default="Sheet 1"
			hint="This is the optional name that appears in the first (and only) workbook tab."
			/>
		<cfargument
			name="Delimiters"
			type="string"
			required="false"
			default=","
			hint="The list of delimiters used for the column list and column name arguments."
			/>
		<cfargument
			name="HeaderCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the header row (if a header row is used)."
			/>
		<cfargument
			name="RowCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the non-header rows."
			/>
		<cfargument
			name="AltRowCSS"
			type="string"
			required="false"
			default=""
			hint="Defines the limited CSS available for the alternate non-header rows. This style overwrites parts of the RowCSS."
			/>
		
		<cfscript>
			// Set up local scope.
			var local = StructNew();
			
			// Get a new sheet object.
			local.Sheet = GetNewSheetStruct();
			
			// Set the sheet properties.
			local.Sheet.Query = ARGUMENTS.Query;
			local.Sheet.ColumnList = ARGUMENTS.ColumnList;
			local.Sheet.ColumnNames = ARGUMENTS.ColumnNames;
			local.Sheet.SheetName = ARGUMENTS.SheetName;
			
			// Write this sheet to an Excel file.
			WriteExcel(
				FilePath = ARGUMENTS.FilePath,
				Sheets = local.Sheet,
				Delimiters = ARGUMENTS.Delimiters,
				HeaderCSS = ARGUMENTS.HeaderCSS,
				RowCSS = ARGUMENTS.RowCSS,
				AltRowCSS = ARGUMENTS.AltRowCSS
				);
			
			// Return out.
			return;
		</cfscript>
	</cffunction>
	
	<cffunction name="getSheetColumnNames" access="private" hint="gets or derives the column names for the sheet">
		<cfargument name="Sheet" type="any" required="true"/>
		<cfargument name="HasHeaderRow" type="boolean" required="true"/>
		<cfscript>
			local = structNew();
			local.names = ArrayNew(1);
			local.columnName = "";
			local.row = Sheet.GetRow(JavaCast( "int", 0 ));
			local.columnCount = local.Row.GetLastCellNum();
			
			for(local.columnIndex = 0; local.columnIndex LT local.columnCount; local.columnIndex=local.columnIndex+1) {
				local.columnName = "column#local.columnIndex+1#";
				
				if(arguments.HasHeaderRow) {
					try {
						local.columnName = local.row.GetCell(JavaCast( "int", local.columnIndex )).GetStringCellValue();
					} catch(Any exception){
						//whoopsie. we'll use the originally derived column name instead
					}
				}
				
				ArrayAppend(local.names,local.columnName);
			}
			
			return local.names;
		</cfscript>
	</cffunction>
	
	<cffunction name="debug">
		<cfdump var="#ARGUMENTS#" />
		
		<cfabort />
	</cffunction>
</cfcomponent>