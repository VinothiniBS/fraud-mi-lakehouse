-- How big are fraudulent transactions? Fraud count and rate by amount band.
SELECT amount_band,
       SUM(fraud_count) AS frauds,
       ROUND(100.0 * SUM(fraud_count) / SUM(txn_count), 3) AS fraud_rate_pct
FROM workspace.default.gold_daily_summary
GROUP BY amount_band
ORDER BY amount_band;
