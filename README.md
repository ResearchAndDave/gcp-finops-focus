# GCP FOCUS v1.0 Implementation

This repository contains SQL queries and documentation for implementing FOCUS (FinOps Open Cost and Usage Specification) v1.0 for Google Cloud Platform billing data.

## Files Overview

### Core SQL Files

1. **`focus_view.sql`** - Google's official FOCUS v1.0 BigQuery view template
   - Based on Google's template from March 19, 2024
   - Implements FOCUS v1.0 GA specification
   - **Note**: Both `BilledCost` and `EffectiveCost` include credits (Google's implementation choice)
   - Use this for standard Google-compliant implementation

2. **`focus_view_modified.sql`** - Modified FOCUS view with corrected BilledCost calculation
   - **Modification**: `BilledCost` excludes credits (invoiced amount before discounts)
   - **Unchanged**: `EffectiveCost` includes credits (actual amount paid)
   - Better aligns with FOCUS specification semantics
   - Use this if you need BilledCost to represent pre-discount amounts

### Documentation

3. **`FOCUS_DEPLOYMENT_GUIDE.md`** - Complete deployment guide
   - Prerequisites and setup instructions
   - Step-by-step deployment process
   - Validation procedures
   - Troubleshooting guide
   - Limitations and known issues

### Validation & Diagnostics

4. **`validate_focus_view.sql`** - 15 comprehensive validation queries
   - Row count checks
   - Cost reconciliation
   - Field population verification
   - Data quality checks
   - Performance testing

5. **`diagnose_cost_discrepancy.sql`** - Diagnostic queries for cost analysis
   - Credit distribution analysis
   - Cost calculation comparisons
   - Sample data inspection
   - Cost type breakdown

### FinOps Use Cases

6. **`focus_use_cases_queries.sql`** - 20 production-ready FOCUS queries
   - Total cloud spend overview
   - Cost by service and region
   - Commitment savings analysis
   - Tag-based cost allocation
   - Cost anomaly detection
   - Month-over-month growth
   - Budget tracking
   - And 13 more common FinOps use cases

7. **`focus_forecasting_queries.sql`** - 10 comprehensive forecasting queries
   - Linear trend forecasts (3-month projections)
   - Service-level forecasting with confidence intervals
   - Seasonality-adjusted predictions
   - Commitment expiration impact analysis
   - Growth rate projections by service
   - Resource-based capacity forecasting
   - Budget runway analysis
   - Team/project-level forecasts
   - Quarterly variance analysis
   - ML-ready dataset export for advanced forecasting

## Quick Start

### Prerequisites

1. Enable **Detailed Billing Export** to BigQuery
2. Enable **Price Export** to BigQuery
3. Have appropriate IAM permissions (`roles/bigquery.dataEditor`)

### Deploy Standard View (Google's Template)

```bash
# 1. Edit focus_view.sql and replace these parameters:
#    - Detailed billing export table path (line 117)
#    - Price export table path (line 124)
#    - Price reference date (line 128)
#    - Billing account ID (line 132)

# 2. Create the view using bq CLI
bq mk \
  --use_legacy_sql=false \
  --view "$(cat focus_view.sql)" \
  --project_id=YOUR_PROJECT_ID \
  YOUR_DATASET.focus_v1_0

# 3. Validate the view
# Run queries from validate_focus_view.sql
```

### Deploy Modified View (Corrected BilledCost)

```bash
# Use focus_view_modified.sql instead
bq mk \
  --use_legacy_sql=false \
  --view "$(cat focus_view_modified.sql)" \
  --project_id=YOUR_PROJECT_ID \
  YOUR_DATASET.focus_v1_0_modified
```

## Key Differences: Standard vs Modified

| Metric | Standard (Google) | Modified | FOCUS Spec |
|--------|------------------|----------|------------|
| **BilledCost** | cost + credits | cost | cost (before discounts) |
| **EffectiveCost** | cost + credits | cost + credits | cost + credits (after discounts) |
| **Use Case** | Google-compliant | FOCUS-compliant | Specification |

### Which One Should You Use?

**Use Standard (`focus_view.sql`) if:**
- You want to follow Google's official implementation
- You only care about effective costs (actual spend)
- You're okay with BilledCost = EffectiveCost

**Use Modified (`focus_view_modified.sql`) if:**
- You need to see savings from credits/discounts
- You want BilledCost to show pre-discount amounts
- You need to calculate discount percentages
- You're integrating with tools that expect standard FOCUS semantics

## Understanding the Cost Discrepancy

When running the cost reconciliation query, you may see:

```
Date         BilledCost  SourceCost  Difference
2024-10-24   0.34        0.50        -0.16
```

**With Google's Standard View:**
- `BilledCost` = 0.34 (includes -$0.16 in credits)
- This is $0.16 less than the source cost
- This is **expected behavior** in Google's implementation

**With Modified View:**
- `BilledCost` = 0.50 (excludes credits)
- `EffectiveCost` = 0.34 (includes credits)
- Difference = 0.0 (perfect reconciliation)
- You can see $0.16 in savings (BilledCost - EffectiveCost)

## Validation

After deploying, run validation queries:

```sql
-- 1. Basic validation - should return recent data
SELECT COUNT(*) as total_rows
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- 2. Cost reconciliation - check for discrepancies
-- Run query #2 from validate_focus_view.sql

-- 3. Check if BilledCost includes credits (Standard view)
SELECT
  DATE(ChargePeriodStart) as usage_date,
  ROUND(SUM(BilledCost), 2) as billed_cost,
  ROUND(SUM(EffectiveCost), 2) as effective_cost,
  ROUND(SUM(BilledCost) - SUM(EffectiveCost), 2) as difference
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY usage_date
ORDER BY usage_date DESC;

-- Standard view: difference = 0.0
-- Modified view: difference > 0 (shows credit savings)
```

## Known Limitations (From Google)

1. **ChargeCategory**: Only "usage", "tax", "adjustment" (no "purchase" or "credit")
2. **Credits**: Applied to line items rather than separate rows
3. **Commitment Amortization**: Distributed over time with usage
4. **ServiceCategory**: Uses GCP taxonomy (not standard FOCUS values yet)
5. **Price Fields**: Use reference date pricing (not usage date pricing)

See `FOCUS_DEPLOYMENT_GUIDE.md` for complete limitations list.

## Maintenance

- [ ] Check for FOCUS query updates from Google quarterly
- [ ] Validate data quality monthly
- [ ] Review cost reconciliation weekly
- [ ] Update price reference date periodically (every 6 months)
- [ ] Monitor query performance

## Troubleshooting

### View returns zero rows
- Check if billing exports are populated
- Verify price export has data at reference date
- Ensure table paths are correct

### Cost discrepancies
- Run `diagnose_cost_discrepancy.sql` to analyze
- Check if credits are being applied
- Consider using modified view

### High query costs
- Add WHERE clauses with date filters
- Consider creating materialized view
- Partition by date for large datasets

## Resources

- [FOCUS Specification](https://focus.finops.org/)
- [GCP Billing Export Docs](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
- [BigQuery Views Docs](https://cloud.google.com/bigquery/docs/views)
- [GCP FOCUS Looker Template](https://github.com/looker-open-source/google_cloud_focus)
- [Original PDF Guide](focus_guide_v1.pdf)

