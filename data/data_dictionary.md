# Data Dictionary — apple_products_pricing_2020_2026.csv

**Rows:** 80,000 | **Columns:** 14 | **Date range:** 2020-09-19 to 2026-07-31
**Grain:** one row per (Date, Platform, Model_Name, Condition) price observation

| Column | Type | Description | Values / Range | Notes |
|---|---|---|---|---|
| `Date` | date | Date of price observation | 2020-09-19 → 2026-07-31 | Stored as string; parse to datetime |
| `Platform` | string | Marketplace | Amazon, Flipkart | |
| `Product_Category` | string | Product line | iPhone, iPad, Mac, Watch | 11 iPhone models, 6 iPad, 7 Mac, 7 Watch = 31 total |
| `Model_Name` | string | Specific model + storage | e.g. "iPhone 15 128GB", "MacBook Pro 14-inch M3 Pro 512GB" | 31 unique values, spans iPhone 12–17, iPad 9th Gen–Pro(M4), MacBook Air/Pro M1–M4, Watch Series 6–X / Ultra / Ultra 2 |
| `Condition` | string | Listing condition | New, Renewed/Refurbished | |
| `Launch_Price_USD` | int | Official launch price (USD) | $329–$1,999 | Fixed per model, doesn't vary by date |
| `Launch_Price_INR` | int | Official launch price (INR) | | Fixed per model |
| `Current_Price_USD` | float | Actual selling price that day (USD) | | Primary price variable |
| `Current_Price_INR` | float | Actual selling price that day (INR) | | |
| `Discount_Pct` | float | % difference vs launch price | -2.0 to 73.1, median 21.3 | **Negative = price above launch (markup), not a discount** — don't assume all values are true discounts |
| `Sale_Event` | string | Named sale event, if any | Big Billion Days, Great Indian Festival, Black Friday, Prime Day, or blank | Blank in 91.7% of rows — this is expected (no event that day), not missing data |
| `Stock_Status` | string | Inventory status | In Stock, Out of Stock, Low Stock | |
| `Rating` | float | Product rating | 3.8–4.9 | |
| `Reviews_Count` | int | Number of reviews | 10–11,526 | Rough proxy for sales volume/popularity |

## Data quality notes
- No true nulls except `Sale_Event` (expected, see above) — confirmed via `df.isna().sum()`.
- `Launch_Price_USD`/`Launch_Price_INR` are constant per `Model_Name` — worth a sanity check (`groupby('Model_Name')['Launch_Price_USD'].nunique()` should be all 1s) before using them as a fixed reference point.
- Currency choice: analysis uses `_USD` columns for consistency across the whole dataset; `_INR` columns are available if an India-specific/local-currency lens is wanted later.
- `Discount_Pct` appears to be pre-calculated from `Current_Price_USD` vs `Launch_Price_USD` — worth verifying the formula reproduces the stored values before trusting it blindly (this is the "assess data accurately" checkpoint).