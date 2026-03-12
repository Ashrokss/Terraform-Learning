# Azure Data Factory with Self-Hosted Integration Runtime (SHIR)

This Terraform code automatically sets up **Azure Data Factory** with a **self-hosted integration runtime** so you can move data between **on-premises sources** (like SQL Server in your datacenter) and **Azure** (like Blob Storage, SQL Database).

---

## What Problem Does This Solve?

**Azure Data Factory** moves and transforms data. By default, it can only reach **public** sources (Azure services, public URLs). It **cannot** reach data that lives in your own network—like SQL Server in your office or a file server behind your firewall.

The **Self-Hosted Integration Runtime (SHIR)** is a small piece of software that runs on **your** machine (VM or on-prem server). It acts as a **bridge**: it connects to your internal data sources and relays data to Azure Data Factory in the cloud.

This Terraform project builds that entire setup for you—**automatically**.

---

## What Does This Terraform Code Create?

### 1. **Shared Azure Data Factory** (`adf-pal-shared`)

- An Azure Data Factory instance—your main data integration service.
- A **Self-Hosted Integration Runtime** named `shir-on-prem`. This is the "definition" in Azure—the actual software runs on the VM.

Think of it as: *"Azure knows there is a gateway; the gateway software runs on the VM."*

---

### 2. **SHIR VM** (`vm-adf-shir`) – The Machine Running the Gateway

If `shir_vm` is configured in `terraform.tfvars`, the code creates:

| Resource | Purpose |
|----------|---------|
| **Virtual Network & Subnet** | Private network for the VM (e.g. 10.0.0.0/16) |
| **Windows Server 2022 VM** | Machine that hosts the gateway software |
| **Storage Account** | Holds a PowerShell script used during setup |
| **Custom Script Extension** | Installs the SHIR software on the VM and registers it with ADF |

**Flow:**
1. Terraform creates the VM.
2. A script is uploaded to storage.
3. The VM uses its managed identity to download the script.
4. The script downloads the official Microsoft SHIR installer, installs it, and registers the node with the shared ADF using an auth key.
5. The SHIR node appears in Azure as **Running**.

You **do not** need to install anything manually.

---

### 3. **Linked ADF** (`adf-pal-linked`) – Optional Second Data Factory

If you need **another** Data Factory (e.g. for dev/test) that uses the **same** gateway instead of running its own:

- A **linked ADF** is created.
- Its managed identity gets **Contributor** on the shared IR.
- A **linked IR** object points to the shared IR.

When you run pipelines in `adf-pal-linked`, they use the gateway in `adf-pal-shared`—no second VM or second installation.

Set `adf_linked = null` in `terraform.tfvars` if you only need one ADF.

---

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Azure Cloud                                  │
│                                                                      │
│  ┌──────────────────────┐         ┌──────────────────────────────┐  │
│  │  adf-pal-shared      │         │  adf-pal-linked (optional)   │  │
│  │  ┌────────────────┐  │         │  ┌────────────────────────┐   │  │
│  │  │ shir-on-prem    │◄─┼────────┼──│ linked-on-prem         │   │  │
│  │  │ (Shared IR)     │  │  link  │  │ (points to shared IR)  │   │  │
│  │  └────────┬───────┘  │         │  └────────────────────────┘   │  │
│  └───────────┼──────────┘         └──────────────────────────────┘  │
│              │                                                         │
│              │  auth key                                               │
│              ▼                                                         │
│  ┌──────────────────────┐                                            │
│  │  vm-adf-shir         │  ← Gateway software runs here               │
│  │  (Windows Server)    │                                            │
│  └──────────┬───────────┘                                            │
└─────────────┼────────────────────────────────────────────────────────┘
              │
              │  network (VPN, ExpressRoute, or same VNet)
              ▼
