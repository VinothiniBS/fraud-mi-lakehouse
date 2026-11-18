-- When does fraud happen? Volume, fraud count and fraud rate by hour of day.
SELECT hour_of_day,
       COUNT(*) AS txns,
       SUM(CAST(is_fraud AS INT)) AS frauds,
       ROUND(100.0 * AVG(CAST(is_fraud AS INT)), 3) AS fraud_rate_pct
FROM workspace.default.silver_transactions
GROUP BY hour_of_day
ORDER BY hour_of_day;
