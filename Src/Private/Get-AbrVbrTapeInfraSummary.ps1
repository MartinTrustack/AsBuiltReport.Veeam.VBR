
function Get-AbrVbrTapeInfraSummary {
    <#
    .SYNOPSIS
    Used by As Built Report to retrieve Veeam VBR Tape Infrastructure Summary.
    .DESCRIPTION
        Documents the configuration of Veeam VBR in Word/HTML/Text formats using PScribo.
    .NOTES
        Version:        0.5.5
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
        Write-PscriboMessage "Discovering Veeam VBR Tape Infrastructure Summary from $System."
    }

    process {
        try {
            $OutObj = @()
            try {
                $TapeServer = Get-VBRTapeServer
                $TapeLibrary = Get-VBRTapeLibrary
                $TapeMediaPool = Get-VBRTapeMediaPool
                $TapeVault = Get-VBRTapeVault
                $TapeDrive = Get-VBRTapeDrive
                $TapeMedium = Get-VBRTapeMedium
                $inObj = [ordered] @{
                    'Tape Servers' = $TapeServer.Count
                    'Tape Library' = $TapeLibrary.Count
                    'Tape MediaPool' = $TapeMediaPool.Count
                    'Tape Vault' = $TapeVault.Count
                    'Tape Drives' = $TapeDrive.Count
                    'Tape Medium' = $TapeMedium.Count
                }
                $OutObj += [pscustomobject]$inobj
            }
            catch {
                Write-PscriboMessage -IsWarning $_.Exception.Message
            }

            $TableParams = @{
                Name = "Tape Infrastructure Inventory - $VeeamBackupServer"
                List = $true
                ColumnWidths = 50, 50
            }
            if ($Report.ShowTableCaptions) {
                $TableParams['Caption'] = "- $($TableParams.Name)"
            }
            try {
                $sampleData = $inObj.GetEnumerator() | Select-Object @{ Name = 'Category';  Expression = {$_.key}},@{ Name = 'Value';  Expression = {$_.value}} | Sort-Object -Property 'Category'

                $exampleChart = New-Chart -Name TapeInfrastructure -Width 600 -Height 400

                $addChartAreaParams = @{
                    Chart = $exampleChart
                    Name  = 'exampleChartArea'
                }
                $exampleChartArea = Add-ChartArea @addChartAreaParams -PassThru

                $addChartSeriesParams = @{
                    Chart             = $exampleChart
                    ChartArea         = $exampleChartArea
                    Name              = 'exampleChartSeries'
                    XField            = 'Category'
                    YField            = 'Value'
                    Palette           = 'Green'
                    ColorPerDataPoint = $true
                }
                $exampleChartSeries = $sampleData | Add-PieChartSeries @addChartSeriesParams -PassThru

                $addChartLegendParams = @{
                    Chart             = $exampleChart
                    Name              = 'Infrastructure'
                    TitleAlignment    = 'Center'
                }
                Add-ChartLegend @addChartLegendParams

                $addChartTitleParams = @{
                    Chart     = $exampleChart
                    ChartArea = $exampleChartArea
                    Name      = ' '
                    Text      = ' '
                    Font      = New-Object -TypeName 'System.Drawing.Font' -ArgumentList @('Arial', '12', [System.Drawing.FontStyle]::Bold)
                }
                Add-ChartTitle @addChartTitleParams

                $chartFileItem = Export-Chart -Chart $exampleChart -Path (Get-Location).Path -Format "PNG" -PassThru
            }
            catch {
                Write-PscriboMessage -IsWarning $($_.Exception.Message)
            }
            if ($OutObj) {
                Section -Style NOTOCHeading3 -ExcludeFromTOC 'Tape Infrastructure' {
                    if ($chartFileItem -and ($inObj.Values | Measure-Object -Sum).Sum -ne 0) {
                        Image -Text 'Tape Infrastructure - Diagram' -Align 'Center' -Percent 100 -Path $chartFileItem
                    }
                    BlankLine
                    $OutObj | Table @TableParams
                }
            }
        }
        catch {
            Write-PscriboMessage -IsWarning $_.Exception.Message
        }
    }
    end {}

}