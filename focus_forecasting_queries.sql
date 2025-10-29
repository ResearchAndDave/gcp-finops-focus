-- FOCUS v1.0 Forecasting Queries for GCP
-- Financial Planning & Forecasting Use Cases
-- Replace `your-project.your-dataset.focus_v1_0` with your actual view path
--
-- These queries help finance teams and FinOps practitioners predict future costs
-- Based on FOCUS v1.0 specification and FinOps forecasting best practices

-- ============================================================================
-- FORECAST 1: Simple Linear Trend Forecast (Next 3 Months)
-- ============================================================================
-- Question: What will our costs be in the next 3 months based on linear trend?
-- Persona: Finance Team, CFO, FinOps Practitioner
-- Capability: Forecasting
-- Method: Linear regression on historical data

WITH daily_costs AS (
  SELECT
    DATE(ChargePeriodStart) as cost_date,
    ROUND(SUM(EffectiveCost), 2) as daily_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
    AND DATE(ChargePeriodStart) < CURRENT_DATE()
    AND ChargeCategory = 'usage'
  GROUP BY cost_date
),
trend_analysis AS (
  SELECT
    AVG(daily_cost) as avg_daily_cost,
    -- Calculate daily growth using linear regression slope approximation
    (SUM((DATE_DIFF(cost_date, DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), DAY)) * daily_cost) /
     SUM(POW(DATE_DIFF(cost_date, DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), DAY), 2))) as daily_growth_rate
  FROM daily_costs
),
forecast_dates AS (
  SELECT date_value as forecast_date
  FROM UNNEST(GENERATE_DATE_ARRAY(
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 90 DAY),
    INTERVAL 1 DAY
  )) as date_value
)
SELECT
  DATE_TRUNC(fd.forecast_date, MONTH) as forecast_month,
  ROUND(SUM(ta.avg_daily_cost + (ta.daily_growth_rate * DATE_DIFF(fd.forecast_date, CURRENT_DATE(), DAY))), 2) as forecasted_cost,
  COUNT(*) as days_in_month
FROM forecast_dates fd
CROSS JOIN trend_analysis ta
GROUP BY forecast_month
ORDER BY forecast_month;

-- Expected Output: Monthly forecasted costs for next 3 months
-- Use: Budget planning, financial reporting


-- ============================================================================
-- FORECAST 2: Service-Level Forecast with Historical Patterns
-- ============================================================================
-- Question: What will each service cost next month?
-- Persona: Engineering Lead, Finance Team
-- Capability: Forecasting, Cost Allocation
-- Method: Average daily cost × days in next month

WITH historical_daily_avg AS (
  SELECT
    ServiceName,
    AVG(daily_cost) as avg_daily_cost,
    STDDEV(daily_cost) as stddev_daily_cost,
    MIN(daily_cost) as min_daily_cost,
    MAX(daily_cost) as max_daily_cost
  FROM (
    SELECT
      ServiceName,
      DATE(ChargePeriodStart) as cost_date,
      SUM(EffectiveCost) as daily_cost
    FROM `your-project.your-dataset.focus_v1_0`
    WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
      AND DATE(ChargePeriodStart) < CURRENT_DATE()
      AND ChargeCategory = 'usage'
    GROUP BY ServiceName, cost_date
  )
  GROUP BY ServiceName
),
next_month_info AS (
  SELECT
    DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH) as next_month,
    DATE_DIFF(
      DATE_SUB(DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL 2 MONTH), MONTH), INTERVAL 1 DAY),
      DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH),
      DAY
    ) + 1 as days_in_next_month
)
SELECT
  h.ServiceName,
  ROUND(h.avg_daily_cost, 2) as avg_daily_cost,
  nm.days_in_next_month,
  ROUND(h.avg_daily_cost * nm.days_in_next_month, 2) as forecasted_monthly_cost,
  ROUND((h.avg_daily_cost - h.stddev_daily_cost) * nm.days_in_next_month, 2) as low_estimate,
  ROUND((h.avg_daily_cost + h.stddev_daily_cost) * nm.days_in_next_month, 2) as high_estimate,
  nm.next_month
FROM historical_daily_avg h
CROSS JOIN next_month_info nm
WHERE h.avg_daily_cost > 1  -- Filter out negligible services
ORDER BY forecasted_monthly_cost DESC;

-- Expected Output: Next month forecast by service with confidence ranges
-- Use: Service-level budget planning


