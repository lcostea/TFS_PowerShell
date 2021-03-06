Param(
#BuildCreation parameters
	[Parameter(Mandatory=$true)][string]$TeamProject,
	[Parameter(Mandatory=$true)][string]$BuildName,
	[Parameter(Mandatory=$false)][string]$BuildArguments,
    [Parameter(Mandatory=$true)][string]$BuildType,
    [Parameter(Mandatory=$true)][string[]]$Solutions,
    [Parameter(Mandatory=$true)][string[]]$Map
)

#replace with your tfs server
$serverName = "http://tfs"

[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Client")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Common")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Client")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.VersionControl.Client")
[void][System.Reflection.Assembly]::LoadWithPartialName("Microsoft.TeamFoundation.Build.Workflow")




$tfs = [Microsoft.TeamFoundation.Client.TeamFoundationServerFactory]::GetServer($serverName) 
$versionControl = $tfs.GetService([Microsoft.TeamFoundation.VersionControl.Client.VersionControlServer]) 
$buildserver = $tfs.GetService([Microsoft.TeamFoundation.Build.Client.IBuildServer])



$buildDefinition = $buildserver.CreateBuildDefinition($TeamProject)
$buildDefinition.Name = $BuildName
$buildDefinition.Description = "Created by PowerShell script"

#Continuous integration
$buildDefinition.ContinuousIntegrationType = [Microsoft.TeamFoundation.Build.Client.ContinuousIntegrationType]::$BuildType

#Build Controller
$buildDefinition.BuildController = $buildserver.GetBuildController("build - Controller"); 
	
#Drop Location - replace with your own
$buildDefinition.DefaultDropLocation = ""

#Workspace

$buildDefinition.Workspace.Mappings.Clear()

foreach ($mapElement in $Map)
{
    $mapElementReplaced = $mapElement -replace "\\", "/"
    $mapSourceControl = '$/' + $mapElementReplaced
    $mapAgentFolder = '$(SourceDir)\' + $mapElement
    $buildDefinition.Workspace.AddMapping($mapSourceControl, $mapAgentFolder, [Microsoft.TeamFoundation.Build.Client.WorkspaceMappingType]::Map) 
}



$process = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::DeserializeProcessParameters($buildDefinition.ProcessParameters)

#Build Solution

if($SlnName -eq "")
{
    $SlnName = $TeamProject
}

$buildSettings = New-Object -TypeName Microsoft.TeamFoundation.Build.Workflow.Activities.BuildSettings

$projectsToBuild = New-Object "Microsoft.TeamFoundation.Build.Workflow.Activities.StringList"

foreach ($sln in $Solutions)
{
    $projectsToBuild.Add('$/' + $sln)
}

$buildSettings.ProjectsToBuild = $projectsToBuild

$process.Add("BuildSettings", $buildSettings)

$process.Add("MSBuildArguments", $BuildArguments)

$process.Add("CreateWorkItem", $false)


$buildDefinition.ProcessParameters = [Microsoft.TeamFoundation.Build.Workflow.WorkflowHelpers]::SerializeProcessParameters($process)


$defaultTemplates = $buildServer.QueryProcessTemplates($TeamProject)| 
		Where-Object { $_.TemplateType -eq [Microsoft.TeamFoundation.Build.Client.ProcessTemplateType]::Default}

$buildDefinition.Process = $defaultTemplates[0]


$buildDefinition.Save()
Write-Host "Created the Build: " + $BuildName -foregroundcolor "green"