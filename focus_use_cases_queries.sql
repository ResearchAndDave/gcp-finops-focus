-- FOCUS v1.0 Use Case Queries for GCP
-- Adapted for your GCP FOCUS BigQuery view
-- Replace `your-project.your-dataset.focus_v1_0` with your actual view path
--
-- These queries demonstrate common FinOps use cases using FOCUS standard columns
-- Based on FOCUS v1.0 specification from focus.finops.org

-- ============================================================================
-- USE CASE 1: Total Cloud Spend Overview
-- ============================================================================
-- Question: What is our total cloud spend over time?
-- Persona: FinOps Practitioner, Finance
-- Capability: Cost Allocation

SELECT
  DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as billing_month,
  BillingCurrency as currency,
  ROUND(SUM(BilledCost), 2) as total_billed_cost,
  ROUND(SUM(EffectiveCost), 2) as total_effective_cost,
  ROUND(SUM(BilledCost) - SUM(EffectiveCost), 2) as total_savings,
  COUNT(DISTINCT SubAccountId) as number_of_accounts
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  AND ChargeCategory = 'usage'
GROUP BY billing_month, currency
ORDER BY billing_month DESC;

-- Expected Output: Monthly spend trends with savings breakdown


-- ============================================================================
-- USE CASE 2: Cost by Service
-- ============================================================================
-- Question: Which cloud services are driving the most cost?
-- Persona: Engineering Lead, FinOps Practitioner
-- Capability: Cost Allocation

SELECT
  ServiceName,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(AVG(EffectiveCost), 4) as avg_cost_per_charge,
  COUNT(*) as number_of_charges,
  ROUND(SUM(EffectiveCost) / (SELECT SUM(EffectiveCost)
    FROM `your-project.your-dataset.focus_v1_0`
    WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      AND ChargeCategory = 'usage') * 100, 2) as percent_of_total
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
GROUP BY ServiceName
ORDER BY total_cost DESC
LIMIT 20;

-- Expected Output: Top services by cost with percentage breakdown


-- ============================================================================
-- USE CASE 3: Regional Cost Analysis
-- ============================================================================
-- Question: How is our spend distributed across regions?
-- Persona: Cloud Architect, FinOps Practitioner
-- Capability: Cost Allocation, Rate Optimization

SELECT
  RegionId,
  RegionName,
  COUNT(DISTINCT ServiceName) as services_used,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(AVG(EffectiveCost), 4) as avg_cost,
  ROUND(SUM(ConsumedQuantity), 2) as total_quantity_consumed
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
  AND RegionId IS NOT NULL
GROUP BY RegionId, RegionName
ORDER BY total_cost DESC;

-- Expected Output: Cost breakdown by GCP region


-- ============================================================================
-- USE CASE 4: Commitment Savings Analysis
-- ============================================================================
-- Question: How much are we saving from our commitments (CUDs)?
-- Persona: FinOps Practitioner, Procurement
-- Capability: Rate Optimization

SELECT
  DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
  CommitmentDiscountCategory,
  COUNT(DISTINCT CommitmentDiscountId) as number_of_commitments,
  ROUND(SUM(BilledCost), 2) as billed_cost,
  ROUND(SUM(EffectiveCost), 2) as effective_cost,
  ROUND(SUM(BilledCost) - SUM(EffectiveCost), 2) as commitment_savings,
  ROUND((SUM(BilledCost) - SUM(EffectiveCost)) / NULLIF(SUM(BilledCost), 0) * 100, 2) as savings_percentage
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
  AND CommitmentDiscountCategory IS NOT NULL
GROUP BY month, CommitmentDiscountCategory
ORDER BY month DESC, commitment_savings DESC;

-- Expected Output: Monthly commitment savings trends


-- ============================================================================
-- USE CASE 5: On-Demand vs Committed Pricing
-- ============================================================================
-- Question: What percentage of our spend is on-demand vs committed?
-- Persona: FinOps Practitioner, Procurement
-- Capability: Rate Optimization

SELECT
  DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
  PricingCategory,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  COUNT(*) as number_of_charges,
  ROUND(SUM(EffectiveCost) / SUM(SUM(EffectiveCost)) OVER (PARTITION BY DATE_TRUNC(DATE(ChargePeriodStart), MONTH)) * 100, 2) as percent_of_monthly_spend
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  AND ChargeCategory = 'usage'
  AND PricingCategory IS NOT NULL