-- ============================================================================
-- FORECAST 3: Seasonality-Adjusted Forecast
-- ============================================================================
-- Question: What will costs be accounting for seasonal patterns?
-- Persona: Finance Team, CFO
-- Capability: Forecasting
-- Method: Year-over-year comparison with trend adjustment

WITH monthly_historical AS (
  SELECT
    DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
    EXTRACT(MONTH FROM DATE(ChargePeriodStart)) as month_number,
    EXTRACT(YEAR FROM DATE(ChargePeriodStart)) as year,
    ROUND(SUM(EffectiveCost), 2) as monthly_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 24 MONTH)
    AND ChargeCategory = 'usage'
  GROUP BY month, month_number, year
),
seasonal_pattern AS (
  SELECT
    month_number,
    AVG(monthly_cost) as avg_cost_for_month,
    STDDEV(monthly_cost) as stddev_cost_for_month,
    COUNT(*) as years_of_data
  FROM monthly_historical
  GROUP BY month_number
),
recent_growth AS (
  SELECT
    AVG((curr.monthly_cost - prev.monthly_cost) / NULLIF(prev.monthly_cost, 0)) as monthly_growth_rate
  FROM monthly_historical curr
  JOIN monthly_historical prev
    ON curr.month = DATE_ADD(prev.month, INTERVAL 1 MONTH)
  WHERE curr.month >= DATE_SUB(CURRENT_DATE(), INTERVAL 6 MONTH)
),
last_year_same_month AS (
  SELECT
    month_number,
    monthly_cost
  FROM monthly_historical
  WHERE year = EXTRACT(YEAR FROM DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH))
)
SELECT
  DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL offset MONTH), MONTH) as forecast_month,
  EXTRACT(MONTH FROM DATE_ADD(CURRENT_DATE(), INTERVAL offset MONTH)) as month_number,
  ROUND(
    COALESCE(ly.monthly_cost, sp.avg_cost_for_month) *
    POW(1 + rg.monthly_growth_rate, offset),
    2
  ) as forecasted_cost,
  ROUND(sp.avg_cost_for_month, 2) as historical_avg_for_month,
  ROUND(sp.stddev_cost_for_month, 2) as historical_stddev
FROM UNNEST(GENERATE_ARRAY(1, 6)) as offset
CROSS JOIN seasonal_pattern sp
CROSS JOIN recent_growth rg
LEFT JOIN last_year_same_month ly
  ON sp.month_number = EXTRACT(MONTH FROM DATE_ADD(CURRENT_DATE(), INTERVAL offset MONTH))
WHERE sp.month_number = EXTRACT(MONTH FROM DATE_ADD(CURRENT_DATE(), INTERVAL offset MONTH))
ORDER BY forecast_month;

-- Expected Output: 6-month forecast with seasonal adjustment
-- Use: Annual budget planning, board presentations


-- ============================================================================
-- FORECAST 4: Commitment Expiration Impact Analysis
-- ============================================================================
-- Question: What will happen to costs when commitments expire?
-- Persona: Procurement, Finance, FinOps Practitioner
-- Capability: Forecasting, Rate Optimization
-- Method: Calculate cost impact of commitment expiration

WITH current_commitment_usage AS (
  SELECT
    ServiceName,
    CommitmentDiscountId,
    CommitmentDiscountName,
    DATE(MIN(ChargePeriodStart)) as first_seen,
    DATE(MAX(ChargePeriodStart)) as last_seen,
    ROUND(AVG(CASE WHEN DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      THEN EffectiveCost END), 2) as avg_daily_effective_cost,
    ROUND(AVG(CASE WHEN DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
      THEN BilledCost END), 2) as avg_daily_billed_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE CommitmentDiscountId IS NOT NULL
    AND ChargeCategory = 'usage'
    AND DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  GROUP BY ServiceName, CommitmentDiscountId, CommitmentDiscountName
),
commitment_savings AS (
  SELECT
    *,
    ROUND(avg_daily_billed_cost - avg_daily_effective_cost, 2) as daily_savings,
    ROUND((avg_daily_billed_cost - avg_daily_effective_cost) * 365, 2) as annual_savings,
    -- Assume commitment expires if not seen in last 7 days
    CASE
      WHEN last_seen < DATE_SUB(CURRENT_DATE(), INTERVAL 7 DAY) THEN 'Expired'
      WHEN DATE_DIFF(last_seen, first_seen, DAY) > 330 THEN 'Expiring Soon'
      ELSE 'Active'
    END as commitment_status
  FROM current_commitment_usage
)
SELECT
  ServiceName,
  CommitmentDiscountName,
  commitment_status,
  last_seen,
  ROUND(avg_daily_effective_cost, 2) as current_daily_cost,
  ROUND(avg_daily_billed_cost, 2) as cost_without_commitment,
  ROUND(daily_savings, 2) as daily_savings,
  ROUND(daily_savings * 30, 2) as monthly_impact_if_expires,
  ROUND(annual_savings, 2) as annual_savings
