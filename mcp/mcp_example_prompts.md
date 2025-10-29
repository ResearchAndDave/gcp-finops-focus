# MCP FOCUS Example Prompts

This guide provides natural language examples for querying your FOCUS cost data through Claude Desktop, Gemini CLI, or other MCP-compatible agents.

## How It Works

Once MCP Toolbox is configured, you can ask questions in plain English. The AI assistant will:
1. Understand your intent
2. Select the appropriate FOCUS tool
3. Set parameters automatically
4. Execute the query
5. Return formatted results

---

## Quick Reference: Tool Mapping

| What You Ask | Tool Used |
|--------------|-----------|
| "What did we spend..." | `get_total_spend` |
| "Show me costs by service..." | `get_cost_by_service` |
| "Which regions..." | `get_cost_by_region` |
| "What are the daily costs..." | `get_daily_costs` |
| "Find cost anomalies..." | `find_cost_anomalies` |
| "Forecast next month..." | `forecast_next_month` |
| "When will we hit budget..." | `check_budget_runway` |
| "Show me untagged resources..." | `find_untagged_resources` |

---

## Cost Analysis Prompts

### Total Spending

**Simple Queries:**
```
What did we spend last month?
```
```
Show me our total cloud costs for the past 90 days
```
```
What's our spending trend over the last 6 months?
```

**Advanced Queries:**
```
Break down our spending by month for the last year and show me the savings from discounts
```
```
Compare our spending this month versus last month
```

**Expected Response:**
> Based on your FOCUS data, here's your spending for the last 30 days:
> - **Total Billed Cost**: $15,234.56
> - **Total Effective Cost**: $12,987.45
> - **Total Savings**: $2,247.11 (14.7% discount rate)
> - **Number of Billing Accounts**: 1

---

### Service-Level Analysis

**Simple Queries:**
```
What are our top 5 most expensive services?
```
```
Show me costs by service for last month
```
```
Which services cost the most?
```

**Advanced Queries:**
```
Show me all services costing more than $100 last week
```
```
What percentage of our budget goes to Compute Engine versus BigQuery?
```
```
List our services ordered by cost with the number of charges for each
```

**Expected Response:**
> Here are your top 5 services by cost (last 30 days):
>
> 1. **Compute Engine**: $4,523.12 (35.8% of total)
> 2. **Cloud Storage**: $2,145.67 (17.0% of total)
> 3. **BigQuery**: $1,876.23 (14.8% of total)
> 4. **Cloud SQL**: $1,234.45 (9.8% of total)
> 5. **Cloud Load Balancing**: $876.34 (6.9% of total)

---

### Regional Analysis

**Simple Queries:**
```
Which regions are we spending the most in?
```
```
Show me costs by region for the past month
```
```
Where are we deploying resources geographically?
```

**Advanced Queries:**
```
Compare costs between us-central1 and us-east1
```
```
Show me which regions have the highest average cost per charge
```
```
List all regions we're using with their associated services
```

**Expected Response:**
> Your spending by region (last 30 days):
>
> | Region ID | Region Name | Services | Total Cost |
> |-----------|-------------|----------|------------|
> | us-central1 | Iowa | 12 | $5,432.10 |
> | us-east1 | South Carolina | 8 | $3,210.45 |
> | europe-west1 | Belgium | 6 | $2,145.32 |

---

### Daily Trends

**Simple Queries:**
```
What are my daily costs for the past week?
```
```
Show me the spending trend over the last 30 days
```
```
What was our average daily spend last month?
```

**Advanced Queries:**
```
Show me daily costs with a 7-day moving average for the past 60 days
```
```
Are our costs trending up or down this month?
```
```
Which days had unusually high spending?
```

**Expected Response:**
> Daily costs for the past 7 days:
>
> | Date | Daily Cost | 7-Day Avg | Services |
> |------|------------|-----------|----------|
> | 2024-10-24 | $425.67 | $398.23 | 15 |
> | 2024-10-23 | $412.34 | $395.12 | 14 |
> | 2024-10-22 | $389.45 | $392.45 | 16 |

---

### Anomaly Detection

**Simple Queries:**
```
Find any unusual cost spikes
```
```
Show me cost anomalies from the past week
```
```
Which services had unexpected costs recently?
```

**Advanced Queries:**
```
Analyze the last 30 days and find services with costs more than 2 standard deviations above normal
```
```
Show me moderate and high severity cost anomalies from yesterday
```
```
What caused the cost spike on October 23rd?
```

