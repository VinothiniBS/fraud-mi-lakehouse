-- Where does fraud happen? Fraud count, rate and value by transaction type.
SELECT txn_type,
       SUM(txn_count) AS txns,
       SUM(fraud_count) AS frauds,
       ROUND(100.0 * SUM(fraud_count) / SUM(txn_count), 3) AS fraud_rate_pct,
       ROUND(SUM(fraud_amount) / 1e6, 1) AS fraud_value_m
FROM workspace.default.gold_daily_summary
GROUP BY txn_type
ORDER BY frauds DESC;