FROM commitment_savings
WHERE commitment_status IN ('Expired', 'Expiring Soon')
  OR daily_savings > 10  -- Focus on significant commitments
ORDER BY monthly_impact_if_expires DESC;

-- Expected Output: Commitment expiration impact on costs
-- Use: Commitment renewal planning, budget risk assessment


-- ============================================================================
-- FORECAST 5: Growth Rate Forecast by Service
-- ============================================================================
-- Question: Which services are growing fastest and what will they cost?
-- Persona: Engineering Lead, Finance, CTO
-- Capability: Forecasting, Cost Allocation
-- Method: Calculate compound monthly growth rate (CMGR)

WITH monthly_service_costs AS (
  SELECT
    DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as month,
    ServiceName,
    ROUND(SUM(EffectiveCost), 2) as monthly_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
    AND ChargeCategory = 'usage'
  GROUP BY month, ServiceName
),
growth_analysis AS (
  SELECT
    ServiceName,
    MIN(month) as first_month,
    MAX(month) as last_month,
    MIN(CASE WHEN month = (SELECT MIN(month) FROM monthly_service_costs msc2 WHERE msc2.ServiceName = msc1.ServiceName)
      THEN monthly_cost END) as first_month_cost,
    MAX(CASE WHEN month = (SELECT MAX(month) FROM monthly_service_costs msc2 WHERE msc2.ServiceName = msc1.ServiceName)
      THEN monthly_cost END) as last_month_cost,
    AVG(monthly_cost) as avg_monthly_cost,
    COUNT(*) as months_of_data
  FROM monthly_service_costs msc1
  GROUP BY ServiceName
),
cmgr_calculation AS (
  SELECT
    ServiceName,
    first_month,
    last_month,
    first_month_cost,
    last_month_cost,
    avg_monthly_cost,
    months_of_data,
    -- Compound Monthly Growth Rate
    ROUND(POW(last_month_cost / NULLIF(first_month_cost, 0), 1.0 / NULLIF(months_of_data - 1, 0)) - 1, 4) as cmgr,
    -- Simple month-over-month average
    ROUND((last_month_cost - first_month_cost) / NULLIF(first_month_cost * months_of_data, 0), 4) as simple_growth_rate
  FROM growth_analysis
  WHERE months_of_data >= 3  -- Need at least 3 months of data
)
SELECT
  ServiceName,
  ROUND(last_month_cost, 2) as current_monthly_cost,
  ROUND(cmgr * 100, 2) as monthly_growth_pct,
  -- Forecast next 3 months
  ROUND(last_month_cost * POW(1 + cmgr, 1), 2) as forecast_month_1,
  ROUND(last_month_cost * POW(1 + cmgr, 2), 2) as forecast_month_2,
  ROUND(last_month_cost * POW(1 + cmgr, 3), 2) as forecast_month_3,
  -- Forecast next 12 months total
  ROUND(last_month_cost * ((POW(1 + cmgr, 12) - 1) / NULLIF(cmgr, 0)), 2) as forecast_next_12_months,
  months_of_data
FROM cmgr_calculation
WHERE last_month_cost > 10  -- Filter out negligible services
ORDER BY monthly_growth_pct DESC;

-- Expected Output: Service growth rates with multi-month forecasts
-- Use: Identify fast-growing services, capacity planning


-- ============================================================================
-- FORECAST 6: Resource-Based Capacity Forecast
-- ============================================================================
-- Question: Based on resource consumption trends, what will we need?
-- Persona: Cloud Architect, Engineering Lead, Finance
-- Capability: Forecasting, Workload Management
-- Method: Linear trend on consumed quantities

