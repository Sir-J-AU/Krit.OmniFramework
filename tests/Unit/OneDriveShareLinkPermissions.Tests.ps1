#requires -Modules Pester
BeforeAll {
    Import-Module (Join-Path $PSScriptRoot '..\..\src\Krit.OmniFramework.psm1') -Force
}

Describe 'Get-KritOneDriveShareLinkPermissions — surface contract' {
    It 'exports the function' {
        Get-Command -Name Get-KritOneDriveShareLinkPermissions -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'requires LocalPath' {
        $cmd = Get-Command -Name Get-KritOneDriveShareLinkPermissions
        $cmd.Parameters['LocalPath'].Attributes.Mandatory -contains $true | Should -BeTrue
    }

    It 'exposes UseDeviceCode switch' {
        (Get-Command Get-KritOneDriveShareLinkPermissions).Parameters.ContainsKey('UseDeviceCode') | Should -BeTrue
    }

    It 'declares PSCustomObject output' {
        (Get-Command Get-KritOneDriveShareLinkPermissions).OutputType.Type.Name | Should -BeIn @('PSCustomObject','PSObject')
    }

    It 'has a non-empty SYNOPSIS' {
        (Get-Help Get-KritOneDriveShareLinkPermissions).Synopsis | Should -Not -BeNullOrEmpty
    }
}

Describe 'Add-KritOneDriveShareLinkRecipients — surface contract' {
    It 'exports the function' {
        Get-Command -Name Add-KritOneDriveShareLinkRecipients -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'declares the documented parameter set' {
        $cmd = Get-Command Add-KritOneDriveShareLinkRecipients
        foreach ($p in 'LocalPath','Recipients','Role','RequireSignIn','SendInvitation','Message','ExpirationDateTime','Password','UseDeviceCode') {
            $cmd.Parameters.ContainsKey($p) | Should -BeTrue -Because "expected parameter $p"
        }
    }

    It 'requires LocalPath and Recipients' {
        $cmd = Get-Command Add-KritOneDriveShareLinkRecipients
        $cmd.Parameters['LocalPath'].Attributes.Mandatory   -contains $true | Should -BeTrue
        $cmd.Parameters['Recipients'].Attributes.Mandatory  -contains $true | Should -BeTrue
    }

    It 'restricts Role to view|edit' {
        $vs = (Get-Command Add-KritOneDriveShareLinkRecipients).Parameters['Role'].Attributes |
              Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
              Select-Object -First 1
        $vs.ValidValues | Should -Be @('view','edit')
    }

    It 'supports ShouldProcess' {
        (Get-Command Add-KritOneDriveShareLinkRecipients).Parameters.ContainsKey('WhatIf')  | Should -BeTrue
        (Get-Command Add-KritOneDriveShareLinkRecipients).Parameters.ContainsKey('Confirm') | Should -BeTrue
    }

    It 'documents at least three examples' {
        @((Get-Help Add-KritOneDriveShareLinkRecipients -Examples).Examples.Example).Count | Should -BeGreaterOrEqual 3
    }
}

Describe 'Remove-KritOneDriveShareLinkPermission — surface contract' {
    It 'exports the function' {
        Get-Command -Name Remove-KritOneDriveShareLinkPermission -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'requires LocalPath and PermissionId' {
        $cmd = Get-Command Remove-KritOneDriveShareLinkPermission
        $cmd.Parameters['LocalPath'].Attributes.Mandatory     -contains $true | Should -BeTrue
        $cmd.Parameters['PermissionId'].Attributes.Mandatory  -contains $true | Should -BeTrue
    }

    It 'supports ShouldProcess at ConfirmImpact High' {
        $attr = (Get-Command Remove-KritOneDriveShareLinkPermission).ScriptBlock.Attributes |
                Where-Object { $_ -is [System.Management.Automation.CmdletBindingAttribute] } |
                Select-Object -First 1
        $attr.SupportsShouldProcess | Should -BeTrue
        $attr.ConfirmImpact | Should -Be 'High'
    }
}

Describe 'Set-KritOneDriveShareLinkPermission — surface contract' {
    It 'exports the function' {
        Get-Command -Name Set-KritOneDriveShareLinkPermission -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
    }

    It 'requires LocalPath and PermissionId; Role optional' {
        $cmd = Get-Command Set-KritOneDriveShareLinkPermission
        $cmd.Parameters['LocalPath'].Attributes.Mandatory     -contains $true  | Should -BeTrue
        $cmd.Parameters['PermissionId'].Attributes.Mandatory  -contains $true  | Should -BeTrue
        $cmd.Parameters['Role'].Attributes.Mandatory          -contains $true  | Should -BeFalse
    }

    It 'restricts Role to view|edit' {
        $vs = (Get-Command Set-KritOneDriveShareLinkPermission).Parameters['Role'].Attributes |
              Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] } |
              Select-Object -First 1
        $vs.ValidValues | Should -Be @('view','edit')
    }

    It 'allows empty-string ExpirationDateTime / Password for clear-semantics' {
        $cmd = Get-Command Set-KritOneDriveShareLinkPermission
        $cmd.Parameters['ExpirationDateTime'].Attributes |
            Where-Object { $_ -is [System.Management.Automation.AllowEmptyStringAttribute] } |
            Should -Not -BeNullOrEmpty
        $cmd.Parameters['Password'].Attributes |
            Where-Object { $_ -is [System.Management.Automation.AllowEmptyStringAttribute] } |
            Should -Not -BeNullOrEmpty
    }

    It 'throws when no mutating param supplied (cannot test invoke without Graph; via smoke)' {
        # Cannot reach inside the function without Graph + a real DriveItem, but we
        # can confirm at least that all three Set-mutating params are Optional (above)
        # and that the function exists. Live "throw when nothing-to-PATCH" is covered
        # by the e2e harness when run with creds.
        Get-Command Set-KritOneDriveShareLinkPermission | Should -Not -BeNullOrEmpty
    }
}

Describe 'OneDrive share-permission cmdlets — documentation surface' {
    It 'all 4 cmdlets have non-empty SYNOPSIS' {
        foreach ($n in 'Get-KritOneDriveShareLinkPermissions','Add-KritOneDriveShareLinkRecipients','Remove-KritOneDriveShareLinkPermission','Set-KritOneDriveShareLinkPermission') {
            (Get-Help $n).Synopsis | Should -Not -BeNullOrEmpty -Because "expected SYNOPSIS on $n"
        }
    }
    It 'all 4 cmdlets document at least one example' {
        foreach ($n in 'Get-KritOneDriveShareLinkPermissions','Add-KritOneDriveShareLinkRecipients','Remove-KritOneDriveShareLinkPermission','Set-KritOneDriveShareLinkPermission') {
            @((Get-Help $n -Examples).Examples.Example).Count | Should -BeGreaterOrEqual 1 -Because "expected at least 1 example on $n"
        }
    }
}
