<#
.SYNOPSIS
    Triggers an evaluation of a configuration baseline
.DESCRIPTION
    Triggers an evaluation of a configuration baseline. Use this to launch the eval of the SetupConfig.ini Baseline from your app install.
.PARAMETER BaseLineName
    The name of the configuration baseline to run.
.PARAMETER NameSpace
    WMI Namespace for the WMI class where the DCM is
.PARAMETER Class
    The WMI class for the DCM Baseline
.PARAMETER MethodName
    The name of the method to call on the WMI Object

.NOTES
  Version:          1.1
  Author:           Adam Gross - @AdamGrossTX
  GitHub:           https://www.github.com/AdamGrossTX
  WebSite:          https://www.asquaredozen.com
  Creation Date:    08/08/2019
  Purpose/Change:
    1.0 Initial script development
    1.1 Updated Formatting

 #>

Function Trigger-DCMEvaluation {
    [cmdletbinding()]
    Param(
        [Parameter()]
        [string]$BaseLineName="YourBaselineName",

        [Parameter()]
        [string]$NameSpace = "root\ccm\dcm",

        [Parameter()]
        [string]$ClassName = "SMS_DesiredConfiguration",

        [Parameter()]
        [string]$MethodName = "TriggerEvaluation"
    )

    $Status = @{
        0 = "NonCompliant"
        1 = "Compliant"
        2 = "NotApplicable"
        3 = "Unknown"
        4 = "Error"
        5 = "NotEvaluated"
    }

    Try {
        Write-Host "Triggering DCM Baseline"
        If ($BaselineName) {
            $Filter = "DisplayName='{0}' and PolicyType is null" -f $BaseLineName
        }
        Else {
            $Filter = "PolicyType is null"
        }
        $Baselines = Get-CIMInstance -Namespace $NameSpace -ClassName $ClassName -Filter $Filter

        If ($Baselines) {
            $Results = @()
            ForEach ($Baseline in $Baselines) {
                $ArgsList = @{
                    Name = $BaseLine.Name
                    Version = $Baseline.Version
                    IsMachineTarget = $True
                    IsEnforced = $True
                }
                $BaseLine | Invoke-CimMethod -MethodName $MethodName -Arguments $ArgsList | Out-Null

                $Filter = "DisplayName='{0}'" -f $BaseLine.DisplayName
                [int]$ComplianceStatus = (Get-CIMInstance -Namespace $NameSpace -ClassName $ClassName -Filter $Filter).LastComplianceStatus
                $Results += "{0} : {1}" -f $BaseLine.DisplayName, $Status[$ComplianceStatus]
            }
            Write-Host $Results
            Return $Results
        }
        Else {
            Write-Host "No Baseline Found"
            Return "No Baseline Found"
        }
    }
    Catch {
        Return $_
    }
}