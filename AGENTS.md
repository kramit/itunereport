# AGENTS.md

## Purpose

This folder contains a simple Intune reporting workflow. The main script connects to Microsoft Graph using the client credentials flow, reads Intune inventory data, and writes a PDF report.

The current implementation lives in [Generate-IntuneAppsReport.ps1](c:\Users\bob\Documents\workingdir\itunereport\Generate-IntuneAppsReport.ps1).

## Files

- `Generate-IntuneAppsReport.ps1`: Main PowerShell script that authenticates to Graph, retrieves Intune apps and devices, builds report lines, writes a PDF, and performs a basic PDF validation check.
- `Report-Design.md`: Natural-language description of the intended visual style of the report.
- `Report-Content.md`: Natural-language description of what the report contains and what it is for.
- `output/intune-apps-report.pdf`: Latest generated sample output.

## How The Current Script Works

1. Read credentials from parameters or environment variables:
   `INTUNE_TENANT_ID`, `INTUNE_CLIENT_ID`, `INTUNE_CLIENT_SECRET`.
2. Request a Microsoft Graph access token from the Microsoft identity platform using:
   `https://login.microsoftonline.com/{tenantId}/oauth2/v2.0/token`
3. Call Microsoft Graph:
   `GET /v1.0/deviceAppManagement/mobileApps`
4. Call Microsoft Graph:
   `GET /v1.0/deviceManagement/managedDevices`
5. Convert the returned JSON objects into plain report lines.
6. Render those lines into a minimal PDF file using built-in PowerShell and .NET classes.
7. Validate that the output file looks like a structurally valid PDF.

## Permissions Required

The Entra app registration used for authentication should have admin-consented Microsoft Graph application permissions equivalent to:

- `DeviceManagementApps.Read.All` or `DeviceManagementApps.ReadWrite.All`
- `DeviceManagementManagedDevices.Read.All` or `DeviceManagementManagedDevices.ReadWrite.All`

Without those permissions, the script will authenticate successfully but fail on one or more Graph calls.

## Running The Script

Example using environment variables in PowerShell:

```powershell
$env:INTUNE_CLIENT_ID = "your-client-id"
$env:INTUNE_TENANT_ID = "your-tenant-id"
$env:INTUNE_CLIENT_SECRET = "your-client-secret"
.\Generate-IntuneAppsReport.ps1
```

Example with explicit parameters:

```powershell
.\Generate-IntuneAppsReport.ps1 `
  -TenantId "your-tenant-id" `
  -ClientId "your-client-id" `
  -ClientSecret "your-client-secret" `
  -OutputPath ".\output\intune-apps-report.pdf"
```

## Recreating This With Another LLM

If you want another LLM to rebuild this project, give it the files in this folder and ask it to preserve the same workflow:

1. Use PowerShell as the implementation language unless there is a reason to switch.
2. Authenticate to Microsoft Graph with OAuth 2.0 client credentials.
3. Retrieve Intune applications from `deviceAppManagement/mobileApps`.
4. Retrieve Intune managed devices from `deviceManagement/managedDevices`.
5. Build a report that starts with summary counts and then lists applications and devices.
6. Generate a PDF output file locally.
7. Validate the PDF after writing it.
8. Use `Report-Design.md` as the visual brief.
9. Use `Report-Content.md` as the content brief.

Recommended prompt for another LLM:

```text
Recreate the Intune report generator in this folder. Use the design guidance in Report-Design.md and the content guidance in Report-Content.md. Build a script that authenticates to Microsoft Graph with client credentials, retrieves Intune applications and managed devices, writes a PDF report, validates the PDF output, and keeps the implementation easy to run locally.
```

## Expectations For Future Changes

- Keep the workflow easy to run from a terminal.
- Prefer stable Microsoft Graph `v1.0` endpoints when available.
- Keep the output readable as both a screen document and a printable document.
- If the script is expanded, keep the data-collection logic, report-content logic, and presentation logic easy to distinguish.
