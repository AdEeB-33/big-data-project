# Olist E-Commerce End-to-End Data Engineering Project

This project implements an end-to-end data engineering pipeline on the **Olist E-Commerce Dataset**, using a **Medallion Architecture** (Bronze → Silver → Gold) built on Microsoft Azure, Databricks, MongoDB, MySQL, and Tableau.

---

## 1. Architecture Overview

![Pipeline Architecture](architecture_diagram.png)

**Flow:** GitHub (CSV files) + SQL Server table → Azure Data Factory → ADLS Gen2 (Bronze) → Azure Databricks (transformation + MongoDB enrichment) → ADLS Gen2 (Silver) → Azure Synapse Analytics (Gold) → Tableau / Power BI / Fabric

### Entity Relationship Diagram

![Olist Dataset ERD](erd_diagram.png)

The Olist dataset is a relational set of CSV files linked by shared keys:

- `olist_orders_dataset` is the central table, linked to:
  - `olist_order_payments_dataset` via `order_id`
  - `olist_order_reviews_dataset` via `order_id`
  - `olist_order_items_dataset` via `order_id`
  - `olist_order_customer_dataset` via `customer_id`
- `olist_order_items_dataset` links to:
  - `olist_products_dataset` via `product_id`
  - `olist_sellers_dataset` via `seller_id`
- `olist_sellers_dataset` and `olist_order_customer_dataset` both link to `olist_geolocation_dataset` via `zip_code_prefix`

---

## 2. Tools Used

| Category | Tool |
|---|---|
| Orchestration | Azure Data Factory (ADF) |
| Storage / Lakehouse | Azure Data Lake Storage Gen2 (ADLS Gen2) |
| Data Processing / Compute | Azure Databricks (PySpark) |
| Data Warehousing | Azure Synapse Analytics (Serverless SQL Pool) |
| Databases | MongoDB & MySQL Server |
| Database Hosting | Filess.io |
| Visualization | Tableau (also supports Power BI / Fabric) |
| Source Control | GitHub |
| Scripting / Prototyping | Google Colab Notebook |

---

## 3. Step-by-Step Implementation

### Phase 1 — Data Source & Local Database Setup

1. Upload the complete Olist e-commerce dataset (CSV files) to a GitHub repository.
2. Set up database hosting on **Filess.io**, creating two databases:
   - A **MySQL** database
   - A **MongoDB** database
3. Using a Google Colab notebook, establish a connection to the MySQL database and load `olist_order_payments.csv` into it.


### Phase 2 — Azure Infrastructure Provisioning

1. Create a **Resource Group** to logically group all project resources.
2. Create an **Azure Data Factory** instance named `olist_data-factory-33`.
3. Create an **Azure Data Lake Storage Gen2** account:
   - Storage account name: `osltdatastorage`
   - Enable **Hierarchical Namespace** (required for ADLS Gen2 capabilities).
   - Inside it, create a container/root folder `olist data` with three subfolders implementing the Medallion Architecture:
     - `bronze/` — raw ingested data
     - `silver/` — cleaned/filtered data
     - `gold/` — business-level aggregated data

### Phase 3 — Data Ingestion Pipeline (Azure Data Factory)

1. **Linked Services:** In the *Manage* tab, create two Linked Services:
   - One for **GitHub** (HTTP source)
   - One for **SQL Server**
2. **Author → Lookup + ForEach pattern:**
   - Create a **Lookup activity** that reads a control file `foreachinput.json` from GitHub via the HTTP linked service. Its source dataset should be a JSON file, with the base URL pointing to the raw GitHub file and using a dynamic expression for the relative path.
   - Create a **ForEach activity**, set to **Sequential**, with its items expression set to `@activity('Lookup1').output.value`.
3. **Inside the ForEach loop:**
   - Add a **Copy Data** activity:
     - **Source:** GitHub linked service, with the base URL set, and the relative file path set dynamically via `@item().csv_relative_url`.
     - **Sink:** ADLS Gen2 linked service, pointing at the `bronze/` folder, with the file name set dynamically via `@item().file_name`.
4. **Outside the ForEach loop:** Add a separate **Copy Data** activity to pull the transaction table directly from the SQL Server source into the `bronze/` zone.
5. The `foreachinput.json` control file contains an array of objects, each with a `csv_relative_url` and `file_name` key/value pair — one per source CSV.

### Phase 4 — Data Transformation & Enrichment (Azure Databricks)

1. **App Registration:** Register an application in Microsoft Entra ID (Azure AD) to be used as a service principal.
2. **IAM Access:** On the `osltdatastorage` storage account, grant the app registration the **Storage Blob Data Contributor** role.
3. **Cluster & Mounting:** Create an Azure Databricks workspace and cluster, then mount ADLS Gen2 to the cluster using the app's client ID and client secret.
4. **Transformation workflow:**
   - Load `product_category_name_translation.csv` into the MongoDB database to act as an enrichment/lookup collection.
   - Read the raw CSV files from the `bronze/` folder into PySpark DataFrames.
   - Perform basic transformations: cleaning, renaming, filtering, deduplication.
   - **Enrichment:** Connect to the hosted MongoDB instance from PySpark and join the category-translation collection against the product data.
   - Perform aggregations as needed.
   - Write the cleaned, enriched output back to the `silver/` folder in ADLS Gen2.

### Phase 5 — Data Warehousing (Azure Synapse Analytics)

1. Create an **Azure Synapse Analytics** workspace, associating it with the `osltdatastorage` account.
2. Grant the Synapse workspace's managed identity **Storage Blob Data Contributor** access on the storage account (and retain access for yourself as well).
3. In **Synapse Studio**, using a **Serverless SQL Pool**:
   - Create a database, e.g. `olist_database`.
   - Write SQL scripts to create external tables/views pointing at the `silver/` layer.
   - Use these scripts to build the dimension and fact tables, writing final results back to the `gold/` folder.

### Phase 6 — Visualization (Tableau)

1. Open Tableau and connect using the **Microsoft Azure Synapse Analytics** connector.
2. Supply the **Serverless SQL Endpoint** URI from the Synapse workspace.
3. Model the dimension and fact tables, and build dashboards analyzing metrics such as shipment intervals and cross-region product/sales operations.

---

## 4. Notes

- Screenshots for each phase (MySQL/MongoDB data load, Azure Portal resource group, ADF pipeline canvas, Databricks notebook output, Synapse SQL scripts/external tables) should be added under the corresponding phase above.
- PySpark transformation and Synapse SQL script code snippets should be added as a code appendix or linked as separate `.py` / `.sql` files in the repository.