**Expected Response:**
> Found 3 cost anomalies in the past 7 days:
>
> **High Anomaly:**
> - **Service**: Compute Engine
> - **Date**: 2024-10-23
> - **Cost**: $1,234.56 (avg: $425.67)
> - **Z-Score**: 2.8
>
> **Moderate Anomalies:**
> - **BigQuery** on 2024-10-22: $876.23 (z-score: 1.7)
> - **Cloud Storage** on 2024-10-21: $654.32 (z-score: 1.6)

---

## Forecasting Prompts

### Next Month Forecast

**Simple Queries:**
```
What will we spend next month?
```
```
Forecast our costs for the next 30 days
```
```
Predict next month's cloud bill
```

**Advanced Queries:**
```
Forecast next month using the last 90 days of data
```
```
What's the expected cost and growth rate for next month?
```
```
Show me monthly forecasts for the next 3 months
```

**Expected Response:**
> **Forecast for November 2024:**
> - **Expected Cost**: $14,567.89
> - **Based on**: 90 days of historical data
> - **Daily Growth Rate**: 0.23%
> - **Confidence**: Historical average daily cost is $456.78

---

### Service-Level Forecasts

**Simple Queries:**
```
Forecast costs by service for next month
```
```
Which services will cost the most next month?
```
```
What will Compute Engine cost next month?
```

**Advanced Queries:**
```
Show me next month's forecast for each service with confidence intervals
```
```
Compare forecasted costs to current month actuals
```
```
Which services are projected to grow the fastest?
```

**Expected Response:**
> Service-level forecasts for next month:
>
> | Service | Forecast | Low Estimate | High Estimate |
> |---------|----------|--------------|---------------|
> | Compute Engine | $4,678.23 | $4,234.12 | $5,122.34 |
> | Cloud Storage | $2,234.56 | $1,987.34 | $2,481.78 |
> | BigQuery | $1,965.43 | $1,678.12 | $2,252.74 |

---

### Budget Runway

**Simple Queries:**
```
When will we hit our budget limit?
```
```
Are we on track to stay within budget this month?
```
```
How many days until we exceed our $10,000 budget?
```

**Advanced Queries:**
```
Given a monthly budget of $15,000, what's our current burn rate and projected variance?
```
```
Calculate our budget runway and tell me if we'll go over
```
```
Show me month-to-date spend and forecasted month-end total
```

**Expected Response:**
> **Budget Runway Analysis:**
> - **Monthly Budget**: $10,000.00
> - **Month-to-Date Spend**: $6,234.56
> - **Avg Daily Burn Rate**: $312.50
> - **Days Remaining**: 12
> - **Forecasted Remaining**: $3,750.00
> - **Month-End Total**: $9,984.56 ✅
> - **Projected Variance**: $15.44 (under budget)
> - **Status**: On track

**Over Budget Example:**
> ⚠️ **Budget Alert:**
> - **Monthly Budget**: $10,000.00
> - **Month-End Forecast**: $12,345.67
> - **Days Until Budget Exhausted**: 4 days
> - **Action**: Reduce spend by $195/day to stay within budget

---

## Optimization Prompts

### Commitment Savings

**Simple Queries:**
```
How much are we saving from commitments?
```
```
Show me our CUD savings for the past 3 months
```
```
What's our commitment discount utilization?
```

**Advanced Queries:**
```
Break down commitment savings by type (spend vs usage)
```
```
Calculate our average savings percentage from commitments
```
```
Show me which commitments are providing the most value
```

**Expected Response:**
> **Commitment Savings (Last 3 Months):**
>
> | Month | Type | Commitments | Savings | Savings % |
> |-------|------|-------------|---------|-----------|
> | Oct 2024 | Usage | 2 | $1,234.56 | 23.4% |
> | Oct 2024 | Spend | 1 | $876.23 | 15.6% |
> | Sep 2024 | Usage | 2 | $1,189.45 | 22.8% |
>
> **Total Savings**: $3,300.24 over 3 months

---

### Untagged Resources

**Simple Queries:**
```
Show me untagged resources
```
```
Which resources don't have proper cost allocation tags?
```
```
Find resources missing team or environment tags
```

**Advanced Queries:**
```
Show me the top 20 most expensive untagged resources from the past week
```
```
Calculate how much we're spending on untagged resources
```
```
List all Compute Engine instances without tags
```

