-- Control test: precision and recall of the existing rule against three candidate rules.
SELECT rule,
       SUM(CASE WHEN hit AND is_fraud THEN 1 ELSE 0 END) AS frauds_caught,
       SUM(CASE WHEN hit AND NOT is_fraud THEN 1 ELSE 0 END) AS false_alarms,
       ROUND(100.0 * SUM(CASE WHEN hit AND is_fraud THEN 1 ELSE 0 END)
             / NULLIF(SUM(CASE WHEN hit THEN 1 ELSE 0 END), 0), 2) AS precision_pct,
       ROUND(100.0 * SUM(CASE WHEN hit AND is_fraud THEN 1 ELSE 0 END) / 8213, 1) AS recall_pct
FROM (
  SELECT is_fraud, 'A: transfer >= 200k' AS rule,
         txn_type = 'TRANSFER' AND amount >= 200000 AS hit
  FROM workspace.default.silver_transactions
  UNION ALL
  SELECT is_fraud, 'B: A + account emptied',
         txn_type = 'TRANSFER' AND amount >= 200000 AND dq_account_emptied
  FROM workspace.default.silver_transactions
  UNION ALL
  SELECT is_fraud, 'C: transfer/cash-out + emptied + night (01-06h)',
         txn_type IN ('TRANSFER', 'CASH_OUT') AND dq_account_emptied AND hour_of_day BETWEEN 1 AND 6
  FROM workspace.default.silver_transactions
  UNION ALL
  SELECT is_fraud, 'Existing rule (isFlaggedFraud)', is_flagged
  FROM workspace.default.silver_transactions
)
GROUP BY rule
ORDER BY rule;
