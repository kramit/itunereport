[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId = $env:INTUNE_TENANT_ID,

    [Parameter(Mandatory = $false)]
    [string]$ClientId = $env:INTUNE_CLIENT_ID,

    [Parameter(Mandatory = $false)]
    [string]$ClientSecret = $env:INTUNE_CLIENT_SECRET,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = (Join-Path -Path $PSScriptRoot -ChildPath "output\intune-apps-report.pdf")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Assert-RequiredValue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        throw "Missing required value: $Name"
    }
}

function Get-GraphAccessToken {
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,

        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$ClientSecret
    )

    $tokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $body = @{
        client_id     = $ClientId
        client_secret = $ClientSecret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = "client_credentials"
    }

    $tokenResponse = Invoke-RestMethod -Method Post -Uri $tokenUri -Body $body -ContentType "application/x-www-form-urlencoded"
    if ([string]::IsNullOrWhiteSpace($tokenResponse.access_token)) {
        throw "Failed to acquire an access token from Microsoft Entra ID."
    }

    return $tokenResponse.access_token
}

function Invoke-GraphPagedGet {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $headers = @{
        Authorization = "Bearer $AccessToken"
        Accept        = "application/json"
    }

    $items = New-Object System.Collections.Generic.List[object]
    $nextUri = $Uri

    while (-not [string]::IsNullOrWhiteSpace($nextUri)) {
        $response = Invoke-RestMethod -Method Get -Uri $nextUri -Headers $headers
        $valueProperty = $response.PSObject.Properties["value"]

        if ($null -ne $valueProperty -and $null -ne $valueProperty.Value) {
            foreach ($item in $valueProperty.Value) {
                [void]$items.Add($item)
            }
        }

        $nextLinkProperty = $response.PSObject.Properties["@odata.nextLink"]
        if ($null -ne $nextLinkProperty -and -not [string]::IsNullOrWhiteSpace([string]$nextLinkProperty.Value)) {
            $nextUri = [string]$nextLinkProperty.Value
        }
        else {
            $nextUri = $null
        }
    }

    return $items
}

function Get-IntuneApplications {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $uri = "https://graph.microsoft.com/v1.0/deviceAppManagement/mobileApps?`$top=999"
    $apps = Invoke-GraphPagedGet -Uri $uri -AccessToken $AccessToken

    return $apps | Sort-Object -Property @{
        Expression = {
            if ([string]::IsNullOrWhiteSpace($_.displayName)) {
                "~"
            }
            else {
                $_.displayName.ToLowerInvariant()
            }
        }
    }
}

function Get-IntuneDevices {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AccessToken
    )

    $uri = "https://graph.microsoft.com/v1.0/deviceManagement/managedDevices?`$top=999"
    $devices = Invoke-GraphPagedGet -Uri $uri -AccessToken $AccessToken

    return $devices | Sort-Object -Property @{
        Expression = {
            if ([string]::IsNullOrWhiteSpace($_.deviceName)) {
                "~"
            }
            else {
                $_.deviceName.ToLowerInvariant()
            }
        }
    }
}