**Expected Response:**
> **Top Untagged Resources (Last 7 Days):**
>
> | Resource Type | Resource ID | Service | Region | Cost |
> |---------------|-------------|---------|--------|------|
> | instances | instance-12345 | Compute Engine | us-central1 | $456.78 |
> | disks | disk-67890 | Compute Engine | us-east1 | $234.56 |
> | datasets | dataset-abc | BigQuery | us | $189.23 |
>
> **Total Untagged Cost**: $2,345.67 (18.6% of total spend)

---

### Tag-Based Allocation

**Simple Queries:**
```
Show me costs by team
```
```
How much did the engineering team spend?
```
```
Break down costs by environment (prod, dev, staging)
```

**Advanced Queries:**
```
Show me costs for each team, sorted by spend
```
```
Compare production vs non-production environment costs
```
```
Which cost-center has the highest cloud spend?
```

**Expected Response:**
> **Costs by Team (Last 30 Days):**
>
> | Team | Resources | Cost | Services |
> |------|-----------|------|----------|
> | platform-engineering | 45 | $4,567.89 | 8 |
> | data-analytics | 32 | $3,456.78 | 6 |
> | machine-learning | 28 | $2,987.65 | 5 |
> | web-applications | 19 | $1,876.54 | 7 |

---

### Regional Pricing Comparison

**Simple Queries:**
```
Compare Compute Engine pricing across regions
```
```
Which region is cheapest for storage?
```
```
Show me cost per unit by region for BigQuery
```

**Advanced Queries:**
```
For Compute Engine, show me the cost per unit in each region where we have usage
```
```
Which regions offer the best value for our workloads?
```
```
Compare us-central1 vs europe-west1 for all services
```

**Expected Response:**
> **Compute Engine Pricing by Region (Last 30 Days):**
>
> | Region | Total Usage | Unit | Total Cost | Cost/Unit |
> |--------|-------------|------|------------|-----------|
> | us-central1 | 12,345 | hour | $2,345.67 | $0.1900 |
> | us-east1 | 8,976 | hour | $1,795.20 | $0.2000 |
> | europe-west1 | 5,432 | hour | $1,195.04 | $0.2200 |
>
> 💡 **Insight**: us-central1 is 5% cheaper than us-east1

---

### Top Resources

**Simple Queries:**
```
What are our most expensive resources?
```
```
Show me the top 10 resources by cost
```
```
Which VMs cost the most?
```

**Advanced Queries:**
```
List the top 20 most expensive resources with their daily average costs
```
```
Show me resources that have been running for more than 30 days
```
```
Which resources cost more than $100 last month?
```

**Expected Response:**
> **Top 10 Resources by Cost (Last 30 Days):**
>
> | Type | Resource ID | Service | Region | Total Cost | Avg Daily |
> |------|-------------|---------|--------|------------|-----------|
> | instances | prod-web-01 | Compute Engine | us-central1 | $876.54 | $29.22 |
> | instances | data-proc-cluster | Compute Engine | us-west1 | $654.32 | $21.81 |
> | datasets | analytics-warehouse | BigQuery | us | $543.21 | $18.11 |

---

### Credit Analysis

**Simple Queries:**
```
What credits did we receive?
```
```
Show me all discounts and credits for last month
```
```
How much did sustained use discounts save us?
```

**Advanced Queries:**
```
Break down all credit types with amounts for the past 3 months
```
```
Which services received the most credits?
```
```
Compare promotional credits vs usage discounts
```

**Expected Response:**
> **Credits Received (Last 3 Months):**
>
> | Month | Credit Type | Count | Total Amount | Services |
> |-------|-------------|-------|--------------|----------|
> | Oct 2024 | SUSTAINED_USE_DISCOUNT | 245 | -$1,234.56 | 5 |
> | Oct 2024 | COMMITTED_USE_DISCOUNT | 89 | -$876.23 | 3 |
> | Oct 2024 | PROMOTIONAL | 12 | -$234.56 | 4 |
>
> **Total Credits**: -$2,345.35 (credits are negative = savings)

---

### Month-over-Month Growth

**Simple Queries:**
```
How are our costs growing month over month?
```
```
Show me cost growth trends
```
```
Which services are growing fastest?
```

**Advanced Queries:**
```
Calculate month-over-month growth for the past 6 months by service
```
```
Show me services with more than 10% monthly growth
```
```
Compare this month's growth to last month's growth
```

**Expected Response:**
> **Month-over-Month Growth (Top Services):**
>
> | Service | This Month | Last Month | Change | % Change |
> |---------|------------|------------|--------|----------|
> | BigQuery | $2,456.78 | $1,987.65 | +$469.13 | +23.6% 📈 |
> | Cloud Storage | $2,123.45 | $2,045.32 | +$78.13 | +3.8% ↗️ |
> | Compute Engine | $4,567.89 | $4,678.23 | -$110.34 | -2.4% ↘️ |

