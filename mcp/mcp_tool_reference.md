# MCP FOCUS Tool Reference

Complete technical reference for all 15 MCP tools provided in `mcp_tools.yaml`.

## Table of Contents

- [Cost Analysis Tools](#cost-analysis-tools)
- [Forecasting Tools](#forecasting-tools)
- [Optimization Tools](#optimization-tools)
- [Toolsets](#toolsets)
- [Parameter Types](#parameter-types)

---

## Cost Analysis Tools

### 1. get_total_spend

**Description:** Get total cloud spend over a time period with monthly breakdown. Shows billed cost, effective cost, and savings from credits/discounts.

**Use Cases:**
- Monthly spending reports
- Executive summaries
- Budget variance analysis
- Savings tracking

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `days_back` | integer | Yes | Number of days to look back | 30, 90, 365 |

**Output Columns:**
- `billing_month` - Month of charges
- `currency` - Billing currency (USD, EUR, etc.)
- `total_billed_cost` - Total invoiced amount
- `total_effective_cost` - Total after credits
- `total_savings` - Credits/discounts received
- `number_of_accounts` - Distinct billing accounts

**Example Usage:**
```
Natural Language: "What did we spend in the last 90 days?"
Parameters: {"days_back": 90}
```

**Sample Output:**
```
billing_month: 2024-10-01
currency: USD
total_billed_cost: 15234.56
total_effective_cost: 12987.45
total_savings: 2247.11
number_of_accounts: 1
```

---

### 2. get_cost_by_service

**Description:** Get cloud costs broken down by service. Shows which services are driving costs with percentages of total spend.

**Use Cases:**
- Service-level cost analysis
- Identifying cost drivers
- Budget allocation by service
- Cost optimization targets

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `days_back` | integer | Yes | Number of days to look back | 30 |
| `limit_results` | integer | Yes | Number of top services to return | 20 |

**Output Columns:**
- `ServiceName` - GCP service name
- `total_cost` - Total effective cost
- `avg_cost_per_charge` - Average cost per line item
- `number_of_charges` - Count of charge records
- `percent_of_total` - Percentage of total spend

**Example Usage:**
```
Natural Language: "Show me the top 10 services by cost"
Parameters: {"days_back": 30, "limit_results": 10}
```

**Sample Output:**
```
ServiceName: Compute Engine
total_cost: 4523.12
avg_cost_per_charge: 12.34
number_of_charges: 367
percent_of_total: 35.80
```

---

### 3. get_cost_by_region

**Description:** Get cloud costs broken down by GCP region. Useful for understanding geographic cost distribution.

**Use Cases:**
- Regional cost analysis
- Multi-region strategy planning
- Compliance and data residency review
- Geographic optimization

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `days_back` | integer | Yes | Number of days to look back | 30 |

**Output Columns:**
- `RegionId` - GCP region ID (e.g., us-central1)
- `RegionName` - Human-readable name (e.g., Iowa)
- `services_used` - Count of distinct services
- `total_cost` - Total effective cost
- `avg_cost` - Average cost per charge

**Example Usage:**
```
Natural Language: "Which regions are we spending the most in?"
Parameters: {"days_back": 30}
```

**Sample Output:**
```
RegionId: us-central1
RegionName: Iowa
services_used: 12
total_cost: 5432.10
avg_cost: 23.45
```

---

### 4. get_daily_costs

**Description:** Get daily cost trends with 7-day moving average. Useful for identifying spending patterns and trends.

**Use Cases:**
- Daily spend tracking
- Trend analysis
- Anomaly detection
- Budget burn rate monitoring

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `days_back` | integer | Yes | Number of days to look back | 30, 60, 90 |

**Output Columns:**
- `usage_date` - Date of charges
- `daily_cost` - Total cost for the day
- `seven_day_avg` - Rolling 7-day average
- `services_used` - Distinct services that day

**Example Usage:**
```
Natural Language: "Show me daily costs for the past 60 days"
Parameters: {"days_back": 60}
```

**Sample Output:**
```
usage_date: 2024-10-24
daily_cost: 425.67
seven_day_avg: 398.23
services_used: 15
```

---

### 5. find_cost_anomalies

**Description:** Detect unusual cost spikes by service using statistical analysis. Z-score > 1.5 indicates anomaly.

**Use Cases:**
- Cost spike detection
- Unexpected spend alerts
- Service behavior analysis
- Budget risk identification

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `lookback_days` | integer | Yes | Days to analyze for baseline | 30, 60 |
| `recent_days` | integer | Yes | Recent days to check for anomalies | 7 |

**Output Columns:**
- `usage_date` - Date of anomaly
- `ServiceName` - Service with anomaly
- `daily_cost` - Cost on anomaly date
- `avg_daily_cost` - Historical average
- `z_score` - Statistical deviation score
- `anomaly_severity` - High/Moderate/Normal

**Example Usage:**
```
Natural Language: "Find cost anomalies in the past week"
Parameters: {"lookback_days": 30, "recent_days": 7}
```

**Sample Output:**
```
usage_date: 2024-10-23
ServiceName: Compute Engine
daily_cost: 1234.56
avg_daily_cost: 425.67
z_score: 2.80
anomaly_severity: High Anomaly
```

**Z-Score Interpretation:**
- `< 1.5` - Normal variation
- `1.5 - 2.0` - Moderate anomaly
- `> 2.0` - High anomaly (investigate immediately)

---

## Forecasting Tools

### 6. forecast_next_month

**Description:** Forecast next month's total cloud spend based on linear trend from recent history.

**Use Cases:**
- Monthly budget planning
- Financial forecasting
- Capacity planning
- Executive reporting

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `history_days` | integer | Yes | Days of history for forecast model | 60, 90 |

**Output Columns:**
- `forecast_month` - Month being forecasted
- `forecasted_cost` - Predicted total cost
- `avg_daily_cost_base` - Average daily cost (baseline)
- `daily_growth_rate` - Daily cost increase rate

**Example Usage:**
```
Natural Language: "What will we spend next month?"
Parameters: {"history_days": 90}
```

**Sample Output:**
```
forecast_month: 2024-11-01
forecasted_cost: 14567.89
avg_daily_cost_base: 456.78
daily_growth_rate: 0.0023
```

---

### 7. forecast_by_service

**Description:** Forecast next month's cost for each service with confidence intervals.

**Use Cases:**
- Service-level budget planning
- Resource allocation
- Growth projection
- Risk assessment

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `history_days` | integer | Yes | Days to analyze | 60 |

**Output Columns:**
- `ServiceName` - Service name
- `avg_daily_cost` - Current average daily cost
- `days_in_next_month` - Days in forecast period
- `forecasted_monthly_cost` - Expected cost
- `low_estimate` - Conservative estimate (avg - stddev)
- `high_estimate` - Optimistic estimate (avg + stddev)

**Example Usage:**
```
Natural Language: "Forecast costs by service for next month"
Parameters: {"history_days": 60}
```

**Sample Output:**
```
ServiceName: Compute Engine
avg_daily_cost: 156.26
days_in_next_month: 30
forecasted_monthly_cost: 4687.80
low_estimate: 4234.12
high_estimate: 5141.48
```

---

### 8. check_budget_runway

**Description:** Calculate when budget will be exhausted based on current burn rate. Helps avoid budget overruns.

**Use Cases:**
- Budget management
- Spend alerts
- Financial planning
- Cost control

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `monthly_budget` | float | Yes | Monthly budget amount in dollars | 10000.00 |

**Output Columns:**
- `avg_daily_burn_rate` - Average spend per day
- `days_remaining_in_month` - Days left in current month
- `month_to_date_spend` - Spend so far this month
- `forecasted_remaining_spend` - Expected spend for rest of month
- `forecasted_month_end_total` - Total month-end projection
- `monthly_budget` - Budget amount provided
- `projected_variance` - Over/under budget amount
- `days_until_budget_exhausted` - Days until hitting limit

**Example Usage:**
```
Natural Language: "Check if we'll hit our $15,000 budget"
Parameters: {"monthly_budget": 15000.00}
```

**Sample Output:**
```
avg_daily_burn_rate: 450.00
days_remaining_in_month: 12
month_to_date_spend: 6234.56
forecasted_remaining_spend: 5400.00
forecasted_month_end_total: 11634.56
monthly_budget: 15000.00
projected_variance: 3365.44 (under budget)
days_until_budget_exhausted: 12
```

**Budget Status Interpretation:**
- `projected_variance > 0` - Under budget ✅
- `projected_variance < 0` - Over budget ⚠️
- `days_until_budget_exhausted < days_remaining` - Action needed 🚨

---

## Optimization Tools

### 9. find_commitment_savings

**Description:** Analyze savings from commitments (CUDs) and identify optimization opportunities.

**Use Cases:**
- CUD performance tracking
- Savings verification
- Commitment renewal planning
- ROI analysis

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `months_back` | integer | Yes | Number of months to analyze | 3, 6 |

**Output Columns:**
- `month` - Month of analysis
- `CommitmentDiscountCategory` - Spend or Usage CUD
- `number_of_commitments` - Count of active commitments
- `billed_cost` - Cost before commitment discount
- `effective_cost` - Cost after discount
- `commitment_savings` - Total savings amount
- `savings_percentage` - Percentage saved

**Example Usage:**
```
Natural Language: "How much are we saving from commitments?"
Parameters: {"months_back": 3}
```

**Sample Output:**
```
month: 2024-10-01
CommitmentDiscountCategory: Usage
number_of_commitments: 2
billed_cost: 5267.89
effective_cost: 4033.33
commitment_savings: 1234.56
savings_percentage: 23.43
```

---

### 10. find_untagged_resources

**Description:** Identify resources that lack required cost allocation tags.

**Use Cases:**
- Tag compliance audit
- Cost allocation improvement
- Resource governance
- Chargeback/showback preparation

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `days_back` | integer | Yes | Number of days to analyze | 7, 30 |

**Output Columns:**
- `ServiceName` - Service of untagged resource
- `ResourceType` - Type (instances, disks, etc.)
- `ResourceId` - Unique resource identifier
- `ResourceName` - Human-readable name
- `RegionName` - Geographic location
- `untagged_cost` - Cost of untagged resource
- `days_active` - Days resource had charges

**Example Usage:**
```
Natural Language: "Show me untagged resources from last week"
Parameters: {"days_back": 7}
```

**Sample Output:**
```
ServiceName: Compute Engine
ResourceType: instances
ResourceId: //compute.googleapis.com/projects/my-project/zones/us-central1-a/instances/vm-12345
ResourceName: production-web-server-01
RegionName: Iowa
untagged_cost: 456.78
days_active: 7
```

**Note:** Query checks for tags: `environment`, `team`, `cost-center`. Customize in YAML.

---

### 11. get_cost_by_tag

**Description:** Get costs broken down by specific tag key (e.g., team, environment, project).

**Use Cases:**
- Team/department chargeback
- Environment cost tracking
- Project budgeting
- Cost center allocation

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `tag_key` | string | Yes | Tag key to analyze | "team", "environment" |
| `days_back` | integer | Yes | Number of days to analyze | 30 |

**Output Columns:**
- `tag_key` - The tag key queried
- `tag_value` - Tag value (team name, env, etc.)
- `tagged_resources` - Count of resources with tag
- `total_cost` - Total effective cost
- `services_used` - Distinct services

**Example Usage:**
```
Natural Language: "Show me costs by team"
Parameters: {"tag_key": "team", "days_back": 30}
```

**Sample Output:**
```
tag_key: team
tag_value: platform-engineering
tagged_resources: 45
total_cost: 4567.89
services_used: 8
```

---

### 12. compare_regional_pricing

**Description:** Compare cost per unit across different regions for a specific service.

**Use Cases:**
- Regional pricing analysis
- Migration cost estimation
- Multi-region strategy
- Cost optimization

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `service_name` | string | Yes | Service to compare | "Compute Engine" |
| `days_back` | integer | Yes | Days to analyze | 30 |

**Output Columns:**
- `ServiceName` - Service analyzed
- `RegionName` - Region name
- `total_usage` - Quantity consumed
- `ConsumedUnit` - Unit of measure
- `total_cost` - Total cost in region
- `cost_per_unit` - Unit pricing

**Example Usage:**
```
Natural Language: "Compare Compute Engine pricing across regions"
Parameters: {"service_name": "Compute Engine", "days_back": 30}
```

**Sample Output:**
```
ServiceName: Compute Engine
RegionName: Iowa
total_usage: 12345.00
ConsumedUnit: hour
total_cost: 2345.67
cost_per_unit: 0.190000
```

---

### 13. get_month_over_month_growth

**Description:** Calculate month-over-month cost growth for all services.

**Use Cases:**
- Growth trend analysis
- Budget forecasting
- Service optimization
- Executive reporting

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `months_back` | integer | Yes | Months to analyze | 6, 12 |

**Output Columns:**
- `month` - Month of data
- `ServiceName` - Service name
- `monthly_cost` - Cost for the month
- `previous_month_cost` - Prior month cost
- `month_over_month_change` - Absolute change
- `percent_change` - Percentage change

**Example Usage:**
```
Natural Language: "Show me month-over-month growth"
Parameters: {"months_back": 6}
```

**Sample Output:**
```
month: 2024-10-01
ServiceName: BigQuery
monthly_cost: 2456.78
previous_month_cost: 1987.65
month_over_month_change: 469.13
percent_change: 23.60
```

---

### 14. get_top_resources

**Description:** Find the most expensive individual resources (VMs, disks, datasets, etc.).

**Use Cases:**
- Resource optimization
- Rightsizing candidates
- Cost reduction targets
- Resource inventory

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `days_back` | integer | Yes | Days to analyze | 30 |
| `limit_results` | integer | Yes | Number of top resources | 50 |

**Output Columns:**
- `ResourceType` - Type of resource
- `ResourceId` - Unique identifier
- `ResourceName` - Human-readable name
- `ServiceName` - GCP service
- `RegionName` - Geographic location
- `total_cost` - Total cost over period
- `avg_daily_cost` - Average daily cost
- `days_active` - Days with charges

**Example Usage:**
```
Natural Language: "Show me the top 20 most expensive resources"
Parameters: {"days_back": 30, "limit_results": 20}
```

**Sample Output:**
```
ResourceType: instances
ResourceId: //compute.googleapis.com/.../instances/prod-web-01
ResourceName: production-web-server-01
ServiceName: Compute Engine
RegionName: Iowa
total_cost: 876.54
avg_daily_cost: 29.22
days_active: 30
```

---

### 15. analyze_credit_usage

**Description:** Breakdown of all credits and discounts received by type.

**Use Cases:**
- Credit tracking
- Discount analysis
- Savings verification
- Financial reporting

**Parameters:**

| Name | Type | Required | Description | Example |
|------|------|----------|-------------|---------|
| `months_back` | integer | Yes | Months to analyze | 3, 6 |

**Output Columns:**
- `month` - Month of credits
- `credit_type` - Type of credit/discount
- `number_of_credits` - Count of credit applications
- `total_credit_amount` - Total credit value (negative)
- `services_receiving_credits` - Services with credits

**Example Usage:**
```
Natural Language: "Show me all credits we received"
Parameters: {"months_back": 3}
```

**Sample Output:**
```
month: 2024-10-01
credit_type: SUSTAINED_USE_DISCOUNT
number_of_credits: 245
total_credit_amount: -1234.56
services_receiving_credits: 5
```

**Common Credit Types:**
- `SUSTAINED_USE_DISCOUNT` - Automatic usage discounts
- `COMMITTED_USE_DISCOUNT` - CUD discounts
- `PROMOTIONAL` - Promotional credits
- `FREE_TIER` - Free tier usage
- `SPENDING_BASED_DISCOUNT` - Volume discounts

---

## Toolsets

Toolsets group related tools for specific personas.

### finance-tools
**Target Persona:** Finance Team, CFO, Controllers

**Included Tools:**
1. `get_total_spend` - Monthly spend tracking
2. `get_daily_costs` - Daily burn rate
3. `check_budget_runway` - Budget management
4. `forecast_next_month` - Budget planning
5. `get_month_over_month_growth` - Growth analysis
6. `analyze_credit_usage` - Discount tracking

**Use Cases:**
- Budget management
- Financial reporting
- Variance analysis
- Forecasting

---

### engineering-tools
**Target Persona:** Engineering Leads, Developers, Architects

**Included Tools:**
1. `get_cost_by_service` - Service costs
2. `get_cost_by_region` - Regional distribution
3. `get_top_resources` - Resource inventory
4. `compare_regional_pricing` - Pricing comparison
5. `find_cost_anomalies` - Spike detection
6. `get_cost_by_tag` - Team allocation

**Use Cases:**
- Resource optimization
- Architecture decisions
- Team cost tracking
- Performance analysis

---

### finops-tools
**Target Persona:** FinOps Practitioners, Cloud Cost Engineers

**Included Tools:**
1. `get_total_spend` - Overall spend
2. `forecast_by_service` - Service forecasts
3. `find_commitment_savings` - CUD analysis
4. `find_untagged_resources` - Governance
5. `find_cost_anomalies` - Anomaly detection
6. `check_budget_runway` - Budget tracking

**Use Cases:**
- Cost optimization
- Savings identification
- Policy enforcement
- Proactive management

---

### executive-tools
**Target Persona:** C-Level, VPs, Directors

**Included Tools:**
1. `get_total_spend` - High-level spend
2. `get_month_over_month_growth` - Growth trends
3. `forecast_next_month` - Future projections
4. `find_commitment_savings` - ROI tracking
5. `get_cost_by_service` - Service breakdown

**Use Cases:**
- Executive reporting
- Strategic planning
- Board presentations
- Investment decisions

---

### all-focus-tools
**Target Persona:** All users

**Included Tools:** All 15 tools

**Use Cases:** Full access to all capabilities

---

## Parameter Types

### integer
Whole numbers for counts, days, limits

**Examples:**
- `days_back: 30`
- `limit_results: 20`
- `months_back: 6`

**Valid Range:** Positive integers > 0

---

### float
Decimal numbers for currency amounts

**Examples:**
- `monthly_budget: 10000.00`
- `monthly_budget: 15500.50`

**Valid Range:** Positive numbers > 0

---

### string
Text values for names, keys, filters

**Examples:**
- `tag_key: "team"`
- `service_name: "Compute Engine"`

**Format:** Quoted strings, case-sensitive

---

## Common Patterns

### Time Ranges

**Last Week:**
```yaml
days_back: 7
```

**Last Month:**
```yaml
days_back: 30
```

**Last Quarter:**
```yaml
days_back: 90
months_back: 3
```

**Last Year:**
```yaml
days_back: 365
months_back: 12
```

---

### Typical Limits

**Quick Overview:**
```yaml
limit_results: 10
```

**Standard Analysis:**
```yaml
limit_results: 20
```

**Deep Dive:**
```yaml
limit_results: 50
```

---

### Budget Values

**Development:**
```yaml
monthly_budget: 5000.00
```

**Production:**
```yaml
monthly_budget: 25000.00
```

**Enterprise:**
```yaml
monthly_budget: 100000.00
```

---

## Response Formats

All tools return data in tabular format suitable for:
- Display in AI chat interfaces
- Export to CSV
- Visualization in dashboards
- Further analysis in Python/R

**Common Fields Across Tools:**
- Costs are rounded to 2 decimal places
- Percentages to 2 decimal places
- Dates in ISO 8601 format
- Currencies in billing currency (usually USD)

---

## Error Handling

### Common Errors

**"Table not found"**
- Verify FOCUS view exists
- Check table path in tools.yaml

**"Invalid parameter type"**
- Ensure integer parameters don't have decimals
- Use quotes for string parameters

**"No data returned"**
- Check date range isn't too far back
- Verify FOCUS view has data for period

**"Permission denied"**
- Verify BigQuery IAM permissions
- Check ADC is configured

---

## Best Practices

### Parameter Selection

1. **Start with shorter time ranges** for faster queries
2. **Use appropriate limits** to avoid overwhelming results
3. **Match history to forecast horizon** (e.g., 90 days history for monthly forecast)
4. **Consider data freshness** - most recent data is 24-48 hours old

### Performance Tips

1. **Shorter date ranges** = faster queries
2. **Add limits** to top-N queries
3. **Use specific services** instead of all services
4. **Cache results** for repeated queries

### Cost Management

1. **Limit query frequency** to control BigQuery costs
2. **Use materialized views** for large datasets
3. **Filter early** with WHERE clauses
4. **Monitor query bytes** processed

---

## Extending the Tools

To add custom tools to `mcp_tools.yaml`:

1. **Define the tool:**
```yaml
tools:
  my_custom_tool:
    kind: bigquery-sql
    source: focus-bigquery
    description: "Description of what it does"
    parameters:
      - name: param_name
        type: integer
        description: "Parameter description"
    statement: |
      SELECT ...
      FROM `YOUR_PROJECT.YOUR_DATASET.YOUR_FOCUS_VIEW`
      WHERE condition = @param_name;
```

2. **Add to toolset:**
```yaml
toolsets:
  my-toolset:
    - my_custom_tool
    - get_total_spend
```

3. **Test with MCP Inspector:**
```bash
mcp-inspector toolbox --tools-file mcp_tools.yaml
```

---

## Support

For issues with:
- **Tools:** Check this reference and setup guide
- **MCP Toolbox:** [GitHub Issues](https://github.com/googleapis/genai-toolbox/issues)
- **FOCUS Spec:** [FOCUS Documentation](https://focus.finops.org/)
- **BigQuery:** [GCP Support](https://cloud.google.com/support)
