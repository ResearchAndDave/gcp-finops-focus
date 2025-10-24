-- Diagnostic Query: Investigate Cost Discrepancy
-- This query helps understand the difference between source costs and FOCUS BilledCost
-- Replace `your-project.your-dataset` with your actual paths

-- ============================================================================
-- 1. ANALYZE CREDITS DISTRIBUTION
-- ============================================================================
-- Check if credits are negative and how they're being applied
SELECT
  DATE(usage_start_time) as usage_date,
  COUNT(*) as total_rows,
  COUNT(CASE WHEN ARRAY_LENGTH(credits) > 0 THEN 1 END) as rows_with_credits,
  SUM(cost) as total_cost,
  SUM((SELECT SUM(amount) FROM UNNEST(credits))) as total_credits,
  AVG((SELECT SUM(amount) FROM UNNEST(credits))) as avg_credit_per_row,
  MIN((SELECT SUM(amount) FROM UNNEST(credits))) as min_credit,
  MAX((SELECT SUM(amount) FROM UNNEST(credits))) as max_credit
FROM `your-project.your-dataset.gcp_billing_export_resource_v1_ACCOUNT`
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY usage_date
ORDER BY usage_date DESC;

-- Expected: Credits should typically be NEGATIVE values
-- If credits are negative, adding them to cost reduces the total


-- ============================================================================
-- 2. COMPARE COST CALCULATIONS
-- ============================================================================
-- See how different calculation methods produce different results
SELECT
  DATE(usage_start_time) as usage_date,

  -- Source table calculation (what validation query uses)
  ROUND(SUM(cost), 4) as source_cost_only,
  ROUND(SUM(cost) + IFNULL(SUM((SELECT SUM(amount) FROM UNNEST(credits))), 0), 4) as source_cost_plus_credits,

  -- What FOCUS BilledCost should be according to spec
  ROUND(SUM(cost), 4) as expected_billed_cost,

  -- What FOCUS EffectiveCost should be according to spec
  ROUND(SUM(cost) + IFNULL(SUM((SELECT SUM(amount) FROM UNNEST(credits))), 0), 4) as expected_effective_cost,

  -- Breakdown
  ROUND(IFNULL(SUM((SELECT SUM(amount) FROM UNNEST(credits))), 0), 4) as total_credits_applied

FROM `your-project.your-dataset.gcp_billing_export_resource_v1_ACCOUNT`
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY usage_date
ORDER BY usage_date DESC;

-- Expected:
-- source_cost_only should match expected_billed_cost
-- source_cost_plus_credits should match expected_effective_cost
-- total_credits_applied should be negative (discounts)


-- ============================================================================
-- 3. SAMPLE ROWS WITH CREDITS
-- ============================================================================
-- Examine individual rows to understand credit structure
SELECT
  DATE(usage_start_time) as usage_date,
  service.description as service,
  sku.description as sku,
  ROUND(cost, 4) as cost,
  credits,
  (SELECT SUM(amount) FROM UNNEST(credits)) as total_credits,
  ROUND(cost + IFNULL((SELECT SUM(amount) FROM UNNEST(credits)), 0), 4) as effective_cost
FROM `your-project.your-dataset.gcp_billing_export_resource_v1_ACCOUNT`
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 DAY)
  AND ARRAY_LENGTH(credits) > 0
ORDER BY ABS(cost) DESC
LIMIT 20;

-- Expected: Credits array should show credit types and amounts
-- Credit amounts should be negative


-- ============================================================================
-- 4. CHECK FOCUS VIEW ACTUAL VALUES
-- ============================================================================
-- See what the FOCUS view is actually calculating
SELECT
  DATE(ChargePeriodStart) as usage_date,
  COUNT(*) as row_count,
  ROUND(SUM(BilledCost), 4) as focus_billed_cost,
  ROUND(SUM(EffectiveCost), 4) as focus_effective_cost,
  ROUND(SUM(ContractedCost), 4) as focus_contracted_cost,
  ROUND(SUM(BilledCost) - SUM(EffectiveCost), 4) as billed_vs_effective_diff
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY usage_date
ORDER BY usage_date DESC;

-- Expected in CORRECT implementation:
-- BilledCost > EffectiveCost (if there are discounts)
-- billed_vs_effective_diff should be positive (savings from credits)
--
-- Current INCORRECT behavior:
-- BilledCost = EffectiveCost (both include credits)


-- ============================================================================
-- 5. DETAILED COST TYPE BREAKDOWN
-- ============================================================================
-- Check if the issue is related to specific cost types
SELECT
  DATE(usage_start_time) as usage_date,
  cost_type,
  COUNT(*) as row_count,
  ROUND(SUM(cost), 4) as total_cost,
  ROUND(SUM((SELECT SUM(amount) FROM UNNEST(credits))), 4) as total_credits,
  ROUND(SUM(cost) + IFNULL(SUM((SELECT SUM(amount) FROM UNNEST(credits))), 0), 4) as net_cost
FROM `your-project.your-dataset.gcp_billing_export_resource_v1_ACCOUNT`
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY usage_date, cost_type
ORDER BY usage_date DESC, total_cost DESC;

-- Expected: Most costs should be cost_type = 'regular'


-- ============================================================================
-- 6. CREDIT TYPES ANALYSIS
-- ============================================================================
-- Understand what types of credits you're receiving
SELECT
  DATE(usage_start_time) as usage_date,
  credit.type as credit_type,
  COUNT(*) as occurrences,
  ROUND(SUM(credit.amount), 4) as total_credit_amount,
  ROUND(AVG(credit.amount), 6) as avg_credit_amount
FROM `your-project.your-dataset.gcp_billing_export_resource_v1_ACCOUNT`,
  UNNEST(credits) as credit
WHERE DATE(usage_start_time) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
GROUP BY usage_date, credit_type
ORDER BY usage_date DESC, total_credit_amount;

-- Expected: Common credit types include:
-- - SUSTAINED_USAGE_DISCOUNT (negative)
-- - COMMITTED_USAGE_DISCOUNT (negative)
-- - PROMOTIONAL (negative)
-- - FREE_TIER (negative)


-- ============================================================================
-- INTERPRETATION GUIDE
-- ============================================================================
--
-- If credits are NEGATIVE (which is standard in GCP):
--   - BilledCost should = cost (before credits)
--   - EffectiveCost should = cost + credits (after credits)
--   - The FOCUS view currently calculates BOTH as cost + credits
--   - This is why BilledCost appears lower than source cost
--
-- The fix would be:
--   - BilledCost: CAST(usage_cost_data.cost AS NUMERIC)
--   - EffectiveCost: CAST(usage_cost_data.cost AS NUMERIC) + credits
--
-- However, Google's implementation might be intentional based on their
-- interpretation of the FOCUS spec. Check the limitations section of the
-- FOCUS guide PDF for GCP-specific implementation details.
