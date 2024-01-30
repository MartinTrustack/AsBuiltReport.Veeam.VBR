
function Get-AbrVbrUserRoleAssignment {
    <#
    .SYNOPSIS
        Used by As Built Report to returns Veeam VBR roles assigned to a user or a user group.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.8.5
        Author:         Jonathan Colon
        Twitter:        @jcolonfzenpr
        Github:         rebelinux
        Credits:        Iain Brighton (@iainbrighton) - PScribo module

    .LINK
        https://github.com/AsBuiltReport/AsBuiltReport.Veeam.VBR
    #>
    [CmdletBinding()]
    param (

    )

    begin {
        Write-PscriboMessage "Discovering Veeam VBR Roles information from $System."
    }

    process {
        try {
            Section -Style Heading3 'Roles and Users' {
                Paragraph "The following section provides information about roles assigned to users or groups."
                BlankLine
                $OutObj = @()
                try {
                    $RoleAssignments = Get-VBRUserRoleAssignment
                    foreach ($RoleAssignment in $RoleAssignments) {
                        Write-PscriboMessage "Discovered $($RoleAssignment.Name) Server."
                        $inObj = [ordered] @{
                            'Name' = $RoleAssignment.Name
                            'Type' = $RoleAssignment.Type
                            'Role' = $RoleAssignment.Role
                        }
                        $OutObj += [pscustomobject]$inobj
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "Roles and Users Table: $($_.Exception.Message)"
                }

                if ($HealthCheck.Infrastructure.Settings) {
                    $OutObj | Where-Object { $_.'Name' -eq 'BUILTIN\Administrators'} | Set-Style -Style Warning -Property 'Name'
                }

                $TableParams = @{
                    Name = "Roles and Users - $VeeamBackupServer"
                    List = $false
                    ColumnWidths = 45, 15, 40
                }
                if ($Report.ShowTableCaptions) {
                    $TableParams['Caption'] = "- $($TableParams.Name)"
                }
                $OutObj | Sort-Object -Property 'Name' | Table @TableParams
                if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object {$_.'Name' -eq 'BUILTIN\Administrators'})) {
                    Paragraph "Health Check:" -Bold -Underline
                    BlankLine
                    Paragraph "Security Best Practice:" -Bold
                    BlankLine
                    if ($OutObj | Where-Object { $_.'Name' -eq 'BUILTIN\Administrators' }) {
                        Paragraph {
                            Text "Veeam recommends to give every Veeam admin his own admin account or add their admin account to the appropriate security group within Veeam and to remove the default 'Veeam Backup Administrator' role from local Administrators group, for traceability and easy adding and removal"
                        }
                        BlankLine
                        Paragraph {
                            Text -Bold "Reference:"
                        }
                        BlankLine
                        Paragraph {
                            Text "https://bp.veeam.com/security/Design-and-implementation/Roles_And_Users.html#roles-and-users"
                        }
                        BlankLine
                    }
                }
                try {
                    Section -ExcludeFromTOC -Style NOTOCHeading4 'Roles and Users Settings' {
                        BlankLine
                        $OutObj = @()
                        try {
                            try {$MFAGlobalSetting = [Veeam.Backup.Core.SBackupOptions]::get_GlobalMFA()} catch {Out-Null}
                            try {$AutoTerminateSession = [Veeam.Backup.Core.SBackupOptions]::get_AutomaticallyTerminateSession()} catch {Out-Null}
                            try {$AutoTerminateSessionMin = [Veeam.Backup.Core.SBackupOptions]::get_AutomaticallyTerminateSessionTimeoutMinutes()} catch {Out-Null}
                            try {$UserActionNotification = [Veeam.Backup.Core.SBackupOptions]::get_UserActionNotification()} catch {Out-Null}
                            try {$UserActionRetention = [Veeam.Backup.Core.SBackupOptions]::get_UserActionRetention()} catch {Out-Null}
                            foreach ($RoleAssignment in $RoleAssignments) {
                                Write-PscriboMessage "Discovered Roles and Users Settings."
                                $inObj = [ordered] @{
                                    'Is MFA globally enabled?' = ConvertTo-TextYN $MFAGlobalSetting
                                    'Is auto logoff on inactivity enabled?' = ConvertTo-TextYN $AutoTerminateSession
                                    'Auto logoff on inactivity after' = "$($AutoTerminateSessionMin) minutes"
                                    'Is Four-eye Authorization enabled?' = ConvertTo-TextYN $UserActionNotification
                                    'Auto reject pending approvals after' = "$($UserActionRetention) days"
                                }
                                $OutObj = [pscustomobject]$inobj
                            }
                        }
                        catch {
                            Write-PscriboMessage -IsWarning "Roles and Users Settings Table: $($_.Exception.Message)"
                        }

                        if ($HealthCheck.Infrastructure.Settings) {
                            $OutObj | Where-Object { $_.'Is MFA globally enabled?' -like 'No'} | Set-Style -Style Warning -Property 'Is MFA globally enabled?'
                            foreach ( $OBJ in ($OutObj | Where-Object { $_.'Is MFA globally enabled?' -eq 'No' })) {
                                $OBJ.'Is MFA globally enabled?' = "* " + $OBJ.'Is MFA globally enabled?'
                            }
                            $OutObj | Where-Object { $_.'Is auto logoff on inactivity enabled?' -like 'No'} | Set-Style -Style Warning -Property 'Is auto logoff on inactivity enabled?'
                            foreach ( $OBJ in ($OutObj | Where-Object { $_.'Is auto logoff on inactivity enabled?' -eq 'No' })) {
                                $OBJ.'Is auto logoff on inactivity enabled?' = "** " + $OBJ.'Is auto logoff on inactivity enabled?'
                            }
                            $OutObj | Where-Object { $_.'Is Four-eye Authorization enabled?' -like 'No'} | Set-Style -Style Warning -Property 'Is Four-eye Authorization enabled?'
                            foreach ( $OBJ in ($OutObj | Where-Object { $_.'Is Four-eye Authorization enabled?' -eq 'No' })) {
                                $OBJ.'Is Four-eye Authorization enabled?' = "*** " + $OBJ.'Is Four-eye Authorization enabled?'
                            }
                        }

                        $TableParams = @{
                            Name = "Roles and Users Settings - $VeeamBackupServer"
                            List = $True
                            ColumnWidths = 40, 60
                        }
                        if ($Report.ShowTableCaptions) {
                            $TableParams['Caption'] = "- $($TableParams.Name)"
                        }
                        $OutObj | Table @TableParams
                        if ($HealthCheck.Infrastructure.BestPractice -and ($OutObj | Where-Object { $_.'Is MFA globally enabled?' -eq '* No' -or $_.'Is auto logoff on inactivity enabled?' -eq '** No' -or $_.'Is Four-eye Authorization enabled?' -eq '*** No'})) {
                            Paragraph "Health Check:" -Bold -Underline
                            BlankLine
                            Paragraph "Security Best Practice:" -Bold
                            BlankLine
                            if ($OutObj | Where-Object { $_.'Is MFA globally enabled?' -eq '* No' }) {
                                Paragraph {
                                    Text "* To ensure comprehensive security, it's crucial to implement MFA across all user accounts. By using a combination of different authentication factors like passwords, biometrics, and one-time passcodes, you create layers of security that make it harder for attackers to gain unauthorized access."
                                }
                                BlankLine
                            }
                            if ($OutObj | Where-Object { $_.'Is auto logoff on inactivity enabled?' -eq '** No' }) {
                                Paragraph {
                                    Text "** Limiting the length of inactive sessions can help protect sensitive information and prevent unauthorized account access."
                                }
                                BlankLine
                            }
                            if ($OutObj | Where-Object { $_.'Is Four-eye Authorization enabled?' -eq '*** No' }) {
                                Paragraph {
                                    Text "*** Veeam recommends configuring Four-eye Authorization to be able to protect against accidental deletion of backup and repositories by requiring an approval from another Backup Administrator."
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-PscriboMessage -IsWarning "Roles and Users Settings Section: $($_.Exception.Message)"
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning "Roles and Users Section: $($_.Exception.Message)"
        }
    }
    end {}

}