function Get-ObjectPropertyValue {
    param(
        [Parameter(Mandatory = $true)]
        [object]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    $property = $InputObject.PSObject.Properties[$PropertyName]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

function Escape-PdfText {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Text
    )

    return $Text.Replace('\', '\\').Replace('(', '\(').Replace(')', '\)')
}

function New-PdfContentStream {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $content = New-Object System.Text.StringBuilder
    [void]$content.AppendLine("BT")
    [void]$content.AppendLine("/F1 10 Tf")
    [void]$content.AppendLine("50 780 Td")
    [void]$content.AppendLine("14 TL")

    $firstLine = $true
    foreach ($line in $Lines) {
        $escaped = Escape-PdfText -Text $line
        if ($firstLine) {
            [void]$content.AppendLine("($escaped) Tj")
            $firstLine = $false
        }
        else {
            [void]$content.AppendLine("T*")
            [void]$content.AppendLine("($escaped) Tj")
        }
    }

    [void]$content.AppendLine("ET")
    return $content.ToString()
}

function Split-ReportLinesIntoPages {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines,

        [Parameter(Mandatory = $false)]
        [int]$LinesPerPage = 48
    )

    $pages = New-Object System.Collections.Generic.List[object]
    for ($i = 0; $i -lt $Lines.Count; $i += $LinesPerPage) {
        $remaining = $Lines.Count - $i
        $take = [Math]::Min($LinesPerPage, $remaining)
        $pages.Add($Lines[$i..($i + $take - 1)])
    }

    return ,$pages
}

function Write-SimplePdf {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $outputDirectory = Split-Path -Path $OutputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($outputDirectory)) {
        New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    $pages = Split-ReportLinesIntoPages -Lines $Lines
    if ($pages.Count -eq 0) {
        $pages = @(@("No data available."))
    }

    $objects = New-Object System.Collections.Generic.List[string]

    $objects.Add("<< /Type /Catalog /Pages 2 0 R >>")

    $pageObjectNumbers = @()
    $nextObjectNumber = 3

    foreach ($pageLines in $pages) {
        $pageObjectNumbers += $nextObjectNumber
        $nextObjectNumber += 2
    }

    $kids = ($pageObjectNumbers | ForEach-Object { "$_ 0 R" }) -join " "
    $objects.Add("<< /Type /Pages /Count $($pageObjectNumbers.Count) /Kids [ $kids ] >>")

    for ($pageIndex = 0; $pageIndex -lt $pages.Count; $pageIndex++) {
        $pageObjectNumber = $pageObjectNumbers[$pageIndex]
        $contentObjectNumber = $pageObjectNumber + 1
        $contentStream = New-PdfContentStream -Lines $pages[$pageIndex]
        $contentBytes = [System.Text.Encoding]::ASCII.GetBytes($contentStream)
        $stream = "<< /Length $($contentBytes.Length) >>`nstream`n$contentStream`nendstream"

        $pageObject = "<< /Type /Page /Parent 2 0 R /MediaBox [ 0 0 612 792 ] /Resources << /Font << /F1 << /Type /Font /Subtype /Type1 /BaseFont /Helvetica >> >> >> /Contents $contentObjectNumber 0 R >>"
        $objects.Add($pageObject)
        $objects.Add($stream)
    }

    $builder = New-Object System.Text.StringBuilder
    [void]$builder.Append("%PDF-1.4`n")

    $offsets = New-Object System.Collections.Generic.List[int]
    $offsets.Add(0)

    for ($index = 0; $index -lt $objects.Count; $index++) {
        $objectNumber = $index + 1
        $offsets.Add($builder.Length)
        [void]$builder.Append("$objectNumber 0 obj`n")
        [void]$builder.Append($objects[$index])
        [void]$builder.Append("`nendobj`n")
    }

    $xrefOffset = $builder.Length
    [void]$builder.Append("xref`n")
    [void]$builder.Append("0 $($objects.Count + 1)`n")
    [void]$builder.Append("0000000000 65535 f `n")

    for ($index = 1; $index -le $objects.Count; $index++) {
        [void]$builder.Append(("{0:0000000000} 00000 n `n" -f $offsets[$index]))
    }

    [void]$builder.Append("trailer`n")
    [void]$builder.Append("<< /Size $($objects.Count + 1) /Root 1 0 R >>`n")
    [void]$builder.Append("startxref`n")
    [void]$builder.Append("$xrefOffset`n")
    [void]$builder.Append("%%EOF")

    [System.IO.File]::WriteAllText($OutputPath, $builder.ToString(), [System.Text.Encoding]::ASCII)
}

function Test-PdfFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $content = [System.IO.File]::ReadAllText($Path, [System.Text.Encoding]::ASCII)
    return $content.StartsWith("%PDF-1.4") -and
        $content.Contains("xref") -and
        $content.Contains("trailer") -and
        $content.TrimEnd().EndsWith("%%EOF")
}

