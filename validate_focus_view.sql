-- FOCUS View Validation Queries
-- Use these queries to validate your FOCUS view after deployment
-- Replace `your-project.your-dataset.focus_v1_0` with your actual view path

-- ============================================================================
-- 1. BASIC ROW COUNT CHECK
-- ============================================================================
-- Verify view returns data for recent dates
SELECT
  DATE(ChargePeriodStart) as usage_date,
  COUNT(*) as total_rows,
  SUM(EffectiveCost) as total_effective_cost
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY usage_date
ORDER BY usage_date DESC;

-- Expected: Should show rows for each day with non-zero costs


-- ============================================================================
-- 2. COST RECONCILIATION
-- ============================================================================
-- Compare FOCUS view costs with source billing table
-- This ensures the transformation preserved cost accuracy
WITH focus_costs AS (
  SELECT
    DATE(ChargePeriodStart) as usage_date,
    SUM(BilledCost) as focus_billed_cost,
    SUM(EffectiveCost) as focus_effective_cost,
    SUM(ContractedCost) as focus_contracted_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  GROUP BY usage_date
),
source_costs AS (
  SELECT
    DATE(usage_start_time) as usage_date,
    SUM(cost) as source_cost,
    SUM(cost) + IFNULL(SUM((SELECT SUM(amount) FROM UNNEST(credits))), 0) as source_effective_cost
  FROM `your-project.your-dataset.gcp_billing_export_resource_v1_ACCOUNT`
  WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  GROUP BY usage_date
)
SELECT
  COALESCE(f.usage_date, s.usage_date) as usage_date,
  ROUND(f.focus_billed_cost, 2) as focus_billed_cost,
  ROUND(s.source_cost, 2) as source_cost,
  ROUND(f.focus_billed_cost - s.source_cost, 4) as cost_difference,
  ROUND(f.focus_effective_cost, 2) as focus_effective_cost,
  ROUND(s.source_effective_cost, 2) as source_effective_cost,
  ROUND(f.focus_effective_cost - s.source_effective_cost, 4) as effective_cost_difference
FROM focus_costs f
FULL OUTER JOIN source_costs s USING (usage_date)
ORDER BY usage_date DESC;

-- Expected: cost_difference and effective_cost_difference should be < $0.01 (rounding only)


-- ============================================================================
-- 3. FIELD POPULATION CHECK
-- ============================================================================
-- Verify key FOCUS fields are populated correctly
SELECT
  COUNT(*) as total_rows,

  -- Key identifiers
  COUNT(DISTINCT BillingAccountId) as billing_accounts,
  COUNT(DISTINCT ServiceName) as services,
  COUNT(DISTINCT RegionId) as regions,
  COUNT(DISTINCT ResourceId) as resources,

  -- Cost fields (should never be NULL for usage records)
  SUM(CASE WHEN EffectiveCost IS NULL THEN 1 ELSE 0 END) as null_effective_cost,
  SUM(CASE WHEN BilledCost IS NULL THEN 1 ELSE 0 END) as null_billed_cost,
  SUM(CASE WHEN ContractedCost IS NULL THEN 1 ELSE 0 END) as null_contracted_cost,

  -- Required fields
  SUM(CASE WHEN ChargeCategory IS NULL THEN 1 ELSE 0 END) as null_charge_category,
  SUM(CASE WHEN BillingCurrency IS NULL THEN 1 ELSE 0 END) as null_currency,
  SUM(CASE WHEN ProviderName IS NULL THEN 1 ELSE 0 END) as null_provider,

  -- Date fields
  SUM(CASE WHEN ChargePeriodStart IS NULL THEN 1 ELSE 0 END) as null_charge_start,
  SUM(CASE WHEN ChargePeriodEnd IS NULL THEN 1 ELSE 0 END) as null_charge_end,
  SUM(CASE WHEN BillingPeriodStart IS NULL THEN 1 ELSE 0 END) as null_billing_start,

  -- Pricing fields (only NULL for non-usage charges)
  SUM(CASE WHEN ConsumedQuantity IS NULL AND ChargeCategory = 'usage' THEN 1 ELSE 0 END) as null_consumed_qty,
  SUM(CASE WHEN PricingCategory IS NULL AND ChargeCategory = 'usage' THEN 1 ELSE 0 END) as null_pricing_category

FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY);

-- Expected: All null counts should be 0 except possibly null_consumed_qty for some SKUs


-- ============================================================================
-- 4. CHARGE CATEGORY DISTRIBUTION
-- ============================================================================
-- Verify charge categories are being classified correctly
SELECT
  ChargeCategory,
  COUNT(*) as row_count,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(AVG(EffectiveCost), 4) as avg_cost,
  COUNT(DISTINCT ServiceName) as distinct_services
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY ChargeCategory
ORDER BY total_cost DESC;

-- Expected: Should see "usage", "tax", possibly "adjustment"
-- "usage" should have the highest cost


-- ============================================================================
-- 5. PRICING CATEGORY DISTRIBUTION
-- ============================================================================
-- Verify pricing categories (standard vs committed)
SELECT
  PricingCategory,
  COUNT(*) as row_count,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(SUM(BilledCost), 2) as billed_cost,
  ROUND(SUM(EffectiveCost) - SUM(BilledCost), 2) as savings
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND ChargeCategory = 'usage'
GROUP BY PricingCategory
ORDER BY total_cost DESC;

-- Expected: Should see "standard" and possibly "committed" if you have commitments


