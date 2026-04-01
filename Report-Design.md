# Intune Report Design Brief

This report should feel clean, technical, and professional rather than decorative. The visual goal is to make it easy for an IT administrator to scan the document quickly and trust the information.

Use a light background, ideally white or a very pale grey, so the report prints well and keeps strong contrast. The primary accent color should be a Microsoft-adjacent blue, such as a medium azure tone, used sparingly for headings, section dividers, table headers, or key summary figures. Neutral dark greys should be used for body text. Avoid saturated or playful color palettes. Green may be used only for healthy or compliant states, amber for warnings, and red only for important failures or non-compliance indicators.

A Microsoft-inspired color theme should be used throughout the report:

- Primary blue: `#0078D4` for main headings, key counts, and section accents.
- Dark blue: `#106EBE` for secondary headers or emphasis areas.
- Neutral dark grey: `#323130` for body text.
- Neutral mid grey: `#605E5C` for supporting labels and metadata.
- Light grey background: `#F3F2F1` for subtle panels or summary boxes.
- Border grey: `#D2D0CE` for dividers or table rules.
- Success green: `#107C10` for compliant or healthy states.
- Warning amber: `#FFB900` for stale or at-risk update states.
- Error red: `#D13438` for failed updates, non-compliance, or critical exceptions.

The color usage should remain disciplined. Most of the report should still read as black or dark grey on white, with the Microsoft accent colors reserved for navigation, emphasis, and status meaning.

Typography should be modern and highly legible. A sensible default is Segoe UI if available, because it matches the Microsoft ecosystem well. Acceptable alternatives would be Calibri, Aptos, or Arial if font portability is more important than strict brand feel. Section headings should be visually distinct through size and weight rather than excessive color. Body text should remain simple and easy to read at normal print sizes.

The layout should prioritize structure:

- A title block at the top with report name, generation timestamp, and tenant or environment context if available.
- A short summary section near the beginning with counts such as total applications and total managed devices.
- Clear section breaks for Applications and Devices.
- Consistent spacing between records so each application or device entry is visually separable.
- If tables are used, keep borders subtle and rely more on spacing, alignment, and header contrast than heavy grid lines.

The document should look good both on screen and when exported or printed. That means avoiding dark backgrounds, avoiding low-contrast text, and keeping margins generous enough that nothing feels cramped.

The overall impression should be: enterprise, readable, restrained, and dependable.
