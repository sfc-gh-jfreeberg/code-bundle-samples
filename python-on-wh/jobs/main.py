import argparse
import sys
from utils.helpers import get_session, log_step, summarize_results

def parse_args():
    parser = argparse.ArgumentParser(description="Aggregate sales data by region and product category.")
    parser.add_argument("--source-table", required=True, help="Fully qualified source table name")
    parser.add_argument("--output-table", required=True, help="Fully qualified output table name")
    parser.add_argument("--date-column", default="ORDER_DATE", help="Name of the date column to filter on")
    parser.add_argument("--days-back", type=int, default=30, help="Number of days back to aggregate")
    return parser.parse_args()


def main():
    args = parse_args()
    session = get_session()

    log_step(f"Reading from {args.source_table} (last {args.days_back} days)")

    source_df = session.sql(f"""
        SELECT
            REGION,
            PRODUCT_CATEGORY,
            SUM(SALE_AMOUNT)    AS TOTAL_SALES,
            COUNT(*)            AS ORDER_COUNT,
            AVG(SALE_AMOUNT)    AS AVG_ORDER_VALUE
        FROM {args.source_table}
        WHERE {args.date_column} >= DATEADD('day', -{args.days_back}, CURRENT_DATE)
        GROUP BY REGION, PRODUCT_CATEGORY
        ORDER BY TOTAL_SALES DESC
    """)

    row_count = source_df.count()
    log_step(f"Aggregated {row_count} region/category combinations")

    log_step(f"Writing results to {args.output_table}")
    source_df.write.mode("overwrite").save_as_table(args.output_table)

    summarize_results(session, args.output_table)
    log_step("Done")


if __name__ == "__main__":
    main()