WITH daily_resource_usage AS (
  SELECT
    DATE(ChargePeriodStart) as usage_date,
    ServiceName,
    ResourceType,
    ConsumedUnit,
    ROUND(SUM(ConsumedQuantity), 2) as daily_quantity,
    ROUND(SUM(EffectiveCost), 2) as daily_cost,
    ROUND(SUM(EffectiveCost) / NULLIF(SUM(ConsumedQuantity), 0), 6) as cost_per_unit
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
    AND DATE(ChargePeriodStart) < CURRENT_DATE()
    AND ChargeCategory = 'usage'
    AND ConsumedQuantity > 0
    AND ResourceType IS NOT NULL
  GROUP BY usage_date, ServiceName, ResourceType, ConsumedUnit
),
usage_trends AS (
  SELECT
    ServiceName,
    ResourceType,
    ConsumedUnit,
    AVG(daily_quantity) as avg_daily_quantity,
    -- Calculate growth trend
    (CORR(DATE_DIFF(usage_date, DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY), DAY), daily_quantity) *
     STDDEV(daily_quantity) / NULLIF(STDDEV(DATE_DIFF(usage_date, DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY), DAY)), 0)) as daily_growth,
    AVG(cost_per_unit) as avg_cost_per_unit,
    COUNT(DISTINCT usage_date) as days_of_data
  FROM daily_resource_usage
  GROUP BY ServiceName, ResourceType, ConsumedUnit
  HAVING COUNT(DISTINCT usage_date) >= 30  -- Need sufficient data
)
SELECT
  ServiceName,
  ResourceType,
  ConsumedUnit,
  ROUND(avg_daily_quantity, 2) as current_avg_daily_quantity,
  ROUND(daily_growth, 4) as daily_quantity_growth,
  ROUND(avg_cost_per_unit, 6) as cost_per_unit,
  -- Forecast next 30 days
  ROUND((avg_daily_quantity + (daily_growth * 30)) * 30, 2) as forecast_next_30d_quantity,
  ROUND((avg_daily_quantity + (daily_growth * 30)) * 30 * avg_cost_per_unit, 2) as forecast_next_30d_cost,
  -- Forecast next 90 days
  ROUND((avg_daily_quantity + (daily_growth * 90)) * 90, 2) as forecast_next_90d_quantity,
  ROUND((avg_daily_quantity + (daily_growth * 90)) * 90 * avg_cost_per_unit, 2) as forecast_next_90d_cost
FROM usage_trends
WHERE avg_daily_quantity * avg_cost_per_unit > 1  -- Focus on significant resources
ORDER BY forecast_next_30d_cost DESC;

-- Expected Output: Resource consumption and cost forecasts
-- Use: Capacity planning, infrastructure scaling decisions


-- ============================================================================
-- FORECAST 7: Budget Runway Analysis
-- ============================================================================
-- Question: At current burn rate, when will we exceed our budget?
-- Persona: Finance, CFO, FinOps Practitioner
-- Capability: Forecasting, Budget Management
-- Method: Calculate daily burn rate and project budget exhaustion

WITH daily_spend AS (
  SELECT
    DATE(ChargePeriodStart) as spend_date,
    ROUND(SUM(EffectiveCost), 2) as daily_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
    AND DATE(ChargePeriodStart) < CURRENT_DATE()
    AND ChargeCategory = 'usage'
  GROUP BY spend_date
),
burn_rate AS (
  SELECT
    AVG(daily_cost) as avg_daily_burn,
    STDDEV(daily_cost) as stddev_daily_burn,
    MIN(daily_cost) as min_daily_burn,
    MAX(daily_cost) as max_daily_burn
  FROM daily_spend
),
monthly_info AS (
  SELECT
    DATE_TRUNC(CURRENT_DATE(), MONTH) as current_month_start,
    DATE_SUB(DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY) as current_month_end,
    DATE_DIFF(
      DATE_SUB(DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL 1 MONTH), MONTH), INTERVAL 1 DAY),
      CURRENT_DATE(),
      DAY
    ) + 1 as days_remaining_in_month
),
month_to_date_spend AS (
  SELECT
    ROUND(SUM(EffectiveCost), 2) as mtd_spend
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_TRUNC(CURRENT_DATE(), MONTH)
    AND DATE(ChargePeriodStart) < CURRENT_DATE()
    AND ChargeCategory = 'usage'
)
SELECT
  'Current Month Forecast' as metric,
  ROUND(br.avg_daily_burn, 2) as avg_daily_burn_rate,
  mi.days_remaining_in_month as days_remaining,
  ROUND(mtd.mtd_spend, 2) as month_to_date_spend,
  ROUND(br.avg_daily_burn * mi.days_remaining_in_month, 2) as forecasted_remaining_spend,
  ROUND(mtd.mtd_spend + (br.avg_daily_burn * mi.days_remaining_in_month), 2) as forecasted_month_end_total,
  -- Replace with your actual budget
  10000.00 as monthly_budget,
  ROUND(10000.00 - (mtd.mtd_spend + (br.avg_daily_burn * mi.days_remaining_in_month)), 2) as projected_variance,
  CASE
    WHEN (mtd.mtd_spend + (br.avg_daily_burn * mi.days_remaining_in_month)) > 10000.00
    THEN CAST(FLOOR((10000.00 - mtd.mtd_spend) / NULLIF(br.avg_daily_burn, 0)) AS INT64)
    ELSE mi.days_remaining_in_month
  END as days_until_budget_exhausted