GROUP BY month, PricingCategory
ORDER BY month DESC, total_cost DESC;

-- Expected Output: Monthly breakdown of standard vs committed pricing


-- ============================================================================
-- USE CASE 6: Cost by Resource
-- ============================================================================
-- Question: Which specific resources are most expensive?
-- Persona: Engineering Team, Cloud Architect
-- Capability: Cost Allocation, Workload Optimization

SELECT
  ResourceType,
  ResourceId,
  ResourceName,
  ServiceName,
  RegionName,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(AVG(EffectiveCost), 4) as avg_daily_cost,
  COUNT(DISTINCT DATE(ChargePeriodStart)) as days_active
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
  AND ResourceId IS NOT NULL
GROUP BY ResourceType, ResourceId, ResourceName, ServiceName, RegionName
ORDER BY total_cost DESC
LIMIT 50;

-- Expected Output: Top 50 most expensive resources


-- ============================================================================
-- USE CASE 7: Daily Cost Trends
-- ============================================================================
-- Question: What is our daily spending pattern?
-- Persona: FinOps Practitioner, Finance
-- Capability: Cost Allocation, Forecasting

SELECT
  DATE(ChargePeriodStart) as usage_date,
  ROUND(SUM(EffectiveCost), 2) as daily_cost,
  ROUND(AVG(SUM(EffectiveCost)) OVER (
    ORDER BY DATE(ChargePeriodStart)
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ), 2) as seven_day_avg,
  COUNT(DISTINCT ServiceName) as services_used,
  COUNT(*) as number_of_charges
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  AND ChargeCategory = 'usage'
GROUP BY usage_date
ORDER BY usage_date DESC;

-- Expected Output: Daily costs with 7-day moving average


-- ============================================================================
-- USE CASE 8: SKU-Level Analysis
-- ============================================================================
-- Question: What are the most expensive SKUs?
-- Persona: Engineering Team, FinOps Practitioner
-- Capability: Cost Allocation, Rate Optimization

SELECT
  ServiceName,
  ChargeDescription,
  SkuId,
  PricingCategory,
  COUNT(*) as usage_count,
  ROUND(SUM(ConsumedQuantity), 2) as total_quantity,
  ConsumedUnit,
  ROUND(AVG(ContractedUnitPrice), 6) as avg_unit_price,
  ROUND(SUM(EffectiveCost), 2) as total_cost
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
  AND SkuId IS NOT NULL
GROUP BY ServiceName, ChargeDescription, SkuId, PricingCategory, ConsumedUnit
ORDER BY total_cost DESC
LIMIT 30;

-- Expected Output: Top 30 SKUs by cost with pricing details


-- ============================================================================
-- USE CASE 9: Tag-Based Cost Allocation
-- ============================================================================
-- Question: How is cost distributed across our tagged resources?
-- Persona: FinOps Practitioner, Engineering Lead
-- Capability: Cost Allocation, Chargeback/Showback

SELECT
  tag.key as tag_key,
  tag.value as tag_value,
  tag.x_type as tag_type,
  COUNT(DISTINCT ResourceId) as tagged_resources,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(AVG(EffectiveCost), 4) as avg_cost_per_charge,
  COUNT(DISTINCT ServiceName) as services_used
FROM `your-project.your-dataset.focus_v1_0`,
  UNNEST(Tags) as tag
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
  AND tag.key IN ('environment', 'team', 'project', 'cost-center', 'application')
  -- Adjust tag keys to match your organization's taxonomy
GROUP BY tag_key, tag_value, tag_type
ORDER BY total_cost DESC;

-- Expected Output: Cost breakdown by business tags


-- ============================================================================
-- USE CASE 10: Untagged Resources
-- ============================================================================
-- Question: What resources lack proper cost allocation tags?
-- Persona: FinOps Practitioner, Cloud Governance
-- Capability: Cost Allocation, Cloud Governance