function New-ReportLines {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Applications,

        [Parameter(Mandatory = $true)]
        [object[]]$Devices
    )

    $generatedAt = [DateTimeOffset]::UtcNow.ToString("u")
    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Intune Applications And Devices Report")
    $lines.Add("Generated (UTC): $generatedAt")
    $lines.Add("Application count: $($Applications.Count)")
    $lines.Add("Device count: $($Devices.Count)")
    $lines.Add("")

    $lines.Add("Applications")
    $lines.Add("------------")

    if ($Applications.Count -eq 0) {
        $lines.Add("No applications were returned by Microsoft Graph.")
    }
    else {
        $index = 1
        foreach ($app in $Applications) {
            $name = if ([string]::IsNullOrWhiteSpace($app.displayName)) { "<no display name>" } else { [string]$app.displayName }
            $type = if ($app.'@odata.type') { [string]$app.'@odata.type' } else { "<unknown type>" }
            $publisher = if ([string]::IsNullOrWhiteSpace($app.publisher)) { "<no publisher>" } else { [string]$app.publisher }
            $created = if ($app.createdDateTime) { [string]$app.createdDateTime } else { "<no created date>" }
            $id = if ($app.id) { [string]$app.id } else { "<no id>" }

            $lines.Add(("{0}. {1}" -f $index, $name))
            $lines.Add("   Type: $type")
            $lines.Add("   Publisher: $publisher")
            $lines.Add("   Created: $created")
            $lines.Add("   Id: $id")
            $lines.Add("")
            $index++
        }
    }

    $lines.Add("")
    $lines.Add("Devices")
    $lines.Add("-------")

    if ($Devices.Count -eq 0) {
        $lines.Add("No devices were returned by Microsoft Graph.")
    }
    else {
        $index = 1
        foreach ($device in $Devices) {
            $deviceNameValue = Get-ObjectPropertyValue -InputObject $device -PropertyName "deviceName"
            $operatingSystemValue = Get-ObjectPropertyValue -InputObject $device -PropertyName "operatingSystem"
            $osVersionValue = Get-ObjectPropertyValue -InputObject $device -PropertyName "osVersion"
            $ownerTypeValue = Get-ObjectPropertyValue -InputObject $device -PropertyName "ownerType"
            $complianceStateValue = Get-ObjectPropertyValue -InputObject $device -PropertyName "complianceState"
            $lastSyncValue = Get-ObjectPropertyValue -InputObject $device -PropertyName "lastSyncDateTime"
            $userPrincipalNameValue = Get-ObjectPropertyValue -InputObject $device -PropertyName "userPrincipalName"
            $idValue = Get-ObjectPropertyValue -InputObject $device -PropertyName "id"

            $name = if ([string]::IsNullOrWhiteSpace([string]$deviceNameValue)) { "<no device name>" } else { [string]$deviceNameValue }
            $os = if ([string]::IsNullOrWhiteSpace([string]$operatingSystemValue)) { "<no operating system>" } else { [string]$operatingSystemValue }
            $osVersion = if ([string]::IsNullOrWhiteSpace([string]$osVersionValue)) { "<no os version>" } else { [string]$osVersionValue }
            $owner = if ([string]::IsNullOrWhiteSpace([string]$ownerTypeValue)) { "<no owner type>" } else { [string]$ownerTypeValue }
            $compliance = if ([string]::IsNullOrWhiteSpace([string]$complianceStateValue)) { "<no compliance state>" } else { [string]$complianceStateValue }
            $lastSync = if ($null -ne $lastSyncValue -and -not [string]::IsNullOrWhiteSpace([string]$lastSyncValue)) { [string]$lastSyncValue } else { "<no last sync>" }
            $user = if ([string]::IsNullOrWhiteSpace([string]$userPrincipalNameValue)) { "<no primary user>" } else { [string]$userPrincipalNameValue }
            $id = if ($null -ne $idValue -and -not [string]::IsNullOrWhiteSpace([string]$idValue)) { [string]$idValue } else { "<no id>" }

            $lines.Add(("{0}. {1}" -f $index, $name))
            $lines.Add("   OS: $os $osVersion")
            $lines.Add("   Owner: $owner")
            $lines.Add("   Compliance: $compliance")
            $lines.Add("   Last sync: $lastSync")
            $lines.Add("   User: $user")
            $lines.Add("   Id: $id")
            $lines.Add("")
            $index++
        }
    }

    return $lines
}

Assert-RequiredValue -Name "TenantId" -Value $TenantId
Assert-RequiredValue -Name "ClientId" -Value $ClientId
Assert-RequiredValue -Name "ClientSecret" -Value $ClientSecret

$accessToken = Get-GraphAccessToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
$applications = @(Get-IntuneApplications -AccessToken $accessToken)
$devices = @(Get-IntuneDevices -AccessToken $accessToken)
$reportLines = New-ReportLines -Applications $applications -Devices $devices
Write-SimplePdf -Lines $reportLines -OutputPath $OutputPath

if (-not (Test-PdfFile -Path $OutputPath)) {
    throw "The generated PDF did not pass the basic file validation check."
}

[PSCustomObject]@{
    OutputPath        = (Resolve-Path -LiteralPath $OutputPath).Path
    ApplicationCount  = $applications.Count
    DeviceCount       = $devices.Count
    PdfValidationPass = $true
} | Format-List
