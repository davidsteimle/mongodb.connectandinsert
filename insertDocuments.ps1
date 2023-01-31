<#
.PARAMETER database
The name of your database.
.PARAMETER collection
The name of your collection.
.PARAMETER user
The user with insert rights.
.PARAMETER password
The $user password -- CHANGE this to secure
.PARAMETER uri
The ase URI for your connection.
.PARAMETER documents
An object or objects to insert.
.PARAMETER testrun
Runs the script as normal, but only displays the javascript file and the mongosh command.
#>

# Add a requirement for mongosh

[CmdletBinding()]
param(
    [string]$database,
    [string]$collection,
    [string]$user,
    [string]$password,
    [string]$uri,
    [array]$documents,
    [switch]$testrun
)

Write-Verbose "Is `$documents null? $($null -eq $documents)"

if ($null -eq $documents) {
    Write-Output 'No documents provided.'
    exit 1
}

# Clean-up URI
if($uri[-1] -eq '/'){
    $uri = $uri -replace "/$",''
}

# Create a generic list of supplied data.
$insertMany = New-Object 'System.Collections.Generic.List[psobject]'

# Add each document to the generic list.
$documents.ForEach({ $insertMany.Add($PSItem) })

# File for javascript -- CHANGE this to a temporary file.
$file = New-TemporaryFile
Write-Verbose "Creating temporary file $($file.VersionInfo.FileName)" -Verbose
$jsfilename = $file.VersionInfo.FileName -replace ".tmp$",'.js'
Rename-Item -Path $file -NewName $jsfilename
$file = Get-Item $jsfilename
Write-Verbose "Change that file to a javascript file extension $($file.VersionInfo.FileName)" -Verbose

# Decide on insert methodology.
# DeprecationWarning: Collection.insert() is deprecated. Use insertOne, insertMany, or bulkWrite.
$insert = if($insertMany.Count -gt 1){
    Write-Output 'insertMany'
} else {
    Write-Output 'insertOne'
}

# Build the javascript file.
$javascript = @"
db.$collection.$insert(
$($insertMany | ConvertTo-Json)
)
"@
$javascript | Out-File $file -Force

# Command to execute.
$command = @"
mongosh "$uri/$database" --apiVersion 1 --username $user --password $password --file $file
"@

# Run the command.
if ($testrun) {
    Get-Content $($file.VersionInfo.FileName)
    Write-Host $command
} else {
    # Invoke-Expression $command
}

Remove-Item $file
