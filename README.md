# PD2 x Customer Lifecycle 🔒

A hands-on Salesforce PD2+ implementation project built around a single Customer Lifecycle business process.

The project progressively applies Apex development, asynchronous processing, Record Types, sharing, bulkification, error handling, and trigger architecture.

---

## Business Scenario

When an Opportunity becomes **Closed Won** and is associated with a **Prospective Account**:

1. Convert the Account from **Prospective → Customer**.
2. Set `ConversionDate__c` on the Account.
3. Find eligible Leads using the custom `Lead.Account__c` relationship.
4. Convert those Leads to Contacts under the existing Account.
5. Convert the resulting Contacts and existing **Potential Customer** Contacts to **Customer**.
6. Set `ConversionDate__c` on the Contacts.
7. Share Customer Contacts with active Standard Users whose `Country__c` matches the Account's `BillingCountry`.

### Security Model

| Object | OWD |
|--------|-----|
| Account | Private |
| Contact | Private |
| Lead | Private |
| Opportunity | Private |

---

## Implementation

### 1. Opportunity → Account Onboarding

The Opportunity trigger handles:

- `after insert`
- `after update`

Only Opportunities that become **Closed Won** are processed.

For updates, the implementation compares `Trigger.new` with `Trigger.oldMap`.

**Examples:**

| Previous Stage | New Stage | Process |
|---|---|---|
| Open | Closed Won | Yes |
| Closed Lost | Closed Won | Yes |
| Closed Won | Closed Won | No |

Eligible Opportunities are then filtered to Accounts with the **Prospective** Record Type.

The Account is updated to:

- Record Type → `Customer`
- `ConversionDate__c` → `Date.today()`

Record Type IDs are retrieved using Developer Names rather than hardcoded IDs.

---

### 2. Bulk Account Processing

The onboarding logic supports multiple Opportunities in the same transaction.

It:

- Collects eligible Opportunities
- Filters them to valid Prospective Accounts
- Deduplicates Accounts
- Processes Accounts in bulk

If multiple Closed Won Opportunities belong to the same Account, that Account is processed only once.

Account updates use partial-success DML:

```apex
Database.update(accountsToConvert, false);
```

Successful Account IDs continue to the next Queueable, while failures are logged individually.

---

### 3. Queueable Lead Processing

Successfully onboarded Accounts are passed to:

```text
OnboardedAccountConvertLeadContacts
```

Lead processing therefore runs in a separate asynchronous transaction.

---

### 4. Lead Identification

The initial idea of identifying Leads using the Account email domain was dropped.

The current implementation uses the custom Account lookup:

```text
Lead.Account__c
```

A Lead is eligible when:

- `IsConverted = false`
- Email is populated
- `Account__c` belongs to an onboarded Account

The Account lookup is the source of truth for Lead association.

---

### 5. Lead → Contact Conversion

The converted Lead Status is retrieved dynamically using `LeadStatus.IsConverted` rather than hardcoding a status value.

Multiple Lead conversions are collected and processed together using:

```apex
Database.convertLead(conversionsList, false);
```

Partial-success processing is used and successful Contact IDs are collected for the next stage.

The resulting Contact is explicitly associated with the existing Account:

```apex
conversion.setAccountId(l.Account__c);
```

Opportunity creation during Lead conversion is disabled:

```apex
conversion.setDoNotCreateOpportunity(true);
```

---

### 6. Contact Consolidation

The next Queueable is:

```text
OnboardedAccountConvertContacts
```

It receives:

- Successfully converted Contact IDs
- Successfully onboarded Account IDs

It finds Contacts belonging to those Accounts where either:

- The Contact was newly converted from a Lead
- The Contact has the **Potential Customer** Record Type

Both groups are then converted to the **Customer Contact Record Type** and:

```text
ConversionDate__c = Date.today()
```

Contact updates use:

```apex
Database.update(contactsToUpdateMap.values(), false);
```

Successful Contacts continue to the sharing stage and failures are logged individually.

