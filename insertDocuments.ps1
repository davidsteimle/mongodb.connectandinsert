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
#>

# Add a requirement for mongosh

[CmdletBinding()]
param(
    [string]$database,
    [string]$collection,
    [string]$user,
    [string]$password,
    [string]$uri,
    [string]$documents
)

# Clean-up URI
if($uri[-1] -eq '/'){
    $uri = $uri -replace "/$",''
}

# Create a generic list of supplied data.
$insertMany = New-Object 'System.Collections.Generic.List[psobject]'

# Sample doc for early testing. Change to param.
# $documents = @(
#     [pscustomobject]@{
#         title = 'Hedwig and the Angry Inch'
#         director = 'Mitchell, John Cameron'
#         year = 2001
#         media =  @('bluray')
#         cast = @('Mitchell, John Cameron','Martin, Andrea','Pitt, Michael','SHor, Miriam')
#         language = 'English'
#         criterion = $true
#     },
#     [pscustomobject]@{
#         title = 'Psycho Beach Party'
#         director = 'King, Robert Lee'
#         year = 2000
#         media =  @('bluray')
#         cast = @('Ambrose, Lauren','Gibson, Thomas','Brendon, Nicholas')
#         language = 'English'
#     }
# )

# Add each document to the generic list.
$documents.ForEach({ $insertMany.Add($PSItem) })

# File for javascript -- CHANGE this to a temporary file.
$file = 'connect-and-insert.js'

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
Invoke-Expression $command
