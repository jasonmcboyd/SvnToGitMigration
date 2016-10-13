<#

.SYNOPSIS
Gets a unique list of authors from an SVN repository.
 
.DESCRIPTION
Gets a unique list of authors from an SVN repository.

This script was adapted from chapter 9.2 'Git and Other Systems - Migrating to Git' of the book, 'Pro Git', written by 'Scott Chacon'

http://git-scm.com/book/en/Git-and-Other-Systems-Migrating-to-Git

.PARAMETER SvnRepositoryUrl
The URL of the SVN repository.

.EXAMPLE
.\GetSvnRepositoryAuthors.ps1 https://yoursvnhost.com/yoursvnrepository
  
#>
[CmdletBinding()]
param (

[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[String]
$SvnRepositoryUrl)

# Get the log entries from the SVN repository.
Write-Verbose "Getting the SVN log entries."
$logEntries = svn log $SvnRepositoryUrl

# Create a regular expression to capture the lines in the log that contain the author information.
$regex = '^r\d+ \| [^\|]*\| [^\|]*\| \d+ line[s]?$'

# Extract a list of unique author names from the log entries.
Write-Verbose "Extracting the SVN authors from the log entries."
$logEntries `
| Where-Object { $_ -match $regex } `
| ForEach-Object { $_.Split('|')[1].Trim() } `
| Group-Object `
| Sort-Object Name `
| ForEach-Object { $_.Name } 