FROM burn_rate br
CROSS JOIN monthly_info mi
CROSS JOIN month_to_date_spend mtd;

-- Expected Output: Budget runway and exhaustion date
-- Use: Budget risk management, spend alerts


-- ============================================================================
-- FORECAST 8: Tag-Based Team/Project Forecast
-- ============================================================================
-- Question: What will each team/project spend next quarter?
-- Persona: Engineering Leads, Finance, Product Managers
-- Capability: Forecasting, Cost Allocation, Chargeback
-- Method: Team-level trend analysis

WITH daily_team_costs AS (
  SELECT
    DATE(ChargePeriodStart) as cost_date,
    tag.key as tag_key,
    tag.value as team_name,
    ROUND(SUM(EffectiveCost), 2) as daily_cost
  FROM `your-project.your-dataset.focus_v1_0`,
    UNNEST(Tags) as tag
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
    AND DATE(ChargePeriodStart) < CURRENT_DATE()
    AND ChargeCategory = 'usage'
    AND tag.key IN ('team', 'department', 'project', 'cost-center')  -- Adjust to your tag keys
  GROUP BY cost_date, tag_key, team_name
),
team_trends AS (
  SELECT
    tag_key,
    team_name,
    AVG(daily_cost) as avg_daily_cost,
    -- Calculate linear growth rate
    (SUM((DATE_DIFF(cost_date, DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), DAY)) * daily_cost) /
     NULLIF(SUM(POW(DATE_DIFF(cost_date, DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY), DAY), 2)), 0)) as daily_growth_rate,
    STDDEV(daily_cost) as stddev_daily_cost,
    COUNT(DISTINCT cost_date) as days_of_data
  FROM daily_team_costs
  GROUP BY tag_key, team_name
  HAVING COUNT(DISTINCT cost_date) >= 30
)
SELECT
  tag_key,
  team_name,
  ROUND(avg_daily_cost, 2) as current_avg_daily_cost,
  ROUND(daily_growth_rate, 4) as daily_growth_rate,
  -- Next month forecast
  ROUND((avg_daily_cost + (daily_growth_rate * 30)) * 30, 2) as forecast_next_month,
  -- Next quarter forecast (90 days)
  ROUND((avg_daily_cost + (daily_growth_rate * 90)) * 90, 2) as forecast_next_quarter,
  -- Confidence interval
  ROUND((avg_daily_cost - stddev_daily_cost) * 30, 2) as next_month_low_estimate,
  ROUND((avg_daily_cost + stddev_daily_cost) * 30, 2) as next_month_high_estimate,
  days_of_data
FROM team_trends
WHERE avg_daily_cost > 1  -- Filter negligible teams
ORDER BY forecast_next_quarter DESC;

-- Expected Output: Team/project-level forecasts with confidence ranges
-- Use: Department budgeting, project cost allocation


-- ============================================================================
-- FORECAST 9: Quarterly Forecast with Variance Analysis
-- ============================================================================
-- Question: What will we spend this quarter vs last quarter?
-- Persona: Finance, CFO, Board of Directors
-- Capability: Forecasting, Financial Reporting
-- Method: Quarter-over-quarter comparison with trend

