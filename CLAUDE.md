# RefreshOrg — CLAUDE.md

## What This Project Does

**RefreshOrg** is a Salesforce 2GP managed package (namespace: `refreshorg`) that masks sensitive data after a sandbox refresh or org clone. It prevents developers/QA from accessing real production data. Admins trigger masking via a Lightning app with two modes: **Standard** (fixed batch chain for Quote → Opportunity → Account) and **Custom** (user-picks any object + Email/Phone fields).

---

## Package Info

| Key | Value |
|---|---|
| Package ID | `0HogK000000391xSAA` |
| Namespace | `refreshorg` |
| Version | `0.1.0.NEXT` |
| API Version | `66.0` |
| Dev Hub alias | `RefOrg_DevHub` |
| Package type | Managed |

---

## Project Structure

```
force-app/main/default/
  classes/          — 8 production classes + 8 test classes
  lwc/              — 3 LWC components
  objects/          — Quote object config
  tabs/             — Standard_Mask, Custom_Mask
  applications/     — Refresh_Org Lightning app
  flexipages/       — Refresh_Org_UtilityBar
config/
  project-scratch-def.json   — Scratch org definition (Quotes enabled)
```

---

## Key Classes

### Helper / Utility
- **`DataMaskHelper`** — Generates fake phone, email, URL, credit card, account number, random strings. Single source of truth for all random data.
- **`RefreshOrg_Utils`** — Schema introspection: `isEditableField()`, `isSensitiveField()`, `getFieldTypes()`. Used to filter which fields can be masked.
- **`ObjectDataHelper`** — `@AuraEnabled` methods for LWC: `getNonSetupObjects()`, `getObjectFields()`. Surfaces maskable objects/fields to the UI.

### Orchestrator
- **`PostRefreshOrgProcessController`** — Two `@AuraEnabled` entry points:
  - `maskStandardData()` — kicks off `Batch_MaskQuoteRecordsDetails`
  - `maskCustomData(payload)` — kicks off `Batch_MaskObjectRecordsDetails` with user-selected fields

### Batch Chain (Standard Masking)
Runs in sequence via `finish()` chaining:
1. **`Batch_MaskQuoteRecordsDetails`** — Masks Quote (`Name`, `Email`, `Phone`, `Description`), plus related Opportunity (`Name`) and Account (`Phone`, `Website`, `AccountNumber`). Chains to step 2.
2. **`Batch_MaskOpportunityRecordsDetails`** — Masks remaining Opportunities and their Accounts. Chains to step 3.
3. **`Batch_MaskAccountRecordsDetails`** — Masks remaining Accounts not touched by prior batches.

All three implement `Database.Stateful` and track processed IDs in `Set<Id>` fields to avoid duplicate DML across batch chunks.

### Generic Batch (Custom Masking)
- **`Batch_MaskObjectRecordsDetails`** — Accepts a `MaskingPayload` (object API name + list of fields). Dynamically builds SOQL, masks EMAIL→random email and PHONE→random phone. Chains additional payloads in `finish()`.

---

## LWC Components

| Component | Purpose |
|---|---|
| `postRefreshOrgProcess` | Main container. Admin-only guard (checks System Administrator profile via `@wire`). Hosts the two-tab layout. |
| `or_standardComponent` | "Standard Masking" tab. One button → calls `maskStandardData()`. |
| `or_customComponent` | "Custom Masking" tab. Object search (300ms debounce), field selection (dual-listbox, max 25 fields/object), paginated tile UI, calls `maskCustomData()`. |

---

## Common CLI Commands

### Package version create
```bash
sf package version create \
  --package RefreshOrg \
  --installation-key-bypass \
  --code-coverage \
  --wait 20 \
  --target-dev-hub RefOrg_DevHub
```

### Create scratch org
```bash
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --target-dev-hub RefOrg_DevHub \
  --alias RefreshOrg_Scratch \
  --duration-days 7
```

### Deploy to scratch org
```bash
sf project deploy start --target-org RefreshOrg_Scratch
```

### Run tests
```bash
sf apex run test --target-org RefreshOrg_Scratch --code-coverage --result-format human
```

### List package versions
```bash
sf package version list --package RefreshOrg --target-dev-hub RefOrg_DevHub
```

### Install a package version
```bash
sf package install --package <04t_VERSION_ID> --target-org <ORG_ALIAS> --wait 10
```

---

## Scratch Org Requirements

The scratch org definition (`config/project-scratch-def.json`) must include:

```json
"settings": {
  "quoteSettings": { "enableQuote": true }
}
```

Without this, the Apex compiler cannot resolve the `Quote` SObject and all `Batch_MaskQuoteRecords*` classes fail with `Invalid type: Quote`.

---

## Known Gotchas

- **`packageDirectories` must not be empty** in `sfdx-project.json`. The single entry must have `"default": true`. If this gets wiped (e.g. by a CLI command), restore it manually — the package ID lives in `packageAliases` and should not be re-created.
- **Do not run `sf package create` again** — the package already exists (`0HogK000000391xSAA`). That command will return `DUPLICATE_VALUE`.
- **Namespace must be linked to Dev Hub** before `sf package create` or `sf package version create` will work. The namespace `refreshorg` must be registered in a separate Developer Edition org and linked via Setup → Namespace Registries in the Dev Hub org.
- **Dev Hub org cannot own the namespace** — once Dev Hub is enabled on an org, namespace registration is disabled on that same org. Use a second DE org for namespace registration.
- **`Quote` is only available in standard masking** — the `Batch_MaskQuoteRecordsDetails` class has a runtime guard (`isObjectAvailable('Quote')`) that returns an empty query locator if Quotes are not enabled, so it degrades gracefully in orgs where the feature is off.

---

## Architecture — Data Flow

```
Lightning App (Admin only)
  │
  ├── Standard Masking tab (or_standardComponent)
  │     └── PostRefreshOrgProcessController.maskStandardData()
  │           └── Batch_MaskQuoteRecordsDetails
  │                 └── Batch_MaskOpportunityRecordsDetails
  │                       └── Batch_MaskAccountRecordsDetails
  │
  └── Custom Masking tab (or_customComponent)
        └── PostRefreshOrgProcessController.maskCustomData(payload)
              └── Batch_MaskObjectRecordsDetails (chained per object)
```
