# Databricks notebook source
from pyspark.sql import functions as F

raw = spark.table("workspace.default.paysim_raw")

# PaySim's "step" is an hour number (1 = first hour). Map it onto a calendar so Power BI
# can show real dates; the start date is arbitrary and stated in the README.
start = F.to_timestamp(F.lit("2026-01-01 00:00:00"))

silver = (raw
    .withColumn("txn_id", F.monotonically_increasing_id())
    .withColumn("txn_ts", start + F.expr("make_interval(0,0,0,0, step - 1, 0, 0)"))
    .withColumn("txn_date", F.to_date("txn_ts"))
    .withColumn("hour_of_day", F.hour("txn_ts"))
    .withColumnRenamed("oldbalanceOrg", "orig_balance_before")
    .withColumnRenamed("newbalanceOrig", "orig_balance_after")
    .withColumnRenamed("oldbalanceDest", "dest_balance_before")
    .withColumnRenamed("newbalanceDest", "dest_balance_after")
    .withColumnRenamed("nameOrig", "orig_account")
    .withColumnRenamed("nameDest", "dest_account")
    .withColumn("txn_type", F.col("type"))
    .withColumn("is_fraud", F.col("isFraud").cast("boolean"))
    .withColumn("is_flagged", F.col("isFlaggedFraud").cast("boolean"))
    # Merchant accounts start with "M" and carry no balances in PaySim
    .withColumn("dest_kind", F.when(F.col("dest_account").startswith("M"), "Merchant").otherwise("Customer"))
    .withColumn("amount_band",
        F.when(F.col("amount") < 1_000, "1. <1k")
         .when(F.col("amount") < 10_000, "2. 1k-10k")
         .when(F.col("amount") < 100_000, "3. 10k-100k")
         .when(F.col("amount") < 1_000_000, "4. 100k-1M")
         .otherwise("5. 1M+"))
)

# Data quality checks: do the balances add up?
silver = (silver
    .withColumn("orig_balance_gap",
        F.round(F.col("orig_balance_before") - F.col("amount") - F.col("orig_balance_after"), 2))
    .withColumn("dq_orig_mismatch",
        (F.col("txn_type").isin("CASH_OUT", "TRANSFER", "PAYMENT", "DEBIT")) & (F.abs("orig_balance_gap") > 0.01))
    .withColumn("dq_account_emptied",
        (F.col("orig_balance_before") > 0) & (F.col("orig_balance_after") == 0))
    .withColumn("dq_dest_zero_both",
        (F.col("dest_kind") == "Customer") & (F.col("dest_balance_before") == 0)
        & (F.col("dest_balance_after") == 0) & (F.col("amount") > 0))
    .drop("type", "isFraud", "isFlaggedFraud")
)

silver.write.mode("overwrite").saveAsTable("workspace.default.silver_transactions")
print(spark.table("workspace.default.silver_transactions").count())

s = spark.table("workspace.default.silver_transactions")

daily = (s.groupBy("txn_date", "txn_type", "amount_band", "dest_kind")
    .agg(F.count("*").alias("txn_count"),
         F.sum("amount").alias("txn_amount"),
         F.sum(F.col("is_fraud").cast("int")).alias("fraud_count"),
         F.sum(F.when(F.col("is_fraud"), F.col("amount")).otherwise(0)).alias("fraud_amount"),
         F.sum(F.col("is_flagged").cast("int")).alias("flagged_count"),
         F.sum((F.col("is_fraud") & F.col("is_flagged")).cast("int")).alias("fraud_flagged_count"),
         F.sum(F.col("dq_orig_mismatch").cast("int")).alias("dq_orig_mismatch_count"),
         F.sum(F.col("dq_account_emptied").cast("int")).alias("dq_account_emptied_count"),
         F.sum(F.col("dq_dest_zero_both").cast("int")).alias("dq_dest_zero_both_count")))

daily.write.mode("overwrite").saveAsTable("workspace.default.gold_daily_summary")
print(daily.count())

cases = s.filter(F.col("is_fraud") | F.col("is_flagged")).select(
    "txn_id", "txn_ts", "txn_date", "hour_of_day", "txn_type", "amount", "amount_band",
    "orig_account", "dest_account", "dest_kind", "orig_balance_before", "orig_balance_after",
    "is_fraud", "is_flagged", "dq_account_emptied", "dq_orig_mismatch")
cases.write.mode("overwrite").saveAsTable("workspace.default.gold_fraud_cases")
print(cases.count())