---

### 7. Customer Contact Sharing

Customer Contacts are shared with:

- Active Users
- Standard Users
- `User.Country__c = Account.BillingCountry`

Blank Account countries are ignored.

Users are grouped by country before ContactShare records are generated.

Each applicable Contact/User combination receives:

```text
ContactAccessLevel = Edit
RowCause = Manual
```

ContactShare records are inserted using:

```apex
Database.insert(csList, false);
```

Individual failures are logged without preventing successful shares.

---

## Trigger Architecture

The project currently follows a Trigger → Handler → Helper structure.

```
OpportunityTrigger
└── OpportunityTriggerHandler
    └── OpportunityTriggerHelper

AccountTrigger
└── AccountTriggerHandler
    └── AccountTriggerHelper

ContactTrigger
└── ContactTriggerHandler
    └── ContactTriggerHelper
```

The triggers remain thin and delegate business logic to the corresponding classes.

---

## Recursion Exercise

A deliberate Account ↔ Contact recursion scenario has also been implemented.

```
Account Update
    ↓
Account Trigger
    ↓
Contact Update
    ↓
Contact Trigger
    ↓
Account Update
    ↓
Account Trigger
```

The Account handler maintains:

```apex
public static Set<Id> processedAccountIds
```

to prevent the Account from being processed again during the recursive transaction.

`Trigger.oldMap` is used to detect the timestamp changes that drive the recursive path.

This is a dedicated recursion exercise within the project.

---

## Current Class Structure

```
OpportunityTrigger
└── OpportunityTriggerHandler
    └── OpportunityTriggerHelper

OnboardedAccountConvertLeadContacts
└── Lead Conversion

OnboardedAccountConvertContacts
├── Contact Conversion
└── Contact Sharing

AccountTrigger
└── AccountTriggerHandler
    └── AccountTriggerHelper

ContactTrigger
└── ContactTriggerHandler
    └── ContactTriggerHelper
```

---

## Concepts Practiced

- Apex Triggers
- `after insert`
- `after update`
- `Trigger.new`
- `Trigger.oldMap`
- Change detection
- Bulkification
- Sets and Maps
- Relationship queries
- Record Types by Developer Name
- Partial-success DML
- `Database.SaveResult`
- Lead conversion
- Dynamic converted Lead Status
- Queueable Apex
- Queueable chaining
- Asynchronous transaction separation
- Explicit Account association during Lead conversion
- Private OWD
- Contact sharing
- `ContactShare`
- Manual sharing
- Trigger → Handler → Helper architecture
- Recursion testing
- Static recursion guards
- Account deduplication
- Per-record error logging

---

## Deliberately Skipped

The following scenarios were discussed but explicitly skipped:

- Account Country Change → Sharing Recalculation
- Contact Reparenting

They are **not part of the current implementation**.

---

## Current Status

| Area | Status |
|------|--------|
| Opportunity → Closed Won detection | ✅ |
| Prospective → Customer Account | ✅ |
| Account Conversion Date | ✅ |
| Bulk Account onboarding | ✅ |
| Partial-success Account processing | ✅ |
| Queueable Lead processing | ✅ |
| `Lead.Account__c` Lead identification | ✅ |
| Dynamic converted Lead Status | ✅ |
| Bulk Lead conversion | ✅ |
| Lead → existing Account Contact | ✅ |
| Contact consolidation | ✅ |
| Potential Customer → Customer | ✅ |
| Contact Conversion Date | ✅ |
| Country-based Contact sharing | ✅ |
| Partial-success ContactShare processing | ✅ |
| Trigger / Handler / Helper architecture | ✅ |
| Recursion exercise | ✅ |

---

## Project Goal

Build one progressively more advanced Salesforce implementation around a realistic Customer Lifecycle.

The goal is to develop practical PD2-level skills while gradually introducing the kind of transaction, bulkification, security, asynchronous-processing, and architectural thinking expected from a strong Salesforce developer.

**One project. One evolving requirement.**