WITH quarterly_actuals AS (
  SELECT
    CONCAT('Q', CAST(EXTRACT(QUARTER FROM DATE(ChargePeriodStart)) AS STRING),
           ' ', CAST(EXTRACT(YEAR FROM DATE(ChargePeriodStart)) AS STRING)) as quarter,
    DATE_TRUNC(DATE(ChargePeriodStart), QUARTER) as quarter_start,
    ROUND(SUM(EffectiveCost), 2) as quarterly_cost,
    COUNT(DISTINCT DATE(ChargePeriodStart)) as days_of_data,
    DATE_DIFF(
      DATE_SUB(DATE_TRUNC(DATE_ADD(DATE(ChargePeriodStart), INTERVAL 3 MONTH), QUARTER), INTERVAL 1 DAY),
      DATE_TRUNC(DATE(ChargePeriodStart), QUARTER),
      DAY
    ) + 1 as total_days_in_quarter
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(DATE_TRUNC(CURRENT_DATE(), QUARTER), INTERVAL 12 MONTH)
    AND ChargeCategory = 'usage'
  GROUP BY quarter, quarter_start
),
current_quarter_progress AS (
  SELECT
    CONCAT('Q', CAST(EXTRACT(QUARTER FROM CURRENT_DATE()) AS STRING),
           ' ', CAST(EXTRACT(YEAR FROM CURRENT_DATE()) AS STRING)) as quarter,
    DATE_TRUNC(CURRENT_DATE(), QUARTER) as quarter_start,
    ROUND(SUM(EffectiveCost), 2) as qtd_cost,
    COUNT(DISTINCT DATE(ChargePeriodStart)) as days_elapsed,
    DATE_DIFF(
      DATE_SUB(DATE_TRUNC(DATE_ADD(CURRENT_DATE(), INTERVAL 3 MONTH), QUARTER), INTERVAL 1 DAY),
      DATE_TRUNC(CURRENT_DATE(), QUARTER),
      DAY
    ) + 1 as total_days_in_quarter
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_TRUNC(CURRENT_DATE(), QUARTER)
    AND DATE(ChargePeriodStart) < CURRENT_DATE()
    AND ChargeCategory = 'usage'
  GROUP BY quarter, quarter_start
)
SELECT
  qa.quarter,
  qa.quarter_start,
  CASE
    WHEN qa.quarter_start = DATE_TRUNC(CURRENT_DATE(), QUARTER) THEN 'Current (In Progress)'
    ELSE 'Historical'
  END as quarter_status,
  COALESCE(cq.qtd_cost, qa.quarterly_cost) as actual_cost,
  CASE
    WHEN qa.quarter_start = DATE_TRUNC(CURRENT_DATE(), QUARTER)
    THEN ROUND((cq.qtd_cost / cq.days_elapsed) * cq.total_days_in_quarter, 2)
    ELSE qa.quarterly_cost
  END as forecasted_quarterly_cost,
  CASE
    WHEN qa.quarter_start = DATE_TRUNC(CURRENT_DATE(), QUARTER)
    THEN ROUND(cq.days_elapsed / cq.total_days_in_quarter * 100, 1)
    ELSE 100.0
  END as percent_complete,
  LAG(qa.quarterly_cost) OVER (ORDER BY qa.quarter_start) as previous_quarter_cost,
  ROUND(
    CASE
      WHEN qa.quarter_start = DATE_TRUNC(CURRENT_DATE(), QUARTER)
      THEN ((cq.qtd_cost / cq.days_elapsed) * cq.total_days_in_quarter) -
           LAG(qa.quarterly_cost) OVER (ORDER BY qa.quarter_start)
      ELSE qa.quarterly_cost - LAG(qa.quarterly_cost) OVER (ORDER BY qa.quarter_start)
    END,
    2
  ) as qoq_change,
  ROUND(
    CASE
      WHEN qa.quarter_start = DATE_TRUNC(CURRENT_DATE(), QUARTER)
      THEN (((cq.qtd_cost / cq.days_elapsed) * cq.total_days_in_quarter) -
            LAG(qa.quarterly_cost) OVER (ORDER BY qa.quarter_start)) /
           NULLIF(LAG(qa.quarterly_cost) OVER (ORDER BY qa.quarter_start), 0) * 100
      ELSE (qa.quarterly_cost - LAG(qa.quarterly_cost) OVER (ORDER BY qa.quarter_start)) /
           NULLIF(LAG(qa.quarterly_cost) OVER (ORDER BY qa.quarter_start), 0) * 100
    END,
    2
  ) as qoq_change_pct
FROM quarterly_actuals qa
LEFT JOIN current_quarter_progress cq ON qa.quarter = cq.quarter
ORDER BY qa.quarter_start DESC;

-- Expected Output: Quarterly trends with current quarter forecast
-- Use: Board reporting, quarterly business reviews


-- ============================================================================
-- FORECAST 10: Amortized Cost Forecast - Month over Month by Service Dimensions
-- ============================================================================
-- Question: How are amortized costs trending month over month across services?
-- Persona: Finance Team, CFO, Controller
-- Capability: Forecasting, Financial Planning
-- Method: Month-over-month amortized cost analysis by service dimensions
-- FOCUS Use Case: https://focus.finops.org/use-case/forecast-amortized-costs/