WITH tagged_resources AS (
  SELECT DISTINCT
    ResourceId,
    DATE(ChargePeriodStart) as usage_date
  FROM `your-project.your-dataset.focus_v1_0`,
    UNNEST(Tags) as tag
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
    AND tag.key IN ('environment', 'team', 'cost-center')
    -- Adjust to your required tags
)
SELECT
  f.ServiceName,
  f.ResourceType,
  f.ResourceId,
  f.ResourceName,
  f.RegionName,
  ROUND(SUM(f.EffectiveCost), 2) as untagged_cost,
  COUNT(DISTINCT DATE(f.ChargePeriodStart)) as days_active
FROM `your-project.your-dataset.focus_v1_0` f
LEFT JOIN tagged_resources tr
  ON f.ResourceId = tr.ResourceId
  AND DATE(f.ChargePeriodStart) = tr.usage_date
WHERE DATE(f.ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND f.ChargeCategory = 'usage'
  AND f.ResourceId IS NOT NULL
  AND tr.ResourceId IS NULL
GROUP BY f.ServiceName, f.ResourceType, f.ResourceId, f.ResourceName, f.RegionName
ORDER BY untagged_cost DESC
LIMIT 50;

-- Expected Output: Top untagged resources by cost


-- ============================================================================
-- USE CASE 11: Credit and Discount Analysis
-- ============================================================================
-- Question: What credits and discounts are we receiving?
-- Persona: FinOps Practitioner, Finance
-- Capability: Rate Optimization

SELECT
  DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
  credit.Type as credit_type,
  COUNT(*) as number_of_credits,
  ROUND(SUM(credit.Amount), 2) as total_credit_amount,
  COUNT(DISTINCT ServiceName) as services_receiving_credits,
  ROUND(AVG(credit.Amount), 4) as avg_credit_per_charge
FROM `your-project.your-dataset.focus_v1_0`,
  UNNEST(x_Credits) as credit
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
GROUP BY month, credit_type
ORDER BY month DESC, total_credit_amount;

-- Expected Output: Monthly breakdown of all credit types


-- ============================================================================
-- USE CASE 12: Cost Anomaly Detection
-- ============================================================================
-- Question: Which services have unusual cost spikes?
-- Persona: FinOps Practitioner, Engineering Team
-- Capability: Cost Anomaly Detection

WITH daily_service_costs AS (
  SELECT
    DATE(ChargePeriodStart) as usage_date,
    ServiceName,
    ROUND(SUM(EffectiveCost), 2) as daily_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    AND ChargeCategory = 'usage'
  GROUP BY usage_date, ServiceName
),
service_stats AS (
  SELECT
    ServiceName,
    AVG(daily_cost) as avg_daily_cost,
    STDDEV(daily_cost) as stddev_daily_cost
  FROM daily_service_costs
  GROUP BY ServiceName
)
SELECT
  dsc.usage_date,
  dsc.ServiceName,
  dsc.daily_cost,
  ROUND(ss.avg_daily_cost, 2) as avg_daily_cost,
  ROUND((dsc.daily_cost - ss.avg_daily_cost) / NULLIF(ss.stddev_daily_cost, 0), 2) as z_score,
  CASE
    WHEN (dsc.daily_cost - ss.avg_daily_cost) / NULLIF(ss.stddev_daily_cost, 0) > 2 THEN 'High Anomaly'
    WHEN (dsc.daily_cost - ss.avg_daily_cost) / NULLIF(ss.stddev_daily_cost, 0) > 1.5 THEN 'Moderate Anomaly'
    ELSE 'Normal'
  END as anomaly_severity
FROM daily_service_costs dsc
JOIN service_stats ss ON dsc.ServiceName = ss.ServiceName
WHERE dsc.usage_date >= DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY)
  AND (dsc.daily_cost - ss.avg_daily_cost) / NULLIF(ss.stddev_daily_cost, 0) > 1.5
ORDER BY z_score DESC;

-- Expected Output: Recent cost anomalies with severity ratings


-- ============================================================================
-- USE CASE 13: Month-over-Month Growth
-- ============================================================================
-- Question: How is our spend growing month-over-month?
-- Persona: Finance, Executive
-- Capability: Forecasting, Reporting

