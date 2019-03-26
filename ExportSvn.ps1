<#

.SYNOPSIS
Exports an SVN repository to a Git repository.
 
.DESCRIPTION
This script will cleanly export an SVN repository to a local Git repository and, optionally, push the new Git repository to a remote master Git repository.  

This script achieves a clean clone of the SVN repository by mapping the SVN users to Git users so that the Git author information is correct and gets rid of the git-svn-id.  Additionally, this script cleans up the weird remote branches that the clone command creates from SVN tags and makes real Git tags from them.

This script was adapted from chapter 9.2 'Git and Other Systems - Migrating to Git' of the book, 'Pro Git', written by 'Scott Chacon'

http://git-scm.com/book/en/Git-and-Other-Systems-Migrating-to-Git

.PARAMETER SvnRepositoryUrl
The URL of the SVN repository that is to be cloned.

.PARAMETER RepositoryUserName
The user name that will added to the local Git repository configuration.  By convention this should be your first and last name.

.PARAMETER RepositoryUserEmail
The user email that will be added to the local Git repository configuration.

.PARAMETER AuthorsFilePath
The path of the authors file.  The authors file contains the mappings between SVN users and Git users.

Example Mapping: 
jdoe = John Doe <jdoe@nunya.com>

Each mapping should be on an individual line.

.PARAMETER LocalRepositoryPath
The path to the directory where the SVN repository will be cloned.  If the directory does not exist it will be created.

.PARAMETER TrunkDirectory
If the SVN repository follows the traditional trunk/tags/branch structure then this should be left as null.  Otherwise, this should be the path to the trunk directory (relative to the repository URL).

.PARAMETER TagsDirectory
If the SVN repository follows the traditional trunk/tags/branch structure then this should be left as null.  Otherwise, this should be the path to the tags directory (relative to the repository URL).

.PARAMETER BranchesDirectory
If the SVN repository follows the traditional trunk/tags/branch structure then this should be left as null.  Otherwise, this should be the path to the branches directory (relative to the repository URL).

.PARAMETER GitIgnores
An array of directories and files to be ignored.  The contents of the array will be written to the .gitignore file.

The default ignores include:
bin/
obj/
*.suo
*.csproj.user

.PARAMETER RemoteOriginUrl
The URL of the remote Git repository that will be added to the cloned repository as the remote origin.  This is optional.

.PARAMETER PushToRemoteOrigin
If true, the local repository will be pushed to the remote origin specified in the 'RemoteOriginUrl' argument when the clone is complete.

.PARAMETER OriginRepositoryUsername
The username used to authenticate against the remote origin if pushing to a remote origin.

.EXAMPLE
.\ImportSvn.ps1 `
    -SvnRepositoryUrl "https://nunya.com/svn/demoproject" `
    -RepositoryUserName "jdoe" `
    -RepositoryUserEmail "jdoe@nunya.com" `
    -AuthorsFilePath D:\Authors.txt `
    -LocalRepositoryPath D:\DemoProject

This will clone the SVN repository at https://nunya.com/svn/demoproject to the local directory, D:\DemoProject.  A .gitignore file will be created with the default values and the file will be committed to the local Git repository using the RepositoryUserName and RepositoryUserEmail arguments for the author information.  This example assumes the SVN repository is using the traditional trunk\tags\branch structure:

/svn/DemoProject
    /Trunk
    /Tags
    /Branches

.EXAMPLE
.\ImportSvn.ps1 `
    -SvnRepositoryUrl "https://nunya.com/svn/demoproject" `
    -RepositoryUserName "jdoe" `
    -RepositoryUserEmail "jdoe@nunya.com" `
    -AuthorsFilePath D:\Authors.txt `
    -LocalRepositoryPath D:\DemoProject `
    -GitIgnores $null

This will clone the SVN repository at https://nunya.com/svn/demoproject to the local directory, D:\DemoProject.  A .gitignore file will not be created for the Git repository.  This example assumes the SVN repository is using the traditional trunk\tags\branch structure:

/svn/DemoProject
    /Trunk
    /Tags
    /Branches

.EXAMPLE
.\ImportSvn.ps1 `
    -SvnRepositoryUrl "https://nunya.com/svn/demoproject" `
    -RepositoryUserName "jdoe" `
    -RepositoryUserEmail "jdoe@nunya.com" `
    -AuthorsFilePath D:\Authors.txt `
    -LocalRepositoryPath D:\DemoProject `
    -RemoteOriginUrl "https://git.nunya.com/demoproject.git"

This will clone the SVN repository at https://nunya.com/svn/demoproject to the local directory, D:\DemoProject.  A .gitignore file will be created with the default values and the file will be committed to the local Git repository using the RepositoryUserName and RepositoryUserEmail arguments for the author information.  The RemoteOriginUrl will be added to the git repository as the remote origin.  This example assumes the SVN repository is using the traditional trunk\tags\branch structure:

/svn/DemoProject
    /Trunk
    /Tags
    /Branches

.EXAMPLE
.\ImportSvn.ps1 `
    -SvnRepositoryUrl "http://nunya.com/svn/" `
    -RepositoryUserName "jdoe" `
    -RepositoryUserEmail "jdoe@nunya.com" `
    -AuthorsFilePath D:\Authors.txt `
    -LocalRepositoryPath D:\SvnClone\ClonedRepository `
    -RemoteOriginUrl "https://git.nunya.com/demoproject.git"
    -PushToRemoteOrigin $true

This will clone the SVN repository at https://nunya.com/svn/demoproject to the local directory, D:\DemoProject.  A .gitignore file will be created with the default values and the file will be committed to the local Git repository using the RepositoryUserName and RepositoryUserEmail arguments for the author information.  The RemoteOriginUrl will be added to the git repository as the remote origin.  The Git repository will be pushed to the remote origin after the clone has operation has been completed.  This example assumes the SVN repository is using the traditional trunk\tags\branch structure:

/svn/DemoProject
    /Trunk
    /Tags
    /Branches
 
.EXAMPLE
.\ImportSvn.ps1 `
    -SvnRepositoryUrl "http://nunya.com/svn/" `
    -RepositoryUserName "jdoe" `
    -RepositoryUserEmail "jdoe@nunya.com" `
    -AuthorsFilePath D:\Authors.txt `
    -LocalRepositoryPath D:\SvnClone\ClonedRepository `
    -TrunkDirectory "trunk/demoproject/" `
    -TagsDirectory "tags/demoproject/"
 
