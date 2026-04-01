# Intune Report Content Brief

This report is intended to provide a quick operational snapshot of the Intune environment through Microsoft Graph data. It should focus on inventory-style information first, with room to extend into richer health and compliance reporting later.

The report currently includes two main sections.

Applications section:

- Total number of Intune applications returned by Microsoft Graph.
- For each application:
- Display name.
- Graph object type.
- Publisher.
- Created date and time.
- Unique application identifier.

Devices section:

- Total number of managed devices returned by Microsoft Graph.
- For each device:
- Device name.
- Operating system and OS version.
- Ownership type when available.
- Compliance state.
- Last sync date and time.
- Primary user principal name when available.
- Unique device identifier.

Update health and exceptions section:

- A list of devices that are not updating.
- A list of devices with failed update attempts.
- A note for devices that made an update attempt but the attempt failed.
- This section should be easy to scan and should highlight exceptions rather than burying them inside the full device inventory.
- If possible in future versions, include the most recent update-related status, timestamp, and any available failure reason.

The report should begin with a summary area that states when it was generated and the top-level counts for apps and devices. After that, the detail sections should present the full inventory in a stable, predictable order.

The content should stay factual and concise. It is primarily an administrative reference document, not a narrative dashboard. Any future enhancements should preserve that principle.

Good future additions could include:

- Device enrollment type.
- Manufacturer and model.
- Management state.
- Application assignment details.
- Compliance policy summaries.
- Detected stale devices based on last sync age.
- Exception sections for non-compliant or inactive devices.
- Windows update status and update ring context.
- Devices failing quality or feature updates.