WITH monthly_costs AS (
  SELECT
    DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
    ServiceName,
    ROUND(SUM(EffectiveCost), 2) as monthly_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
    AND ChargeCategory = 'usage'
  GROUP BY month, ServiceName
)
SELECT
  month,
  ServiceName,
  monthly_cost,
  LAG(monthly_cost) OVER (PARTITION BY ServiceName ORDER BY month) as previous_month_cost,
  ROUND(monthly_cost - LAG(monthly_cost) OVER (PARTITION BY ServiceName ORDER BY month), 2) as month_over_month_change,
  ROUND((monthly_cost - LAG(monthly_cost) OVER (PARTITION BY ServiceName ORDER BY month)) /
    NULLIF(LAG(monthly_cost) OVER (PARTITION BY ServiceName ORDER BY month), 0) * 100, 2) as percent_change
FROM monthly_costs
WHERE month >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH), MONTH)
ORDER BY month DESC, monthly_cost DESC;

-- Expected Output: Month-over-month cost trends by service


-- ============================================================================
-- USE CASE 14: Publisher/Marketplace Analysis
-- ============================================================================
-- Question: How much are we spending on marketplace/third-party services?
-- Persona: Procurement, FinOps Practitioner
-- Capability: Cost Allocation

SELECT
  PublisherName,
  ProviderName,
  COUNT(DISTINCT ServiceName) as number_of_services,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(SUM(EffectiveCost) / (SELECT SUM(EffectiveCost)
    FROM `your-project.your-dataset.focus_v1_0`
    WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      AND ChargeCategory = 'usage') * 100, 2) as percent_of_total_spend
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
GROUP BY PublisherName, ProviderName
ORDER BY total_cost DESC;

-- Expected Output: Breakdown of first-party vs marketplace spend


-- ============================================================================
-- USE CASE 15: Cost by Charge Category
-- ============================================================================
-- Question: How is our spend distributed across usage, tax, and adjustments?
-- Persona: Finance, FinOps Practitioner
-- Capability: Invoice Reconciliation

SELECT
  DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
  ChargeCategory,
  ChargeClass,
  ROUND(SUM(BilledCost), 2) as total_billed,
  ROUND(SUM(EffectiveCost), 2) as total_effective,
  COUNT(*) as number_of_charges
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
GROUP BY month, ChargeCategory, ChargeClass
ORDER BY month DESC, total_effective DESC;

-- Expected Output: Monthly breakdown by charge type


-- ============================================================================
-- USE CASE 16: Resource Utilization by Service
-- ============================================================================
-- Question: What is our resource consumption pattern by service?
-- Persona: Engineering Team, Cloud Architect
-- Capability: Workload Optimization

SELECT
  ServiceName,
  ConsumedUnit,
  COUNT(DISTINCT ResourceId) as unique_resources,
  ROUND(SUM(ConsumedQuantity), 2) as total_quantity_consumed,
  ROUND(AVG(ConsumedQuantity), 4) as avg_quantity_per_charge,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(SUM(EffectiveCost) / NULLIF(SUM(ConsumedQuantity), 0), 6) as cost_per_unit
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
  AND ConsumedQuantity IS NOT NULL
  AND ConsumedUnit IS NOT NULL
GROUP BY ServiceName, ConsumedUnit
ORDER BY total_cost DESC;

-- Expected Output: Service consumption with unit costs


-- ============================================================================
-- USE CASE 17: Cost Efficiency by Region
-- ============================================================================
-- Question: Which regions provide the best cost efficiency?
-- Persona: Cloud Architect, FinOps Practitioner
-- Capability: Rate Optimization

SELECT
  ServiceName,
  RegionName,
  ROUND(SUM(ConsumedQuantity), 2) as total_usage,
  ConsumedUnit,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(SUM(EffectiveCost) / NULLIF(SUM(ConsumedQuantity), 0), 6) as cost_per_unit,
  ROUND(AVG(ContractedUnitPrice), 6) as avg_unit_price
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
  AND RegionName IS NOT NULL
  AND ConsumedQuantity > 0
GROUP BY ServiceName, RegionName, ConsumedUnit
HAVING SUM(EffectiveCost) > 10  -- Focus on significant costs
ORDER BY ServiceName, cost_per_unit;

-- Expected Output: Regional pricing comparison by service


