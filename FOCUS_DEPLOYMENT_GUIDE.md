# GCP FOCUS v1.0 BigQuery View Deployment Guide

## Overview

This guide provides step-by-step instructions for creating a FOCUS (FinOps Open Cost and Usage Specification) v1.0 compliant BigQuery view for your GCP billing data.

**Last Updated:** Based on FOCUS guide dated Aug 9, 2024
**Query Last Updated:** March 19, 2024

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Step 1: Enable Billing Exports](#step-1-enable-billing-exports)
3. [Step 2: Configure IAM Permissions](#step-2-configure-iam-permissions)
4. [Step 3: Create the FOCUS BigQuery View](#step-3-create-the-focus-bigquery-view)
5. [Step 4: Validate the View](#step-4-validate-the-view)
6. [Limitations and Notes](#limitations-and-notes)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before creating the FOCUS view, ensure you have:

- **GCP Project** with billing enabled
- **BigQuery API** enabled
- **Billing Account** access with appropriate permissions
- **Detailed Billing Export** enabled and populating data
- **Price Export** enabled and populating data

### Required Information

Collect the following information before proceeding:

1. **Billing Account ID**: Found in your billing export table name
   - Format: `gcp_billing_export_resource_v1_XXXXXX`
   - The `XXXXXX` is your billing account ID

2. **Detailed Billing Export Table Path**:
   - Format: `project.dataset.gcp_billing_export_resource_v1_ACCOUNT`
   - Example: `my-billing-project.billing_data.gcp_billing_export_resource_v1_012345`

3. **Price Export Table Path**:
   - Format: `project.dataset.cloud_pricing_export`
   - Example: `my-billing-project.billing_data.cloud_pricing_export`

4. **Price Export Reference Date**:
   - A date after you enabled price export (format: YYYY-MM-DD)
   - This determines which pricing data is used for list prices
   - Example: `2024-01-15`

---

## Step 1: Enable Billing Exports

### 1.1 Enable Detailed Billing Export

If not already enabled:

1. Go to [Cloud Console Billing](https://console.cloud.google.com/billing)
2. Select your billing account
3. Click **Billing export** in the left menu
4. Click **BigQuery export** tab
5. Under **Detailed usage cost**, click **EDIT SETTINGS**
6. Select or create a BigQuery dataset
7. Click **Save**

**Important Notes:**
- Data begins populating from the time you enable the export
- Initial data may take 24-48 hours to appear
- Historical data is not backfilled

### 1.2 Enable Price Export

1. From the same **BigQuery export** page
2. Under **Pricing**, click **EDIT SETTINGS**
3. Select the same BigQuery dataset (or a different one)
4. Click **Save**

**Important Notes:**
- Price export provides list pricing metadata
- Required for FOCUS fields: `ListUnitPrice` and `ServiceCategory`
- Price export is a point-in-time snapshot

---

## Step 2: Configure IAM Permissions

### 2.1 Required Permissions for View Creation

You need the following IAM permissions:

- `bigquery.tables.create` - To create the view
- `bigquery.tables.getData` - To query underlying tables
- `bigquery.datasets.create` - To create datasets (if needed)

### 2.2 Recommended IAM Roles

Grant one of these predefined roles:

- **BigQuery Data Editor** (`roles/bigquery.dataEditor`)
  - Includes all necessary permissions for view creation

- **BigQuery Admin** (`roles/bigquery.admin`)
  - Full BigQuery access (use cautiously)

### 2.3 Grant Permissions

```bash
# Grant BigQuery Data Editor role to a user
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:EMAIL" \
  --role="roles/bigquery.dataEditor"
```

Replace:
- `PROJECT_ID` - Your GCP project ID
- `EMAIL` - User email address

---

## Step 3: Create the FOCUS BigQuery View

### 3.1 Prepare the SQL Query

The FOCUS SQL query requires three parameters to be replaced:

1. **Detailed Billing Export Table Path** (appears 1 time)
2. **Price Export Table Path** (appears 1 time)
3. **Price Export Reference Date** (appears 1 time)
4. **Billing Account ID** (appears 2 times in the output)

### 3.2 SQL Query Template

Save this SQL query and replace the highlighted parameters:

**Parameters to Replace:**
- `project.dataset.gcp_billing_export_resource_v1_account` → Your detailed billing export table
- `project.dataset.cloud_pricing_export` → Your price export table
- `YYYY-MM-DD` → Your price reference date
- `TODO - replace with the billing account ID` → Your billing account ID (appears twice)

```sql
WITH
region_names AS (
  SELECT *
  FROM UNNEST([
    STRUCT<id STRING, name STRING>("africa-south1", "Johannesburg"),
    ("asia-east1", "Taiwan"),
    ("asia-east2", "Hong Kong"),
    ("asia-northeast1", "Tokyo"),
    ("asia-northeast2", "Osaka"),
    ("asia-northeast3", "Seoul"),
    ("asia-southeast1", "Singapore"),
    ("australia-southeast1", "Sydney"),
    ("australia-southeast2", "Melbourne"),
    ("europe-central2", "Warsaw"),
    ("europe-north1", "Finland"),
    ("europe-southwest1", "Madrid"),
    ("europe-west1", "Belgium"),
    ("europe-west2", "London"),
    ("europe-west3", "Frankfurt"),
    ("europe-west4", "Netherlands"),
    ("europe-west6", "Zurich"),
    ("europe-west8", "Milan"),
    ("europe-west9", "Paris"),
    ("europe-west10", "Berlin"),
    ("europe-west12", "Turin"),
    ("asia-south1", "Mumbai"),
    ("asia-south2", "Delhi"),
    ("asia-southeast2", "Jakarta"),
    ("me-central1", "Doha"),
    ("me-central2", "Dammam"),
    ("me-west1", "Tel Aviv"),
    ("northamerica-northeast1", "Montréal"),
    ("northamerica-northeast2", "Toronto"),
    ("us-central1", "Iowa"),
    ("us-east1", "South Carolina"),
    ("us-east4", "Northern Virginia"),
    ("us-east5", "Columbus"),
    ("us-south1", "Dallas"),
    ("us-west1", "Oregon"),
    ("us-west2", "Los Angeles"),
    ("us-west3", "Salt Lake City"),
    ("us-west4", "Las Vegas"),
    ("southamerica-east1", "São Paulo"),
    ("southamerica-west1", "Santiago")
  ])
),
usage_cost_data AS (
  SELECT
    *,
    (
      SELECT
        AS STRUCT type,
        id,
        full_name
      FROM
        UNNEST(credits)
      WHERE
        type IN UNNEST(["COMMITTED_USAGE_DISCOUNT", "COMMITTED_USAGE_DISCOUNT_DOLLAR_BASE"])
      LIMIT
        1) AS cud,
    ARRAY( ( (
      SELECT
        AS STRUCT key AS key,
        value AS value,
        "label" AS x_type,
        FALSE AS x_inherited,
        "n/a" AS x_namespace
      FROM
        UNNEST(labels))
    UNION ALL (
      SELECT
        AS STRUCT key AS key,
        value AS value,
        "system_label" AS x_type,
        FALSE AS x_inherited,
        "n/a" AS x_namespace
      FROM
        UNNEST(system_labels))
    UNION ALL (
      SELECT
        AS STRUCT key AS key,
        value AS value,
        "project_label" AS x_type,
        TRUE AS x_inherited,
        "n/a" AS x_namespace
      FROM
        UNNEST(project.labels))
    UNION ALL (
      SELECT
        AS STRUCT key AS key,
        value AS value,
        "tag" AS x_type,
        inherited AS x_inherited,
        namespace AS x_namespace
      FROM
        UNNEST(tags) ) )) AS focus_tags,
  FROM
    `project.dataset.gcp_billing_export_resource_v1_account`),
    -- TODO - replace with your detailed usage export table path
prices AS (
  SELECT
    *,
    flattened_prices
  FROM
    `project.dataset.cloud_pricing_export`,
    -- TODO - replace with your pricing export table path
    UNNEST(list_price.tiered_rates) AS flattened_prices
  WHERE
    DATE(export_time) = 'YYYY-MM-DD')
    -- TODO - replace with a date after you enabled pricing export to use pricing data as of this date
SELECT
  usage_cost_data.location.zone AS AvailabilityZone,
  CAST(usage_cost_data.cost AS NUMERIC) + IFNULL((
    SELECT
      SUM(CAST(c.amount AS NUMERIC))
    FROM
      UNNEST(usage_cost_data.credits) AS c), 0) AS BilledCost,
  "TODO - replace with the billing account ID in your detailed usage export table name" AS BillingAccountId,
  usage_cost_data.currency AS BillingCurrency,
  PARSE_TIMESTAMP("%Y%m", invoice.month, "America/Los_Angeles") AS BillingPeriodStart,
  TIMESTAMP(DATE_SUB(DATE_ADD(PARSE_DATE("%Y%m", invoice.month), INTERVAL 1 MONTH), INTERVAL 1 DAY),
    "America/Los_Angeles") AS BillingPeriodEnd,
  CASE LOWER(cost_type)
    WHEN "regular" THEN "usage"
    WHEN "tax" THEN "tax"
    WHEN "rounding_error" then "adjustment"
    WHEN "adjustment" then "adjustment"
    ELSE "error"
  END AS ChargeCategory,
  IF(
    COALESCE(
      usage_cost_data.adjustment_info.id,
      usage_cost_data.adjustment_info.description,
      usage_cost_data.adjustment_info.type,
      usage_cost_data.adjustment_info.mode)
    IS NOT NULL,
    "correction",
    NULL) AS ChargeClass,
  usage_cost_data.sku.description AS ChargeDescription,
  usage_cost_data.usage_start_time AS ChargePeriodStart,
  usage_cost_data.usage_end_time AS ChargePeriodEnd,
  CASE usage_cost_data.cud.type
    WHEN "COMMITTED_USAGE_DISCOUNT_DOLLAR_BASE" THEN "Spend"
    WHEN "COMMITTED_USAGE_DISCOUNT" THEN "Usage"
  END AS CommitmentDiscountCategory,
  usage_cost_data.subscription.instance_id AS CommitmentDiscountId,
  usage_cost_data.cud.full_name AS CommitmentDiscountName,
  IF(usage_cost_data.cost_type = "regular", CAST(usage_cost_data.usage.amount AS NUMERIC), NULL) AS
    ConsumedQuantity,
  IF(usage_cost_data.cost_type = "regular", usage_cost_data.usage.unit, NULL) AS ConsumedUnit,
  CAST(usage_cost_data.cost AS NUMERIC) AS ContractedCost,
  CAST(usage_cost_data.price.effective_price AS NUMERIC) AS ContractedUnitPrice,
  CAST(usage_cost_data.cost AS NUMERIC) + IFNULL((
    SELECT
      SUM(CAST(c.amount AS NUMERIC))
    FROM
      UNNEST(usage_cost_data.credits) AS c), 0) AS EffectiveCost,
  CAST(usage_cost_data.cost_at_list AS NUMERIC) AS ListCost,
  IF(usage_cost_data.cost_type = "regular", CAST(prices.flattened_prices.account_currency_amount AS NUMERIC), NULL
    ) AS ListUnitPrice,
  IF(
    usage_cost_data.cost_type = "regular",
    IF(
      LOWER(usage_cost_data.sku.description) LIKE "commitment%" OR usage_cost_data.cud IS NOT NULL,
      "committed",
      "standard"),
    null) AS PricingCategory,
  IF(usage_cost_data.cost_type = "regular", usage_cost_data.price.pricing_unit_quantity, NULL) AS PricingQuantity,
  IF(usage_cost_data.cost_type = "regular", usage_cost_data.price.unit, NULL) AS PricingUnit,
  "Google Cloud" AS ProviderName,
  IF(usage_cost_data.transaction_type = "GOOGLE", "Google Cloud", usage_cost_data.seller_name) AS PublisherName,
  usage_cost_data.location.region AS RegionId,
  (
    SELECT
      name
    FROM
      region_names
    WHERE
      id = usage_cost_data.location.region) AS RegionName,
  usage_cost_data.resource.global_name AS ResourceId,
  usage_cost_data.resource.name AS ResourceName,
  IF(
    STARTS_WITH( usage_cost_data.resource.global_name, '//'),
    REGEXP_REPLACE(
      usage_cost_data.resource.global_name,
      '(//)|(googleapis.com/)|(projects/[^/]+/)|(project_commitments/[^/]+/)|(locations/[^/]+/)|(regions/[^/]+/)|(zones/[^/]+/)|(global/)|(/[^/]+)',
      ''),
    NULL) AS ResourceType,
  prices.product_taxonomy AS ServiceCategory,
  usage_cost_data.service.description AS ServiceName,
  IF(usage_cost_data.cost_type = "regular", usage_cost_data.sku.id, NULL) AS SkuId,
  IF(
    usage_cost_data.cost_type = "regular",
    CONCAT(
      "Billing Account ID:", usage_cost_data.billing_account_id,
      ", SKU ID: ", usage_cost_data.sku.id,
      ", Price Tier Start Amount: ", price.tier_start_amount),
    NULL) AS SkuPriceId,
  usage_cost_data.billing_account_id as SubAccountId,
  usage_cost_data.focus_tags AS Tags,
  ARRAY((
    SELECT
      AS STRUCT name AS Name,
      CAST(amount AS NUMERIC) AS Amount,
      full_name AS FullName,
      id AS Id,
      type AS Type
    FROM
      UNNEST(usage_cost_data.credits))) AS x_Credits,
  usage_cost_data.cost_type AS x_CostType,
  CAST(usage_cost_data.currency_conversion_rate AS NUMERIC) AS x_CurrencyConversionRate,
  usage_cost_data.export_time AS x_ExportTime,
  usage_cost_data.location.location AS x_Location,
  (
    SELECT
      AS STRUCT usage_cost_data.project.id,
      usage_cost_data.project.number,
      usage_cost_data.project.name,
      usage_cost_data.project.ancestry_numbers,
      usage_cost_data.project.ancestors) AS x_Project,
  usage_cost_data.service.id AS x_ServiceId
FROM
  usage_cost_data
LEFT JOIN
  prices
ON
  usage_cost_data.sku.id = prices.sku.id
  AND usage_cost_data.price.tier_start_amount = prices.flattened_prices.start_usage_amount;
```

### 3.3 Example with Parameters Replaced

Here's an example with fictional values:

```sql
-- Example parameters:
-- Billing Account: 012345-ABCDEF-6789GH
-- Billing Project: my-billing-project
-- Dataset: billing_exports
-- Price Reference Date: 2024-01-15

-- In the query, you would replace:
-- `project.dataset.gcp_billing_export_resource_v1_account`
-- WITH: `my-billing-project.billing_exports.gcp_billing_export_resource_v1_012345_ABCDEF_6789GH`

-- `project.dataset.cloud_pricing_export`
-- WITH: `my-billing-project.billing_exports.cloud_pricing_export`

-- 'YYYY-MM-DD'
-- WITH: '2024-01-15'

-- "TODO - replace with the billing account ID..."
-- WITH: "012345-ABCDEF-6789GH"
```

### 3.4 Create the View Using Cloud Console

1. Navigate to [BigQuery Console](https://console.cloud.google.com/bigquery)
2. Click **Compose new query**
3. Paste your modified SQL query (with parameters replaced)
4. Click **Run** to validate the query executes successfully
5. Once validated, click **Save view** above the results
6. Configure the view:
   - **Project name**: Select your project
   - **Dataset name**: Select or create a dataset
   - **Table name**: Enter a name (e.g., `focus_v1_0`)
7. Click **Save**

### 3.5 Create the View Using bq Command Line

```bash
# Set variables
PROJECT_ID="my-billing-project"
DATASET_ID="billing_exports"
VIEW_NAME="focus_v1_0"
SQL_FILE="focus_view.sql"

# Create the view
bq mk \
  --use_legacy_sql=false \
  --view "$(cat $SQL_FILE)" \
  --project_id=$PROJECT_ID \
  $DATASET_ID.$VIEW_NAME
```

### 3.6 Create the View Using Terraform

```hcl
resource "google_bigquery_table" "focus_view" {
  project    = "my-billing-project"
  dataset_id = "billing_exports"
  table_id   = "focus_v1_0"

  view {
    query          = file("${path.module}/focus_view.sql")
    use_legacy_sql = false
  }

  description = "FOCUS v1.0 compliant view of GCP billing data"

  labels = {
    standard = "focus"
    version  = "v1-0"
  }
}
```

---

## Step 4: Validate the View

### 4.1 Basic Row Count Check

```sql
SELECT COUNT(*) as total_rows
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) = CURRENT_DATE() - 1;
```

Expected: Should return rows if you have usage from yesterday

### 4.2 Cost Reconciliation

```sql
-- Compare FOCUS view costs with source billing table
WITH focus_costs AS (
  SELECT
    DATE(ChargePeriodStart) as usage_date,
    SUM(BilledCost) as focus_billed_cost,
    SUM(EffectiveCost) as focus_effective_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAYS)
  GROUP BY usage_date
),
source_costs AS (
  SELECT
    DATE(usage_start_time) as usage_date,
    SUM(cost) as source_cost,
    SUM(cost) + SUM((SELECT SUM(amount) FROM UNNEST(credits))) as source_effective_cost
  FROM `your-project.your-dataset.gcp_billing_export_resource_v1_ACCOUNT`
  WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAYS)
  GROUP BY usage_date
)
SELECT
  f.usage_date,
  f.focus_billed_cost,
  s.source_cost,
  f.focus_billed_cost - s.source_cost as cost_difference,
  f.focus_effective_cost,
  s.source_effective_cost
FROM focus_costs f
JOIN source_costs s USING (usage_date)
ORDER BY usage_date DESC;
```

Expected: Differences should be minimal (rounding differences only)

### 4.3 Check Field Population

```sql
-- Verify key FOCUS fields are populated
SELECT
  COUNT(*) as total_rows,
  COUNT(DISTINCT BillingAccountId) as billing_accounts,
  COUNT(DISTINCT ServiceName) as services,
  COUNT(DISTINCT RegionId) as regions,
  SUM(CASE WHEN EffectiveCost IS NULL THEN 1 ELSE 0 END) as null_effective_cost,
  SUM(CASE WHEN ChargeCategory IS NULL THEN 1 ELSE 0 END) as null_charge_category
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) = CURRENT_DATE() - 1;
```

Expected:
- `null_effective_cost` should be 0
- `null_charge_category` should be 0

### 4.4 Sample Data Review

```sql
-- View sample records
SELECT
  ChargePeriodStart,
  ServiceName,
  ChargeDescription,
  EffectiveCost,
  BilledCost,
  ChargeCategory,
  PricingCategory
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) = CURRENT_DATE() - 1
LIMIT 10;
```

---

## Limitations and Notes

### Known Limitations (from Google)

1. **ChargeCategory Values**:
   - GCP only uses: "usage", "tax", "adjustment"
   - Does NOT distinguish between "usage" and "purchase"
   - "credit" values appear on line items they're applied to

2. **Cost Columns**:
   - All cost columns include what FOCUS considers "purchases"
   - GCP classifies purchases under "usage"

3. **Commitment Amortization**:
   - GCP amortizes commitments by time
   - EffectiveCost = cost + credits (simplified calculation)
   - Does not "move" cost from commitment fee SKU to usage

4. **Billing vs Sub-Account**:
   - `BillingAccountId`: Account in table name (parent/reseller for resellers)
   - `SubAccountId`: Account usage is associated with

5. **Unsupported Features**:
   - PricingCategory does not support "dynamic" value
   - ServiceCategory uses GCP taxonomy (not official FOCUS values yet)

6. **Resource Information**:
   - Available for most, but not all usage
   - Some SKUs may not have ResourceId/ResourceName/ResourceType

7. **ChargeClass**:
   - Value "correction" applies to ALL adjustments
   - Not only adjustments to previous invoices

8. **CommitmentDiscountId**:
   - Not always present
   - Currently supports CUD fee breakdown
   - More features coming

9. **Price Export Fields**:
   - `ListUnitPrice` and `ServiceCategory` use price as of reference date
   - Not as of actual usage date
   - These fields change infrequently

### View Characteristics

- **Storage Cost**: Zero (virtual view, no data storage)
- **Query Cost**: Standard BigQuery query pricing applies
- **Update Frequency**: Real-time (reflects source table updates)
- **Data Latency**: Same as source billing export (typically 24 hours)

---

## Troubleshooting

### Error: "Not found: Table"

**Cause**: Incorrect table path or table doesn't exist

**Solution**:
1. Verify billing exports are enabled and populated
2. Check table paths in BigQuery console
3. Ensure correct project/dataset/table names in query

### Error: "Access Denied"

**Cause**: Insufficient IAM permissions

**Solution**:
1. Verify you have `bigquery.tables.create` permission
2. Verify you have `bigquery.tables.getData` on source tables
3. Check both view destination and source tables are accessible

### Error: "Syntax error: Expected end of input but got keyword SELECT"

**Cause**: Missing semicolon or SQL syntax issue

**Solution**:
1. Ensure query uses Standard SQL (not Legacy SQL)
2. Validate query in BigQuery console first
3. Check for typos in parameter replacement

### View Returns Zero Rows

**Cause**: Multiple possible issues

**Solution**:
1. Check if source tables have data:
   ```sql
   SELECT COUNT(*) FROM `your-billing-table` WHERE DATE(usage_start_time) >= CURRENT_DATE() - 7;
   ```
2. Verify price export has data:
   ```sql
   SELECT COUNT(*) FROM `your-price-table` WHERE DATE(export_time) = 'YOUR-REFERENCE-DATE';
   ```
3. Check if LEFT JOIN to prices is causing issues (prices may be empty)

### Price Fields Are NULL

**Cause**: Price export not enabled or empty at reference date

**Solution**:
1. Verify price export is enabled and populated
2. Choose a more recent reference date
3. Query price export directly to verify data exists

### High Query Costs

**Cause**: View scans large billing tables on each query

**Solution**:
1. Use WHERE clauses to filter date ranges
2. Consider creating a materialized view:
   ```sql
   CREATE MATERIALIZED VIEW `project.dataset.focus_v1_0_materialized`
   AS SELECT * FROM `project.dataset.focus_v1_0`;
   ```
3. Partition the materialized view by date

### View Update Required

**Cause**: Google released new FOCUS query version

**Solution**:
1. Download updated query from Google's documentation
2. Test in development environment
3. Update view using:
   ```bash
   bq update --view "$(cat new_query.sql)" project.dataset.focus_v1_0
   ```

---

## Additional Resources

- [FOCUS Specification](https://focus.finops.org/)
- [GCP Billing Export Documentation](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
- [BigQuery Views Documentation](https://cloud.google.com/bigquery/docs/views)
- [GCP FOCUS Looker Template](https://github.com/looker-open-source/google_cloud_focus)

---

## Maintenance Checklist

- [ ] Monitor for new FOCUS query versions from Google
- [ ] Validate view data quality monthly
- [ ] Review query performance and costs
- [ ] Update reference date in price export query periodically
- [ ] Document any customizations to the query
- [ ] Test view updates in non-production first

---

## Change History

| Date | Version | Description |
|------|---------|-------------|
| 2024-10-24 | 1.0 | Initial deployment guide created |

