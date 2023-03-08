# Define a function to get the structure of a SQL table
function Get-SqlTableStructure
{
    <#
.SYNOPSIS
This function retrieves the structure of a specified SQL table.



.DESCRIPTION
This function connects to a specified SQL Server instance and database, and retrieves the structure of a specified table. The structure is returned as a PowerShell custom object.



.PARAMETER TableName
The name of the SQL table to retrieve the structure of.



.PARAMETER ServerName
The name of the SQL Server instance to connect to.



.PARAMETER DatabaseName
The name of the SQL database to connect to.



.EXAMPLE
Get-SqlTableStructure -ServerName "MyServer" -DatabaseName "MyDatabase" -TableName "MyTable"

.EXAMPLE
Get-SqlTableStructure -ServerName "MyServer" -DatabaseName "MyDatabase"
    #>
	
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string]$ServerName,
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[string]$DatabaseName,
		[Parameter(Mandatory = $false, ValueFromPipeline = $true)]
		[string]$TableName
	)
	
	begin
	{
		# Check that the ServerName, DatabaseName, and TableName parameters are not null or empty
		if ([string]::IsNullOrEmpty($ServerName) -or [string]::IsNullOrEmpty($DatabaseName))
		{
			throw "ServerName, and DatabaseName parameters cannot be null or empty."
		}
		if ([string]::IsNullOrEmpty($TableName))
		{
			$Query = @"
Use $DatabaseName; 
SELECT TABLE_CATALOG,TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME,ORDINAL_POSITION,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,CHARACTER_OCTET_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX,NUMERIC_SCALE,DATETIME_PRECISION,CHARACTER_SET_CATALOG,CHARACTER_SET_SCHEMA,CHARACTER_SET_NAME,COLLATION_CATALOG,COLLATION_SCHEMA,COLLATION_NAME,DOMAIN_CATALOG,DOMAIN_SCHEMA,DOMAIN_NAME
FROM INFORMATION_SCHEMA.COLUMNS ORDER BY ORDINAL_POSITION
"@
			Write-Host "No TableName provided. All columns will be returned from the chosen database" -ForegroundColor Cyan
		}
		Else
		{
			$Query = @"
Use $DatabaseName; 
SELECT TABLE_CATALOG,TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME,ORDINAL_POSITION,DATA_TYPE,CHARACTER_MAXIMUM_LENGTH,CHARACTER_OCTET_LENGTH,NUMERIC_PRECISION,NUMERIC_PRECISION_RADIX,NUMERIC_SCALE,DATETIME_PRECISION,CHARACTER_SET_CATALOG,CHARACTER_SET_SCHEMA,CHARACTER_SET_NAME,COLLATION_CATALOG,COLLATION_SCHEMA,COLLATION_NAME,DOMAIN_CATALOG,DOMAIN_SCHEMA,DOMAIN_NAME
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = '$TableName' ORDER BY ORDINAL_POSITION
"@
		}
		
		# Define a query to retrieve the columns and data types for the specified table
		try
		{
			# Connect to the SQL Server instance and database
			$SqlConnection = New-Object System.Data.SqlClient.SqlConnection
			$SqlConnection.ConnectionString = "Server=$ServerName;Database=$DatabaseName;Integrated Security=True"
			$SqlConnection.Open()
		}
		catch
		{
			throw "Error connecting to SQL Server instance: $($_.Exception.Message)"
		}
		
	}
	
	process
	{
		try
		{
			# Execute the query and store the results in a DataTable
			$SqlDataAdapter = New-Object System.Data.SqlClient.SqlDataAdapter($Query, $SqlConnection)
			$DataTable = New-Object System.Data.DataTable
			$SqlDataAdapter.Fill($DataTable) | Out-Null
		}
		catch
		{
			throw "Error querying the SQL Server instance: $($_.Exception.Message)"
		}
		
		try
		{
			# Create an array of PowerShell custom objects for each row returned by the query
			$Structure = foreach ($Row in $DataTable.Rows)
			{
				[pscustomobject]@{
					ServerName   = $ServerName
					TableCatalog = $Row.TABLE_CATALOG
					TableSchema  = $Row.TABLE_SCHEMA
					TableName    = $Row.TABLE_NAME
					ColumnName   = $Row.COLUMN_NAME
					OrdinalPosition = $Row.ORDINAL_POSITION
					DataType	 = $Row.DATA_TYPE
					CharacterMaximumLength = $Row.CHARACTER_MAXIMUM_LENGTH
					CharacterOctetLength = $Row.CHARACTER_OCTET_LENGTH
					NumericPrecision = $Row.NUMERIC_PRECISION
					NumericPrecisionRadix = $Row.NUMERIC_PRECISION_RADIX
					NumericScale = $Row.NUMERIC_SCALE
					DateTimePrecision = $Row.DATETIME_PRECISION
					CharacterSetCatalog = $Row.CHARACTER_SET_CATALOG
					CharacterSetSchema = $Row.CHARACTER_SET_SCHEMA
					CharacterSetName = $Row.CHARACTER_SET_NAME
					CollationCatalog = $Row.COLLATION_CATALOG
					CollationSchema = $Row.COLLATION_SCHEMA
					CollationName = $Row.COLLATION_NAME
					DomainCatalog = $Row.DOMAIN_CATALOG
					DomainSchema = $Row.DOMAIN_SCHEMA
					DomainName   = $Row.DOMAIN_NAME
				}
			}
		}
		Catch
		{
			throw "Error parsing return to SQL Server instance: $($_.Exception.Message)"
		}
		return $Structure
	}
	End
	{
		$SqlConnection.Close()
	}
}

