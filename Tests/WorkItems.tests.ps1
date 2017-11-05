﻿$userName = $env:VSTSPoshUserName
$token = $env:VSTSPoshToken
$account = $env:VSTSPoshAccount

function New-ProjectName
{
    [Guid]::NewGuid().ToString().Replace('-', '').Substring(10)
}

$moduleRoot = Split-Path -Path $PSScriptRoot -Parent
$modulePath = Join-Path -Path $moduleRoot -ChildPath 'VSTS.psm1'
Import-Module -Name $modulePath -Force

Describe 'Code' -Tags 'Unit' {
    InModuleScope -ModuleName VSTS {
        # All unit tests run in VSTS module scope

    }
}

Describe 'Work items' -Tags 'Integration' {
    BeforeAll {
        $projectName = New-ProjectName
        $session = New-VSTSSession -AccountName $account -User $userName -Token $token
        Write-Verbose -Verbose -Message ('Creating VSTS test project {0}' -f $projectName)
        New-VSTSProject -Session $session -Name $projectName
        Wait-VSTSProject -Session $session -Name $projectName -Exists -State 'WellFormed' -Attempts 50 -RetryIntervalSec 5
    }

    Context "Work item doesn't exist" {
        It 'Should create a new work item' {
            { $script:workItem = New-VstsWorkItem `
                    -Session $session `
                    -WorkItemType 'Task' `
                    -Project $projectName `
                    -PropertyHashtable @{
                    'System.Title'       = 'This is a test work item'
                    'System.Description' = 'Test'
                } `
                    -Verbose } | Should Not Throw
            $script:workItem.Fields.'System.Title' | Should Be 'This is a test work item'
            $script:workItem.Fields.'System.Description' | Should Be 'Test'
        }

        It 'Should find a work item' {
            { $script:createdWorkItem = New-VstsWorkItem `
                    -Session $session `
                    -WorkItemType 'Task' `
                    -Project $projectName `
                    -PropertyHashtable @{
                    'System.Title'       = 'This is a work item I want to find'
                    'System.Description' = 'Test'
                } `
                    -Verbose } | Should Not Throw
            { $script:foundWorkItem = Get-VstsWorkItem `
                    -Session $session `
                    -Id $script:createdWorkItem.Id `
                    -Verbose } | Should Not Throw
            $script:foundWorkItem.Fields.'System.Title' | Should Be 'This is a work item I want to find'
            }
    }

    AfterAll {
        Write-Verbose -Verbose -Message ('Deleting VSTS test project {0}' -f $projectName)
        Remove-VSTSProject -Session $session -Name $projectName
    }
}


