# Intune Apps Report Generator

This project provides a simple PowerShell script to generate a PDF report of Intune applications and managed devices by connecting to Microsoft Graph API.

## Prerequisites

- PowerShell (version 5.1 or later)
- Access to an Azure tenant with Intune configured
- An Entra app registration with appropriate permissions

## Authentication Setup

To authenticate with Microsoft Graph API, you need to set up an app registration in Azure Active Directory (Entra ID) and grant the necessary permissions.

### 1. Create an App Registration

1. Go to the Azure portal.
2. Navigate to **Azure Active Directory** > **App registrations**.
3. Click **New registration**.
4. Enter a name for your app (e.g., "Intune Report Generator").
5. Select **Accounts in this organizational directory only**.
6. Click **Register**.

### 2. Grant Permissions

In the app registration:

1. Go to **API permissions**.
2. Click **Add a permission**.
3. Select **Microsoft Graph**.
4. Choose **Application permissions**.
5. Add the following permissions:
   - `DeviceManagementApps.Read.All` (or `DeviceManagementApps.ReadWrite.All`)
   - `DeviceManagementManagedDevices.Read.All` (or `DeviceManagementManagedDevices.ReadWrite.All`)
6. Click **Grant admin consent** for your organization.

### 3. Create a Client Secret

1. Go to **Certificates & secrets**.
2. Click **New client secret**.
3. Enter a description and set an expiration.
4. Copy the **Value** (this is your `INTUNE_CLIENT_SECRET`).

### 4. Note the App Details

- **Application (client) ID**: This is your `INTUNE_CLIENT_ID`.
- **Directory (tenant) ID**: This is your `INTUNE_TENANT_ID`.

## Usage

### Set Environment Variables

Set the required environment variables:

```powershell
$env:INTUNE_TENANT_ID = "your-tenant-id"
$env:INTUNE_CLIENT_ID = "your-client-id"
$env:INTUNE_CLIENT_SECRET = "your-client-secret"
```

### Run the Script

Execute the script from the project directory:

```powershell
.\Generate-IntuneAppsReport.ps1
```

Alternatively, pass parameters directly:

```powershell
.\Generate-IntuneAppsReport.ps1 `
  -TenantId "your-tenant-id" `
  -ClientId "your-client-id" `
  -ClientSecret "your-client-secret" `
  -OutputPath ".\output\intune-apps-report.pdf"
```

The script will:
1. Authenticate to Microsoft Graph using client credentials.
2. Retrieve Intune applications and managed devices.
3. Generate a PDF report in the `output` folder.
4. Validate the PDF output.

## Output

- The report is saved as `output/intune-apps-report.pdf`.
- It includes summary counts followed by lists of applications and devices.

## Troubleshooting

- Ensure the app has admin-consented permissions.
- Verify environment variables or parameters are correct.
- Check that your account has access to the Intune data.