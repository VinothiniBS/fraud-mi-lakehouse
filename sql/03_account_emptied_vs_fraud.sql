-- Does fraud empty the sender's account? Share of transactions leaving a zero balance.
SELECT is_fraud,
       COUNT(*) AS txns,
       ROUND(100.0 * AVG(CAST(dq_account_emptied AS INT)), 1) AS pct_account_emptied
FROM workspace.default.silver_transactions
WHERE txn_type IN ('TRANSFER', 'CASH_OUT')
GROUP BY is_fraud;
