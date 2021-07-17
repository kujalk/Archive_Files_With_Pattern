<#
Purpose - To create a Zip folder from specified location
Date - 16/7/2021
Version - 1.0
Developer - K.Janarthanan
#>

[CmdletBinding()]
param (
    [String]
    $ConfigFile="$PSScriptRoot\Config.json"
)

function Write-Log
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Validateset("INFO","ERR","WARN")]
        [string]$Type="INFO"
    )

    $DateTime = Get-Date -Format "MM-dd-yyyy HH:mm:ss"
    $FinalMessage = "[{0}]::[{1}]::[{2}]" -f $DateTime,$Type,$Message

    if($Type -eq "ERR")
    {
        Write-Host "$FinalMessage" -ForegroundColor Red
    }
    else 
    {
        Write-Host "$FinalMessage" -ForegroundColor Green
    }
}

try 
{
   
    Write-Log "Script Started"

    $Config = Get-Content -Path $ConfigFile -ErrorAction Stop | ConvertFrom-Json

    $RootFolder = $Config.RootArchiveFolder
    $FullArchive = $RootFolder + ".zip"

    if($RootFolder)
    {
        
        if(Test-Path -Path $RootFolder)
        {
            throw "RootArchiveFolder is already existing. Please delete it to create a fresh archive"
        }

        if(Test-Path -Path $FullArchive -PathType Leaf)
        {
            throw "Already zip is available. Delete it and re-run the script"
        }

        #Creating Folder
        
        foreach($Entry in $Config.Archive)
        {
            Write-Log "Going to create Folder $($Entry.Destination)"
            New-Item -Path "$RootFolder/$($Entry.Destination)" -ItemType Directory -Force -EA Stop | Out-Null
            Write-Log "Created the Folder"
        }

        #Copying Item
        foreach($Entry in $Config.Archive)
        {
            Write-Log "Checking Folder $($Entry.Source)"
            
            $LastElement = $Entry.Source.split("\")[-1]
            $ExceptLast = $Entry.Source.split("\")[0..($Entry.Source.split("\").Count-2)] -join "\"
        
            Write-Log "Copying item from Folder $ExceptLast with pattern $LastElement"
            Copy-Item -Path "$ExceptLast\*" -Filter $LastElement -Destination "$RootFolder\$($Entry.Destination)" -Recurse -Force -EA Stop
            
        }

        Write-Log "Going to Compress folder"
        Compress-Archive -Path "$RootFolder\*" -DestinationPath "$RootFolder.zip" -Force -EA Stop
        Write-Log "Created archive with the name of $RootFolder.zip"

    }
    else 
    {
        throw "RootArchiveFolder is mandatory parameter"    
    }

}
catch 
{
    write-Log "$_" -Type ERR    
}