---

## Complex Multi-Tool Queries

These queries may require the AI to use multiple tools:

**Cross-Analysis:**
```
Show me our top 5 services, then forecast what they'll cost next month
```
```
Find cost anomalies and then show me the resources driving those costs
```
```
Compare our spending by region and tell me which region has the best pricing
```

**Comparative Analysis:**
```
Show me how much we're spending on untagged resources versus tagged resources
```
```
Compare our actual spend this month to what we forecasted last month
```
```
Calculate our commitment savings and show what percentage of our bill they represent
```

**Trend Analysis:**
```
Show me daily costs for the past 30 days and identify any anomalies
```
```
Calculate our monthly growth rate and project when we'll hit $20,000/month
```
```
Show me which teams are growing fastest and forecast their costs for next quarter
```

---

## Tips for Effective Prompts

### Be Specific with Time Ranges
✅ **Good**: "Show me costs for the last 30 days"
❌ **Vague**: "Show me recent costs"

### Specify Services When Relevant
✅ **Good**: "What did Compute Engine cost last month?"
❌ **Generic**: "How much did we spend?"

### Ask for Comparisons
✅ **Good**: "Compare this month to last month"
✅ **Good**: "Which region is cheaper?"

### Request Context
✅ **Good**: "Show me costs with percentages of total"
✅ **Good**: "Include confidence intervals in the forecast"

### Follow Up Questions
After getting results, you can ask:
- "Why did that happen?"
- "Show me more details about [specific item]"
- "What should I do about this?"
- "Create a summary for my manager"

---

## Example Conversation Flow

**You**: "What did we spend last month?"

**AI**: *Uses `get_total_spend` with days_back=30*
> You spent $12,456.78 last month with $1,234.56 in savings from discounts.

**You**: "Which services drove that cost?"

**AI**: *Uses `get_cost_by_service` with days_back=30*
> Your top services were: Compute Engine ($4,567), Cloud Storage ($2,345), and BigQuery ($1,876).

**You**: "Are those costs normal or did we have any spikes?"

**AI**: *Uses `find_cost_anomalies`*
> I found one anomaly: BigQuery had an unusual spike on Oct 23rd ($876 vs normal $425).

**You**: "Forecast what we'll spend next month"

**AI**: *Uses `forecast_next_month`*
> Based on trends, you'll likely spend $13,245 next month (6.3% increase).

**You**: "Will that exceed our $15,000 budget?"

**AI**: *Uses `check_budget_runway` with monthly_budget=15000*
> No, you're projected to stay under budget by $1,755. You have 28 days of runway remaining.

---

## Personas and Their Common Questions

### Finance Team
- "What's our total spend this quarter?"
- "Are we on track to meet our budget?"
- "Show me month-over-month variance"
- "Forecast the rest of the year"

### Engineering Leads
- "Which of my team's resources are most expensive?"
- "Show me costs by environment"
- "Are there any untagged resources?"
- "Compare costs across regions"

### FinOps Practitioners
- "Find opportunities for commitment discounts"
- "Show me savings from our current CUDs"
- "Which services have the worst cost efficiency?"
- "Detect any unusual spending patterns"

### Executives/C-Level
- "What's our cloud spend trend?"
- "How much are we saving from optimizations?"
- "Forecast our spending for next quarter"
- "What's driving our cost growth?"

---

## Creating Custom Prompts

To create your own effective prompts:

1. **Identify the question**: What do you want to know?
2. **Choose timeframe**: Last week, month, quarter?
3. **Add filters**: Specific service, region, or tag?
4. **Request format**: Table, trend, comparison, forecast?
5. **Add context**: Percentages, averages, totals?

**Template:**
> Show me [METRIC] for [TIMEFRAME] [FILTERS] with [CONTEXT]

**Examples:**
- Show me **costs** for **last month** filtered by **Compute Engine** with **region breakdown**
- Show me **top resources** for **past 7 days** with **daily averages**
- Show me **growth rate** for **each service** over **6 months** with **forecasts**

---

## Next Steps

1. ✅ Try simple queries first to familiarize yourself
2. ✅ Experiment with different time ranges and parameters
3. ✅ Create custom queries for your specific use cases
4. ✅ Set up automated reports using Python SDK
5. ✅ Train your team on effective prompting techniques

Happy querying! 🚀
