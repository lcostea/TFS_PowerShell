# TFS_PowerShell
a series of PowerShell scripts to help you work with TFS (source control, builds, work items etc)

Usage of BuildCreator.ps1:

[array]$MapItems = @("Path\ToYourFirstProject","Path\YourLibrary")

[array]$SolutionItems = @("Path/ToYourFirstSln/YourProject1.sln","Path/ToYourSecondSln/YourProject1.sln")

$TeamProject = "Your-Team-Project-Name"

$BuildName = "Sample Build"

& '.\BuildCreator.ps1' -TeamProject:$TeamProject -BuildName:$BuildName -BuildType:"Individual" -Solutions:$SolutionItems -Map:$MapItems
