# RefreshOrg — CLAUDE.md

## What This Project Does

**RefreshOrg** is a Salesforce 2GP managed package (namespace: `refreshorg`) that masks or redacts sensitive data after a sandbox refresh or org clone. It prevents developers/QA from accessing real production data. Admins trigger operations via a Lightning app with three modes: **Standard** (fixed batch chain for Opportunity → Account), **Custom Masking** (user-picks any object + Email/Phone fields), and **Custom Redaction** (user-picks any object + fields with per-field character range configuration).

---

## Package Info

- **Package name:** RefreshOrg
- **Namespace:** `refreshorg`
- **Package ID:** `0HogK000000391xSAA`
- **Source API version:** 66.0
- **Type:** Salesforce 2GP (second-generation managed package)
- **Latest versions:** `RefreshOrg@0.1.0-1`, `RefreshOrg@0.1.0-2`

---

## Architecture

### Three Operation Modes

| Mode | Trigger | Objects | Fields | Batch Class |
|------|---------|---------|--------|-------------|
| Standard | `maskStandardData()` | Opportunity → Account (hardcoded) | Name, Phone, Website, AccountNumber | `Batch_MaskOpportunityRecordsDetails` → chains `Batch_MaskAccountRecordsDetails` |
| Custom Masking | `maskCustomData(payload)` | Any user-selected object | Email and Phone fields only | `Batch_MaskObjectRecordsDetails` |
| Custom Redaction | `redactCustomData(payload)` | Any user-selected object | Email, Phone, and String fields | `Batch_RedactObjectRecordDetails` |

### Masking vs Redaction

- **Masking** replaces the entire field value with randomly generated data (e.g., `(555) 123-4567`, `abc123@gmail.com`).
- **Redaction** replaces a user-specified character range (1-based, alphanumeric positions only) with asterisks while preserving special characters like dashes, parentheses, and `@domain`.

### Batch Chaining Pattern

`Batch_MaskObjectRecordsDetails` and `Batch_RedactObjectRecordDetails` both accept a `List<MaskingPayload>` and process one object per batch run. In `finish()`, they remove the first element and re-enqueue themselves with the remaining payload — processing each object sequentially.

---

## Key Classes

### `PostRefreshOrgProcessController`
Main Apex controller exposing `@AuraEnabled` methods to LWC components.
- `maskStandardData()` — kicks off the standard Opp → Account batch chain.
- `maskCustomData(payload)` — kicks off `Batch_MaskObjectRecordsDetails` with a user-built payload.
- `redactCustomData(payload)` — kicks off `Batch_RedactObjectRecordDetails` with a user-built payload.
- Inner classes: `MaskingPayload` (objectApiName + List\<FieldData\>), `FieldData` (fieldApiName, fieldDataType, fromChar, toChar).

### `ObjectDataHelper`
Utility controller for object/field metadata queries.
- `getNonSetupObjects()` — returns all queryable, non-custom-setting objects (sorted by label). Used to populate the object search in Custom Masking/Redaction UIs.
- `getObjectFields(objectApiName, operationType)` — returns accessible fields filtered by `RefreshOrg_Utils.isSensitiveField()`. The `operationType` string (`'custom-masking'` or `'custom-redaction'`) controls which field types are returned.

### `RefreshOrg_Utils`
Shared constants and helpers.
- `MASK_OPERATION_TYPE = 'custom-masking'` / `REDACTION_OPERATION_TYPE = 'custom-redaction'`
- Custom masking allows: `EMAIL`, `PHONE`
- Custom redaction allows: `EMAIL`, `PHONE`, `STRING`
- `isSensitiveField()` checks field type against the allowed list for the given operation type.
- `isEditableField()` excludes formula, auto-number, lookup, and roll-up summary fields.

### `DataMaskHelper`
Pure utility class with static methods for generating masked/redacted values.
- `generate_randomPhoneNumber()` → `(XXX) XXX-XXXX`
- `generate_randomEmail()` → 8-char alphanumeric username + random domain
- `generate_randomUrl()`, `generate_randomCreditCardNumber()`, `generate_randomAccountNumber()`
- `generateRedactedPhoneValue(value, fromChar, toChar)` — replaces alphanumeric chars at 1-based positions `fromChar`–`toChar` with `*`, preserving special characters
- `generateRedactedEmailValue(value, fromChar, toChar)` — same but only applies to the local part (before `@`), domain is always preserved

### Standard Batch Classes
- `Batch_MaskOpportunityRecordsDetails` — updates Opp `Name`, and related Account `Phone`/`Website`/`AccountNumber`. Chains to `Batch_MaskAccountRecordsDetails` in `finish()` passing already-updated Account IDs to skip duplicates.
- `Batch_MaskAccountRecordsDetails` — updates Account `Name`, `Phone`, `Website`, `AccountNumber` for records NOT in the passed ID set.

---

## LWC Components

| Component | Role |
|-----------|------|
| `postRefreshOrgProcess` | Top-level app/tab container |
| `or_standardComponent` | Standard mode UI — single button triggers `maskStandardData()` |
| `or_customMaskingCmp` | Custom masking UI — object/field picker tiles, calls `maskCustomData()` |
| `or_customRedactionCmp` | Custom redaction UI — object/field picker tiles with per-field char range inputs, calls `redactCustomData()` |
| `or_customComponent` | Parent wrapper for the redaction tab; passes `redactionCriteria` config (per-type fromChar/toChar defaults) as `@api` to `or_customRedactionCmp` |

### Tile/Pagination Pattern (Custom Masking & Redaction)
Both custom components use the same "tiles" pattern:
- Each tile represents one object + its selected fields.
- Only one tile is displayed at a time (paginated by tile index).
- Object search uses a 300ms debounced typeahead backed by a cached `getNonSetupObjects()` call.
- Max 25 fields per tile (`MAX_SELECTED_FIELDS = 25`).
- Duplicate object selection across tiles is blocked with a toast warning.

---

## Field Type Handling

| Display Type | Custom Masking | Custom Redaction | Standard |
|---|---|---|---|
| EMAIL | Replace with random email | Asterisk range in local part | — |
| PHONE | Replace with `(XXX) XXX-XXXX` | Asterisk range over alphanumeric chars | Account.Phone |
| STRING | — | Asterisk range (full value) | — |
| Name/Website/AccountNumber | — | — | Random alphanumeric/URL |

---

## Development Notes

- All batch DML uses `Database.update(list, false)` (partial success, errors logged via `System.debug`).
- `generateRedactedPhoneValue` / `generateRedactedEmailValue` return `null` if: input is blank, already contains `*`, char indices are out of bounds, or fromChar > toChar.
- `ObjectDataHelper.getNonSetupObjects()` is marked `cacheable=true`; `getObjectFields()` is not (different results per operation type).
- The `list_fieldLabelKeywords` list in `RefreshOrg_Utils` is currently empty — keyword-based sensitive field detection is a placeholder for future use.