┌─────────────────────────────────────┐
│  On-premises data sources           │
│  (SQL Server, file shares, etc.)   │
└─────────────────────────────────────┘
```

---

## File Structure (What Each Part Does)

| File / Folder | What it does |
|---------------|--------------|
| `root/` | Root Terraform config—run `terraform` from this directory |
| `root/main.tf` | Uses existing resource group, calls the modules, wires everything together |
| `root/variables.tf` | Inputs: subscription, RG, tags, ADF names, VM password, etc. |
| `root/terraform.tfvars` | Your actual values (subscription, RG, passwords, etc.) |
| `modules/adf/` | Creates the shared ADF and the SHIR definition |
| `modules/shir-vm/` | Creates VNet, VM, storage, and runs the install script |
| `modules/adf-linked/` | Creates the linked ADF and linked IR (optional) |
| `scripts/gatewayInstall.ps1` | Installs the Microsoft SHIR and registers it with ADF |

---

## Configuration Options

| Scenario | `shir_vm` | `adf_linked` |
|---------|-----------|--------------|
| Full automation: shared ADF + VM + linked ADF | Set with `vm_admin_password` | Set |
| Shared ADF + VM only | Set with `vm_admin_password` | `null` |
| Use an existing on-prem machine for SHIR | `null` | `null` or set after manual registration |

---

## How to Use

1. **Prerequisites**
   - Terraform >= 1.5.0
   - Azure CLI: `az login`
   - An existing resource group (e.g. `Pal-RG`)

2. **Configure**
   - Copy `terraform.tfvars.example` to `terraform.tfvars` (or edit existing `terraform.tfvars`)
   - Set `costcentre`, `workload`, and `vm_admin_password` (or use `TF_VAR_shir_vm` for the password)

3. **Apply** (run from this `root` directory)
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Verify**
   - In Azure Portal → `adf-pal-shared` → Manage → Integration runtimes
   - `shir-on-prem` should show **Running** with at least one node

---

## Verifying SHIR Connectivity (Test Connection Only)

Use this method when you want to confirm the SHIR can reach a target **without** creating a pipeline or copying data.

### Prerequisites

- A SQL Server instance the SHIR VM can reach (same VNet, VPN, or on-prem with firewall rules)
- SQL authentication: username + password, or Windows auth (depending on your setup)
- If using the SHIR VM itself: install SQL Server (Express/Developer) on `vm-adf-shir` and enable TCP/IP on port 1433

---

### Step 1: Open the Data Factory

1. Go to **Azure Portal** → search for your Data Factory.
2. Use **adf-pal-shared** (if testing from the shared ADF) or **adf-pal-linked** (if using the linked IR).
3. Open the Data Factory resource.

---

### Step 2: Create a SQL Server Linked Service

1. In the left menu, click **Manage** (wrench icon).
2. Under **Connections**, click **Linked services**.
3. Click **+ New**.
4. In the search box, type **SQL Server**.
5. Select **SQL Server** from the list → **Continue**.

---

### Step 3: Configure the Linked Service

1. **Name**  
   Example: `linkedservice_test_sql`

2. **Description** (optional)  
   Example: `Test connection for SHIR`

3. **Connect via integration runtime**  
   - Shared ADF: select **shir-on-prem**  
   - Linked ADF: select **linked-on-prem**

4. **Server name**  
   - IP address or hostname of the SQL Server (e.g. `10.0.1.4` for same-VNet VM, or `yourserver.domain.com`)
   - Include instance if needed: `server\instancename`
   - Do **not** include `tcp:` or port unless you use a non-default port

5. **Database name**  
   - Any valid database (e.g. `master`, `TestDB`, or a real database name)

6. **Authentication type**  
   - **SQL Authentication**: User name + Password  
   - **Windows Authentication**: Use for domain accounts (less common in ADF)

7. **User name** (for SQL auth)  
   - SQL login (e.g. `sa` or a dedicated user)

8. **Password** (for SQL auth)  
   - Use **Azure Key Vault** (recommended) or enter directly
   - To use Key Vault: create a secret and reference it in the linked service

9. Leave other options at default unless your environment requires different settings.

---

### Step 4: Test the Connection

1. Click **Test connection** at the bottom of the form.
2. ADF sends a test request through the selected integration runtime (SHIR) to the SQL Server.
3. Wait a few seconds.

---

### Step 5: Interpret the Result

| Result | Meaning |
|--------|---------|
| **Succeeded** (green checkmark) | SHIR can reach the SQL Server. Network, firewall, and credentials are correct. |
| **Failed** | Check: SHIR node status, firewall/NSG rules, SQL Server TCP/IP, credentials, and server name. |

---

### Step 6: Save (Optional)

- If the test succeeded, click **Create** to save the linked service for later use.
- If you only wanted to test, you can cancel without saving.

---

### Troubleshooting a Failed Test

1. **Verify SHIR node is running**  
   - Manage → Integration runtimes → open **shir-on-prem** (or **linked-on-prem**) → Nodes tab  
   - At least one node should show **Running**

2. **Check network path**  
   - From the SHIR VM, run:  
     `Test-NetConnection -ComputerName <SQL_SERVER_IP> -Port 1433`  
   - Ensure port 1433 (or your custom port) is open

3. **Verify SQL Server configuration**  
   - SQL Server Configuration Manager → enable **TCP/IP**  
   - Restart SQL Server service  
   - Firewall on SQL host: allow inbound on 1433

4. **Verify credentials**  
   - Test login with SQL Server Management Studio from the SHIR VM  
   - Ensure the user has access to the specified database

---

## References

- [Terraforming ADF: Shared Self-Hosted IR](https://pl.seequality.net/terra-adf-shared/)
- [Terraforming ADF: SHIR setup & automation](https://pl.seequality.net/terra-adf-shir/)
- [Microsoft: Create self-hosted IR](https://learn.microsoft.com/en-us/azure/data-factory/create-self-hosted-integration-runtime)