WITH monthly_amortized_costs AS (
  SELECT
    DATE_TRUNC(DATE(ChargePeriodStart), MONTH) as billing_month,
    ProviderName,
    ServiceCategory,
    ServiceName,
    ChargeCategory,
    ROUND(SUM(EffectiveCost), 2) as total_effective_cost
  FROM `your-project.your-dataset.focus_v1_0`
  WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 12 MONTH)
  GROUP BY billing_month, ProviderName, ServiceCategory, ServiceName, ChargeCategory
),
cost_trends AS (
  SELECT
    billing_month,
    ProviderName,
    ServiceCategory,
    ServiceName,
    ChargeCategory,
    total_effective_cost,
    -- Previous month cost
    LAG(total_effective_cost, 1) OVER (
      PARTITION BY ProviderName, ServiceCategory, ServiceName, ChargeCategory
      ORDER BY billing_month
    ) as prev_month_cost,
    -- Previous quarter same month (for seasonality)
    LAG(total_effective_cost, 3) OVER (
      PARTITION BY ProviderName, ServiceCategory, ServiceName, ChargeCategory
      ORDER BY billing_month
    ) as prev_quarter_cost,
    -- 3-month moving average
    AVG(total_effective_cost) OVER (
      PARTITION BY ProviderName, ServiceCategory, ServiceName, ChargeCategory
      ORDER BY billing_month
      ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) as three_month_avg
  FROM monthly_amortized_costs
),
growth_metrics AS (
  SELECT
    billing_month,
    ProviderName,
    ServiceCategory,
    ServiceName,
    ChargeCategory,
    total_effective_cost,
    prev_month_cost,
    three_month_avg,
    -- Month-over-month change
    ROUND(total_effective_cost - prev_month_cost, 2) as mom_change,
    ROUND((total_effective_cost - prev_month_cost) / NULLIF(prev_month_cost, 0) * 100, 2) as mom_change_pct,
    -- Variance from 3-month average
    ROUND(total_effective_cost - three_month_avg, 2) as variance_from_avg,
    ROUND((total_effective_cost - three_month_avg) / NULLIF(three_month_avg, 0) * 100, 2) as variance_from_avg_pct
  FROM cost_trends
  WHERE prev_month_cost IS NOT NULL  -- Only show trends with historical data
),
forecast_next_month AS (
  SELECT
    ServiceCategory,
    ServiceName,
    ChargeCategory,
    -- Use most recent month as baseline
    MAX(CASE WHEN billing_month = (SELECT MAX(billing_month) FROM growth_metrics)
      THEN total_effective_cost END) as current_month_cost,
    -- Average monthly growth rate over last 6 months
    AVG(CASE WHEN billing_month >= DATE_SUB((SELECT MAX(billing_month) FROM growth_metrics), INTERVAL 6 MONTH)
      THEN mom_change_pct END) as avg_growth_rate_6m,
    -- Forecast next month
    ROUND(
      MAX(CASE WHEN billing_month = (SELECT MAX(billing_month) FROM growth_metrics)
        THEN total_effective_cost END) *
      (1 + AVG(CASE WHEN billing_month >= DATE_SUB((SELECT MAX(billing_month) FROM growth_metrics), INTERVAL 6 MONTH)
        THEN mom_change_pct END) / 100),
      2
    ) as forecast_next_month
  FROM growth_metrics
  GROUP BY ServiceCategory, ServiceName, ChargeCategory
)
SELECT
  gm.billing_month,
  gm.ProviderName,
  gm.ServiceCategory,
  gm.ServiceName,
  gm.ChargeCategory,
  gm.total_effective_cost as amortized_cost,
  gm.prev_month_cost,
  gm.mom_change,
  gm.mom_change_pct,
  ROUND(gm.three_month_avg, 2) as three_month_avg,
  gm.variance_from_avg,
  gm.variance_from_avg_pct,
  -- Add forecast for most recent month
  CASE
    WHEN gm.billing_month = (SELECT MAX(billing_month) FROM growth_metrics)
    THEN f.forecast_next_month
    ELSE NULL
  END as forecast_next_month
FROM growth_metrics gm
LEFT JOIN forecast_next_month f
  ON gm.ServiceCategory = f.ServiceCategory
  AND gm.ServiceName = f.ServiceName
  AND gm.ChargeCategory = f.ChargeCategory