This will clone the SVN repository at https://nunya.com/svn to the local directory, D:\DemoProject.  A .gitignore file will be created with the default values and the file will be committed to the local Git repository using the RepositoryUserName and RepositoryUserEmail arguments for the author information.  The RemoteOriginUrl will be added to the git repository as the remote origin.  This example assumes the SVN repository is using a non-traditional structure and that we do not care about importing the branches (maybe we know there are no branches):

/svn
    /Trunk/DemoProject
    /Tags/DemoProject

#>

[CmdletBinding()]
param (

[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[String]
$SvnRepositoryUrl,

[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[String]
$RepositoryUserName,

[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[String]
$RepositoryUserEmail,

[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[String]
$AuthorsFilePath,

[Parameter(Mandatory)]
[ValidateNotNullOrEmpty()]
[String]
$LocalRepositoryPath,

[String]
$TrunkDirectory = $null,

[String]
$TagsDirectory = $null,

[String]
$BranchesDirectory = $null,

[String[]]
$GitIgnores = @("bin/", "obj/", "*.suo", "*.csproj.user"),

[String]
$RemoteOriginUrl = $null,

[Switch]
$PushToRemoteOrigin,

[String]
$OriginRepositoryUsername)

# Store the user's current directory
Push-Location

try {
    # If the local directory does not exist then create it.
    # Send the output of 'New-Item' to null so that the result is not written to the console window.
    if ((Test-Path $LocalRepositoryPath) -eq $false) {
        Write-Verbose "The local directory, '$LocalRepositoryPath' does not exist.  Creating the local directory."
        New-Item -ItemType Directory -Path $LocalRepositoryPath > $null
    }

    # Move to the local working directory that the SVN repository will be cloned to.
    Set-Location $LocalRepositoryPath

    # Create the repository structure argument that will be passed to the 'git svn clone' command.
    $repositoryStructure = ""
    if (![String]::IsNullOrWhiteSpace($TrunkDirectory)) {
        $repositoryStructure = "-T $TrunkDirectory"
    }
    Write-Debug "Repository structure after 'TrunkDirectory' test: $repositoryStructure"
    if (![String]::IsNullOrWhiteSpace($TagsDirectory)) {
        $repositoryStructure = "$repositoryStructure -t $TagsDirectory"
    }
    Write-Debug "Repository structure after 'TagsDirectory' test: $repositoryStructure"
    if (![String]::IsNullOrWhiteSpace($BranchesDirectory)) {
        $repositoryStructure = "$repositoryStructure -b $BranchesDirectory"
    }
    Write-Debug "Repository structure after 'BranchesDirectory' test: $repositoryStructure"

    # If the 'TrunkDirectory', 'TagsDirectory' or 'BranchesDirectory' arguments were not provided then assume the repository 
    # structure follows the traditional trunk\tags\branches structure.
    if ([String]::IsNullOrWhiteSpace($repositoryStructure)) {
        $repositoryStructure = "-s"
    }
    Write-Debug "Repository structure after standard structure test: $repositoryStructure"

    # Clone the SVN repository to a Git repository in the local working directory.
    Write-Verbose "Cloning the SVN repository."
    $command = "git svn clone $SvnRepositoryUrl $LocalRepositoryPath $repositoryStructure --authors-file=$AuthorsFilePath --no-metadata"
    Write-Debug "Command: $command"
    Invoke-Expression $command
    Write-Verbose "The SVN repository has been cloned to $LocalRepositoryPath."

    # Now we need to clean up the weird references that the 'git svn' command set up. 
    # First you’ll move the tags so they’re actual tags rather than strange remote branches, and then you’ll 
    # move the rest of the branches so they’re local.

    # Get all 'tag' remote references in the Git repository.
    $refs = (git for-each-ref refs/remotes/tags)

    # Loop over each reference and create a tag for each one and then delete the branch.
    Write-Verbose "Fixing the repository tags."
    foreach ($ref in $refs) {
        $tagName = $ref.Split("/")[3]

        Write-Verbose "Repository tag, '$tagName' has been created."
        $command = "git tag $tagName tags/$tagName"
        Write-Debug "Command: $command"
        Invoke-Expression $command

        Write-Verbose "Repository branch, '$tagName' has been removed."
        $command = "git branch -r -d tags/$tagName"
        Write-Debug "Command: $command"
        Invoke-Expression $command
    }
    Write-Verbose "All tags have been fixed."

    # Get all the 'branch' remote references in the Git repository.
    $refs = (git for-each-ref refs/remotes)

    # Loop over each remote reference and create a proper branch and then delete the original.
    Write-Verbose "Fixing the repository branches."
    foreach ($ref in $refs) {
        $branchName = $ref.Split("/")[2]

        # Only create a branch if it is not named trunk.
        # We do not want to end up with a master branch and trunk branch that are exactly the same.
        if ($branchName -ne 'trunk') {
            Write-Verbose "Proper repository branch, '$branchName', has been created."
            $command = "git branch $branchName refs/remotes/$branchName"
            Write-Debug "Command: $command"
            Invoke-Expression $command
        }

        Write-Verbose "Weird '$branchName' branch created during the clone has been removed."
        $command = "git branch -r -d $branchName"
        Write-Debug "Command: $command"
        Invoke-Expression $command
    }
    Write-Verbose "All branches have been fixed."

    # Add the user name to the local repository configuration.
    Write-Verbose "Adding the user name, '$RepositoryUserName', to the repositories local configuration."
    $command = "git config --local user.name ""$RepositoryUserName"""
    Write-Debug "Command: $command"
    Invoke-Expression $command

    # Add the user email to the local repository configuration.
    Write-Verbose "Adding the user email address, 'RepositoryUserEmail', to the repositories local configuration."
    $command = "git config --local user.email ""$RepositoryUserEmail"""
    Write-Debug "Command: $command"
    Invoke-Expression $command

    # Add the default ignored directories and files if any were provided and commit the .gitignore file to the repository.
    if ($GitIgnores.Count -gt 0) {
        foreach ($ignore in $GitIgnores) {
            Write-Verbose "Adding '$ignore' to the .gitignore file."
            Add-Content .\.gitignore $ignore
        }

        Write-Verbose "Committing the .gitignore file to the local repository."
        $command = "git add .gitignore"
        Write-Debug "Command: $command"
        Invoke-Expression $command

        $command = "git commit .gitignore -m ""Add .gitignore file"""
        Write-Debug "Command: $command"
        Invoke-Expression $command
    }

    # If the 'RemoteOriginUrl' is not null, empty or white space then add it to the cloned repository as the remote origin.
    if (![String]::IsNullOrWhiteSpace($RemoteOriginUrl)) {
        
        # Add the remote Git server to the local Git repository.
        Write-Verbose "Adding '$RemoteOriginUrl' as the remote origin to the newly cloned repository."
        $command = "git remote add origin $RemoteOriginUrl"
        Write-Debug "Command: $command"
        Invoke-Expression $command
    }

    # If the 'RemoteOriginUrl' is not null, empty or white space and the 'PushToRemoteOrigin' switch is true then push
    # the cloned repository and its tags to the remote repository.
    if (![String]::IsNullOrWhiteSpace($RemoteOriginUrl) -and $PushToRemoteOrigin -eq $true) {
    
        # Push the new Git repository to the remote master Git server.
        Write-Verbose "Pushing the repository to the remote origin."
        $command = "git push origin -u --all"
        Write-Debug "Command: $command"
        Invoke-Expression $command

        # Push the new Git repository's tags to the remote master Git server.
        Write-Verbose "Pushing the repository's tags to the remote origin."
        $command = "git push origin -u --tags"
        Write-Debug "Command: $command"
        Invoke-Expression $command
    }
}
finally {
    # Return to the user's original directory.
    Pop-Location
}
