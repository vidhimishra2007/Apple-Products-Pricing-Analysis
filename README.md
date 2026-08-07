# Apple Products Pricing Analysis (2020–2026)

Portfolio project analyzing 6 years of daily Apple product pricing on Amazon and Flipkart India — built for the Google Data Analytics Apprenticeship application.

## Dataset
`apple_products_pricing_2020_2026.csv` — 80,000 daily price records (Sep 2020 – Jul 2026) covering iPhone, iPad, Mac and Apple Watch across 31 models, tracked on Amazon and Flipkart India. Fields include launch/current price (USD & INR), discount %, sale event, stock status, rating, and review count.

## Pipeline
1. **`01_cleaning.py`** — parses dates, fills missing sale-event labels, derives Year/Month/Quarter, price-drop metrics, storage capacity from model name, and validates data quality (no duplicates, no invalid prices). Outputs `apple_pricing_cleaned.csv`.
2. **`02_eda.py`** — exploratory analysis producing 8 charts (`charts/`) covering discount patterns, price trends, sale-event impact, ratings, and stock status.
3. **`queries.sql`** — 12 SQL queries (run against `apple_pricing.db`, a SQLite load of the cleaned data) covering aggregate comparisons, window functions (RANK, LAG), and CTEs for month-over-month and category-ranked analysis.
4. **`dashboard.html`** — interactive single-file dashboard (Chart.js) presenting the key findings visually.

## Key findings
- **Overall average discount: 21.4%** across all platforms and categories.
- **Watch (26.3%) and iPad (26.2%) discount the most**; **Mac holds price best (15.4%)**.
- **Sale events nearly double average discounting**: 33.7% during named sale events vs. 20.3% on normal days.
- **Big Billion Days is the deepest-discounting event** (37.0% avg), ahead of Prime Day, Great Indian Festival, and Black Friday.
- **Amazon and Flipkart discount almost identically** on average (21.5% vs 21.3%) — platform choice doesn't meaningfully change expected discount.
- **Heavier discounts trend with slightly lower average ratings** (4.37 at 30%+ discount vs 4.55 at low/no discount), consistent with deep markdowns often being on older or overstocked inventory.
- **Sale events see a higher out-of-stock rate** (21.6% vs 16.4% on normal days) — demand outpaces restocking during promotions.
- **Renewed/Refurbished units price 20–25% below New** across every category.

## Files
```
data/
 apple_products_pricing_2020_2026.csv   raw dataset
 apple_pricing_cleaned.csv              cleaned dataset
 data_dictionary.md                     metadata
notebooks/
 01_cleaning.py                         cleaning script
 02_eda.py                              EDA script
apple_pricing.db                       SQLite database (cleaned data)
sql/
 queries.sql                            SQL analysis queries
dashboard_data.json                    aggregated data powering the dashboard
dashboard.html                         interactive dashboard
```
