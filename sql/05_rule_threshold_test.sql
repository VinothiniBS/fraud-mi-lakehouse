-- Would a simple amount threshold work? Frauds caught and false alarms per threshold (transfers).
SELECT threshold,
       SUM(CASE WHEN amount >= threshold AND is_fraud THEN 1 ELSE 0 END) AS frauds_caught,
       SUM(CASE WHEN amount >= threshold AND NOT is_fraud THEN 1 ELSE 0 END) AS false_alarms
FROM workspace.default.silver_transactions
CROSS JOIN (SELECT explode(array(50000, 100000, 200000, 500000)) AS threshold)
WHERE txn_type = 'TRANSFER'
GROUP BY threshold
ORDER BY threshold;