WHERE gm.total_effective_cost > 10  -- Filter out negligible costs
ORDER BY gm.billing_month DESC, gm.total_effective_cost DESC;

-- Expected Output: Month-over-month amortized cost trends with forecasts
-- Use: Financial planning, budget variance analysis, service-level forecasting
-- Notes:
--   - EffectiveCost represents amortized costs (includes commitment amortization)
--   - Breaks down by Provider, ServiceCategory, ServiceName, ChargeCategory per FOCUS spec
--   - Shows month-over-month trends and forecasts next month based on 6-month average growth


-- ============================================================================
-- FORECAST 11: Machine Learning-Ready Dataset Export
-- ============================================================================
-- Question: Export data for advanced ML-based forecasting
-- Persona: Data Science Team, FinOps Practitioner
-- Capability: Forecasting, Advanced Analytics
-- Method: Feature engineering for time series forecasting

SELECT
  DATE(ChargePeriodStart) as date,
  EXTRACT(YEAR FROM DATE(ChargePeriodStart)) as year,
  EXTRACT(MONTH FROM DATE(ChargePeriodStart)) as month,
  EXTRACT(DAYOFWEEK FROM DATE(ChargePeriodStart)) as day_of_week,
  EXTRACT(DAYOFYEAR FROM DATE(ChargePeriodStart)) as day_of_year,
  CASE WHEN EXTRACT(DAYOFWEEK FROM DATE(ChargePeriodStart)) IN (1, 7) THEN 1 ELSE 0 END as is_weekend,
  ServiceName,
  RegionId,
  PricingCategory,
  -- Aggregated metrics
  ROUND(SUM(EffectiveCost), 2) as daily_cost,
  ROUND(SUM(BilledCost), 2) as daily_billed_cost,
  ROUND(SUM(ConsumedQuantity), 2) as daily_quantity,
  COUNT(*) as charge_count,
  COUNT(DISTINCT ResourceId) as unique_resources,
  -- Rolling averages (lag features)
  ROUND(AVG(SUM(EffectiveCost)) OVER (
    PARTITION BY ServiceName
    ORDER BY DATE(ChargePeriodStart)
    ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING
  ), 2) as cost_7day_avg,
  ROUND(AVG(SUM(EffectiveCost)) OVER (
    PARTITION BY ServiceName
    ORDER BY DATE(ChargePeriodStart)
    ROWS BETWEEN 30 PRECEDING AND 1 PRECEDING
  ), 2) as cost_30day_avg,
  -- Credits received
  ROUND(SUM(BilledCost) - SUM(EffectiveCost), 2) as daily_credits
FROM `your-project.your-dataset.focus_v1_0`
WHERE DATE(ChargePeriodStart) >= DATE_SUB(CURRENT_DATE(), INTERVAL 365 DAY)
  AND ChargeCategory = 'usage'
GROUP BY date, year, month, day_of_week, day_of_year, is_weekend, ServiceName, RegionId, PricingCategory
ORDER BY date DESC, ServiceName;

-- Expected Output: ML-ready time series dataset
-- Use: Advanced forecasting with Python/R, Prophet, ARIMA, LSTM models
-- Next Steps: Export to CSV, train models in Vertex AI or external tools


-- ============================================================================
-- NOTES ON FORECASTING BEST PRACTICES
-- ============================================================================
--
-- 1. Choose the right forecast horizon:
--    - Short-term (1-3 months): Use recent trends, higher accuracy
--    - Long-term (6-12 months): Include seasonality, lower accuracy
--
-- 2. Update forecasts regularly:
--    - Run weekly or monthly to capture changing patterns
--    - Adjust for known events (launches, migrations, etc.)
--
-- 3. Communicate uncertainty:
--    - Always provide confidence intervals (low/high estimates)
--    - Explain assumptions to stakeholders
--
-- 4. Validate forecasts:
--    - Compare forecasts to actuals each month
--    - Calculate Mean Absolute Percentage Error (MAPE)
--    - Adjust models based on performance
--
-- 5. Consider external factors:
--    - Product launches
--    - Marketing campaigns
--    - Infrastructure migrations
--    - Commitment renewals/expirations
--
-- 6. Combine methods:
--    - Use simple linear trends for stable services
--    - Apply seasonality for cyclical patterns
--    - Leverage ML for complex, multi-variable forecasts
--
-- 7. Document assumptions:
--    - Record growth rates, seasonal factors
--    - Note any manual adjustments made
--    - Track forecast accuracy over time
--
-- ============================================================================