-- ============================================================================
-- USE CASE 18: Weekend vs Weekday Usage
-- ============================================================================
-- Question: How does our usage pattern differ between weekdays and weekends?
-- Persona: Engineering Team, FinOps Practitioner
-- Capability: Workload Optimization

SELECT
  ServiceName,
  CASE
    WHEN EXTRACT(DAYOFWEEK FROM DATE(ChargePeriodStart)) IN (1, 7) THEN 'Weekend'
    ELSE 'Weekday'
  END as day_type,
  COUNT(*) as number_of_charges,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(AVG(EffectiveCost), 4) as avg_cost_per_charge,
  ROUND(SUM(ConsumedQuantity), 2) as total_quantity
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  AND ChargeCategory = 'usage'
GROUP BY ServiceName, day_type
ORDER BY ServiceName, total_cost DESC;

-- Expected Output: Weekday vs weekend cost patterns


-- ============================================================================
-- USE CASE 19: Hourly Cost Pattern Analysis
-- ============================================================================
-- Question: What are our peak usage hours?
-- Persona: Engineering Team, Cloud Architect
-- Capability: Workload Optimization

SELECT
  EXTRACT(HOUR FROM ChargePeriodStart) as hour_of_day,
  ServiceName,
  COUNT(*) as number_of_charges,
  ROUND(SUM(EffectiveCost), 2) as total_cost,
  ROUND(AVG(EffectiveCost), 4) as avg_cost
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
  AND ChargeCategory = 'usage'
GROUP BY hour_of_day, ServiceName
ORDER BY hour_of_day, total_cost DESC;

-- Expected Output: Hourly cost distribution by service


-- ============================================================================
-- USE CASE 20: Budget Tracking
-- ============================================================================
-- Question: How are we tracking against our budget?
-- Persona: Finance, FinOps Practitioner
-- Capability: Budget Management

WITH monthly_actual AS (
  SELECT
    DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
    ROUND(SUM(EffectiveCost), 2) as actual_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH), MONTH)
    AND ChargeCategory = 'usage'
  GROUP BY month
),
budget_info AS (
  -- Replace with your actual budget values or join to a budget table
  SELECT
    month,
    10000.00 as monthly_budget  -- Example: $10k monthly budget
  FROM UNNEST(GENERATE_DATE_ARRAY(
    DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH), MONTH),
    DATE_TRUNC(CURRENT_DATE(), MONTH),
    INTERVAL 1 MONTH
  )) as month
)
SELECT
  ma.month,
  ma.actual_cost,
  bi.monthly_budget,
  ROUND(ma.actual_cost - bi.monthly_budget, 2) as variance,
  ROUND((ma.actual_cost / bi.monthly_budget) * 100, 2) as percent_of_budget,
  CASE
    WHEN ma.actual_cost > bi.monthly_budget * 1.1 THEN 'Over Budget (>10%)'
    WHEN ma.actual_cost > bi.monthly_budget THEN 'Over Budget'
    WHEN ma.actual_cost > bi.monthly_budget * 0.9 THEN 'Near Budget'
    ELSE 'Under Budget'
  END as budget_status
FROM monthly_actual ma
JOIN budget_info bi ON ma.month = bi.month
ORDER BY ma.month DESC;

-- Expected Output: Monthly budget vs actual with variance analysis


-- ============================================================================
-- NOTES ON CUSTOMIZATION
-- ============================================================================
--
-- To adapt these queries for your organization:
--
-- 1. Replace table path: `your-project.your-dataset.focus_v1_0`
--
-- 2. Adjust date ranges based on your data availability
--
-- 3. Customize tag keys in tag-based queries (e.g., 'environment', 'team')
--
-- 4. Modify budget values in budget tracking query
--
-- 5. Add WHERE clauses to filter by specific:
--    - SubAccountId (for specific GCP billing accounts)
--    - ServiceName (for specific services)
--    - RegionId (for specific regions)
--    - Tags (for specific business units/teams)
--
-- 6. Combine queries or add JOINs for more complex analysis
--
-- 7. Create scheduled queries in BigQuery for regular reporting
--
-- 8. Build dashboards in Looker/Data Studio using these queries as base
--
-- ============================================================================
