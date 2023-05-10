function New-ADOPSVariableGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$VariableGroupName,

        [Parameter(Mandatory, ParameterSetName = 'VariableSingle')]
        [string]$VariableName,

        [Parameter(Mandatory, ParameterSetName = 'VariableSingle')]
        [string]$VariableValue,

        [Parameter(Mandatory)]
        [string]$Project,

        [Parameter(ParameterSetName = 'VariableSingle')]
        [switch]$IsSecret,

        [Parameter(Mandatory, ParameterSetName = 'VariableHashtable')]
        [ValidateScript(
            {
                $_ | ForEach-Object { $_.Keys -Contains 'Name' -and $_.Keys -Contains 'IsSecret' -and $_.Keys -Contains 'Value' -and $_.Keys.count -eq 3 }
            },
            ErrorMessage = 'The hashtable must contain the following keys: Name, IsSecret, Value')]
        [hashtable[]]$VariableHashtable,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [string]$Organization
    )

    # If user didn't specify org, get it from saved context
    if ([string]::IsNullOrEmpty($Organization)) {
        $Organization = GetADOPSDefaultOrganization
    }

    $ProjectInfo = Get-ADOPSProject -Organization $Organization -Project $Project

    $URI = "https://dev.azure.com/${Organization}/_apis/distributedtask/variablegroups?api-version=7.1-preview.2"
    $method = 'POST'

    if ($VariableName) {
        $Body = @{
            Name                           = $VariableGroupName
            Description                    = $Description
            Type                           = 'Vsts'
            variableGroupProjectReferences = @(@{
                    Name             = $VariableGroupName
                    Description      = $Description
                    projectReference = @{
                        Id = $ProjectInfo.Id
                    }
                })
            variables                      = @{
                $VariableName = @{
                    isSecret = $IsSecret.IsPresent
                    value    = $VariableValue
                }
            }
        } | ConvertTo-Json -Depth 10
    }
    else {

        $Variables = @{}
        foreach ($Hashtable in $VariableHashtable) {
            $Variables.Add(
                $Hashtable.Name, @{
                    isSecret = $Hashtable.IsSecret
                    value    = $Hashtable.Value
                }
            )
        }

        $Body = @{
            Name                           = $VariableGroupName
            Description                    = $Description
            Type                           = 'Vsts'
            variableGroupProjectReferences = @(@{
                    Name             = $VariableGroupName
                    Description      = $Description
                    projectReference = @{
                        Id = $($ProjectInfo.Id)
                    }
                })
            variables                      = $Variables
        } | ConvertTo-Json -Depth 10
    }

    InvokeADOPSRestMethod -Uri $Uri -Method $Method -Body $Body -Organization $Organization
}
