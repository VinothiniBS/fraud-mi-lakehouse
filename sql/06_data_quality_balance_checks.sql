-- Data quality: share of transactions whose balances don't reconcile, by transaction type.
SELECT txn_type,
       SUM(txn_count) AS txns,
       ROUND(100.0 * SUM(dq_orig_mismatch_count) / SUM(txn_count), 1) AS pct_balance_mismatch,
       ROUND(100.0 * SUM(dq_dest_zero_both_count) / SUM(txn_count), 1) AS pct_dest_zero_balances
FROM workspace.default.gold_daily_summary
GROUP BY txn_type
ORDER BY txn_type;
