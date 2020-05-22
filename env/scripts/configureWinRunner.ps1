[CmdletBinding()]
param (
    [Parameter()][string]$githubToken,
    [Parameter()][string]$githubOrganisationName
)

mkdir actions-runner; cd actions-runner

Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.262.1/actions-runner-win-x64-2.262.1.zip -OutFile actions-runner-win-x64-2.262.1.zip

Add-Type -AssemblyName System.IO.Compression.FileSystem ; [System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.262.1.zip", "$PWD")

./config.cmd --url "https://github.com/$githubOrganisationName" --token $githubToken --runasservice --unattended --replace

Start-Service "actions.runner.*"