-- ============================================================================
-- 6. TOP SERVICES BY COST
-- ============================================================================
-- Identify highest cost services
SELECT
  ServiceName,
  COUNT(*) as row_count,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(SUM(BilledCost), 2) as billed_cost,
  COUNT(DISTINCT RegionId) as regions_used,
  COUNT(DISTINCT DATE(ChargePeriodStart)) as days_with_usage
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND ChargeCategory = 'usage'
GROUP BY ServiceName
ORDER BY total_cost DESC
LIMIT 10;

-- Expected: Should show your top GCP services (Compute Engine, BigQuery, etc.)


-- ============================================================================
-- 7. REGION DISTRIBUTION
-- ============================================================================
-- Verify region names are mapped correctly
SELECT
  RegionId,
  RegionName,
  COUNT(*) as row_count,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  COUNT(DISTINCT ServiceName) as distinct_services
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND RegionId IS NOT NULL
GROUP BY RegionId, RegionName
ORDER BY total_cost DESC
LIMIT 10;

-- Expected: RegionName should be populated for known regions
-- Should see your most used GCP regions


-- ============================================================================
-- 8. SAMPLE RECORDS REVIEW
-- ============================================================================
-- View sample records to verify data looks correct
SELECT
  DATE(ChargePeriodStart) as usage_date,
  ServiceName,
  ChargeDescription,
  RegionName,
  ROUND(ConsumedQuantity, 2) as consumed_qty,
  ConsumedUnit,
  ROUND(EffectiveCost, 4) as effective_cost,
  ROUND(BilledCost, 4) as billed_cost,
  ChargeCategory,
  PricingCategory
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) = DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  AND EffectiveCost > 1  -- Filter to significant costs
ORDER BY EffectiveCost DESC
LIMIT 20;

-- Expected: Data should look reasonable and match your GCP usage


-- ============================================================================
-- 9. COMMITMENT DISCOUNT VALIDATION
-- ============================================================================
-- Verify commitment discount fields are populated (if applicable)
SELECT
  CommitmentDiscountCategory,
  COUNT(*) as row_count,
  COUNT(DISTINCT CommitmentDiscountId) as distinct_commitments,
  COUNT(DISTINCT CommitmentDiscountName) as distinct_commitment_names,
  ROUND(SUM(EffectiveCost), 2) as total_cost
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND CommitmentDiscountCategory IS NOT NULL
GROUP BY CommitmentDiscountCategory
ORDER BY total_cost DESC;

-- Expected: If you have CUDs, should show "Spend" and/or "Usage" categories


-- ============================================================================
-- 10. CREDITS BREAKDOWN
-- ============================================================================
-- Analyze credits applied to your charges
SELECT
  DATE(ChargePeriodStart) as usage_date,
  credit.Type as credit_type,
  COUNT(*) as row_count,
  ROUND(SUM(credit.Amount), 2) as total_credit_amount,
  COUNT(DISTINCT ServiceName) as services_with_credits
FROM `your-project.your-dataset.focus_v1_0`,
  UNNEST(x_Credits) as credit
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY usage_date, credit_type
ORDER BY usage_date DESC, total_credit_amount;

-- Expected: Should show credit types like SUSTAINED_USAGE_DISCOUNT, PROMOTIONAL, etc.


-- ============================================================================
-- 11. TAGS VALIDATION
-- ============================================================================
-- Verify tags/labels are being captured
SELECT
  tag.x_type as tag_type,
  COUNT(*) as row_count,
  COUNT(DISTINCT tag.key) as distinct_keys,
  ROUND(SUM(EffectiveCost), 2) as tagged_cost
FROM `your-project.your-dataset.focus_v1_0`,
  UNNEST(Tags) as tag
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY tag_type
ORDER BY tagged_cost DESC;

-- Expected: Should see "label", "system_label", "project_label", and possibly "tag"


-- ============================================================================
-- 12. DATA FRESHNESS CHECK
-- ============================================================================
-- Verify the view has recent data
SELECT
  MAX(DATE(ChargePeriodStart)) as latest_usage_date,
  MAX(x_ExportTime) as latest_export_time,
  DATE_DIFF(CURRENT_DATE(), MAX(DATE(ChargePeriodStart)), DAY) as days_lag,
  COUNT(*) as total_rows_last_30_days
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY);

-- Expected: days_lag should be 1-2 (typical GCP billing export delay)


-- ============================================================================
-- 13. RESOURCE TYPE VALIDATION
-- ============================================================================
-- Check resource type extraction
SELECT
  ResourceType,
  COUNT(*) as row_count,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  COUNT(DISTINCT ServiceName) as services
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND ResourceType IS NOT NULL
GROUP BY ResourceType
ORDER BY total_cost DESC
LIMIT 20;

-- Expected: Should show resource types like "instances", "disks", "datasets", etc.


-- ============================================================================
-- 14. CURRENCY VALIDATION
-- ============================================================================
-- Verify billing currency is consistent
SELECT
  BillingCurrency,
  COUNT(*) as row_count,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  MIN(DATE(ChargePeriodStart)) as earliest_date,
  MAX(DATE(ChargePeriodStart)) as latest_date
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
GROUP BY BillingCurrency
ORDER BY total_cost DESC;

-- Expected: Should typically see one currency (USD, EUR, etc.)


-- ============================================================================
-- 15. PERFORMANCE TEST
-- ============================================================================
-- Test query performance on the view
SELECT
  ServiceName,
  DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
  ROUND(SUM(EffectiveCost), 2) as monthly_cost
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
GROUP BY ServiceName, month
ORDER BY month DESC, monthly_cost DESC;

-- Expected: Query should complete in reasonable time (< 30 seconds for most org sizes)
-- Note the bytes processed - if > 10GB regularly, consider materialized view
