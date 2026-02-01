# Salesforce Profile & Permission Comparison Tool

A native Salesforce Lightning application that compares two Profiles side-by-side and identifies differences across multiple permission categories. Built entirely with Lightning Web Components and Apex — no external APIs or storage required.

## Features

- **Side-by-side profile comparison** across six permission categories
- **Summary dashboard** with at-a-glance difference counts
- **Difference-only filtering** to focus on what matters
- **Expandable Field-Level Security** loaded on demand per object
- **CRUD visualization** using a compact `CREDVM` format
- **Built-in How to Use guide** for end users

## Comparison Categories

| Category | What It Compares |
|---|---|
| Assigned Apps | App visibility per profile |
| Object Settings | CRUD permissions (Create, Read, Edit, Delete, View All, Modify All) with expandable FLS |
| System Permissions | All system-level permissions (API Enabled, Modify All Data, etc.) |
| Apex Class Access | Which Apex classes each profile can execute |
| Visualforce Page Access | Which VF pages each profile can access |
| Custom Permissions | Custom permission assignments |

## Installation

### Option 1: Install via Unmanaged Package

Use the install link to add the tool directly to your Salesforce org:

**Production/Developer Edition:**
`https://login.salesforce.com/packaging/installPackage.apexp?p0=PACKAGE_ID`

**Sandbox:**
`https://test.salesforce.com/packaging/installPackage.apexp?p0=PACKAGE_ID`

> Replace `PACKAGE_ID` with the actual package version ID (starts with `04t`).

When prompted, choose **Install for Admins Only** or **Install for All Users** depending on who should have access.

### Option 2: Deploy from Source

1. Clone the repository:
   ```bash
   git clone https://github.com/theodenanyoh11/SFDC-Profile-and-Permissions-Compare-Tool.git
   cd SFDC-Profile-and-Permissions-Compare-Tool
   ```

2. Authorize your target org:
   ```bash
   sf org login web -a my-org
   ```

3. Deploy:
   ```bash
   sf project deploy start -d force-app -o my-org
   ```

## Post-Install Setup

After installing the package (either method), complete these steps to grant access:

### 1. Assign Apex Class Access

Go to **Setup > Profiles** (or create a Permission Set) and enable access for these Apex classes:

- `ProfileComparisonController`
- `ProfileComparisonModels`
- `ProfileComparisonService`
- `ProfileMetadataService`

### 2. Set Tab Visibility

Under the same Profile or Permission Set, set these tabs to **Default On**:

- `Profile Comparison`
- `How to use P&PC`

### 3. Make the App Visible

Under **App Visibility** (or **Assigned Connected Apps**), make the **Profile & Permission Comparison** app visible.

### 4. Open the App

Go to the **App Launcher** (grid icon in the top-left) and search for **Profile & Permission Comparison**.

> **Tip:** If you installed for "All Users," Apex class access and tab visibility are granted automatically. If you installed for "Admins Only," you'll need to manually assign access to other profiles.

## Project Structure

```
force-app/main/default/
├── classes/
│   ├── ProfileComparisonController.cls       # LWC controller
│   ├── ProfileComparisonModels.cls           # Data wrapper classes
│   ├── ProfileComparisonService.cls          # Comparison logic
│   ├── ProfileMetadataService.cls            # Profile metadata retrieval
│   ├── *_Test.cls                            # Test classes
│
├── lwc/
│   ├── profileComparisonApp/                 # Main app component
│   ├── comparisonTable/                      # Reusable comparison table
│   ├── objectSettingsTable/                  # Object settings with expandable FLS
│   └── howToUsePPC/                          # How to Use guide
│
├── tabs/
│   ├── How_to_use_PPC.tab-meta.xml
│   └── Profile_Permission_Comparison.tab-meta.xml
│
├── applications/
│   └── Profile_Permission_Comparison.app-meta.xml
│
├── flexipages/
│   └── Profile_Permission_Comparison.flexipage-meta.xml
│
└── profiles/
    ├── Admin.profile-meta.xml
    └── System Admin Limited.profile-meta.xml
```

## Architecture

- **ProfileMetadataService** — Queries profile permissions via SOQL on `PermissionSet`, `ObjectPermissions`, `FieldPermissions`, and `SetupEntityAccess`. System permissions are discovered dynamically by introspecting all `Permissions*` fields on the PermissionSet object.
- **ProfileComparisonService** — Takes two `ProfileMetadata` objects and produces a `ComparisonResult` with diff indicators for every item.
- **ProfileComparisonController** — Exposes three `@AuraEnabled` methods: `getProfiles()` (cacheable), `compareProfiles()`, and `getFieldComparison()` (lazy-loaded FLS).
- **LWC Components** — The main app orchestrates the UI; `comparisonTable` is reused across five tabs; `objectSettingsTable` adds expandable FLS rows.

## Requirements

- Salesforce Lightning Experience
- API version 59.0+
- No external dependencies

## License

[MIT](LICENSE)
