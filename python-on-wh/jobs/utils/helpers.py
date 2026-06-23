from datetime import datetime
from snowflake.snowpark import Session
from snowflake.snowpark.context import get_active_session


def get_session() -> Session:
    try:
        return get_active_session()
    except Exception:
        raise RuntimeError(
            "No active Snowpark session found. "
            "Code Bundles on Warehouse automatically inject a session — "
            "ensure this script is executed via EXECUTE CODE BUNDLE."
        )


def log_step(message: str) -> None:
    ts = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S")
    print(f"[{ts}] {message}", flush=True)


def summarize_results(session: Session, table_name: str) -> None:
    log_step(f"Summary of {table_name}:")
    summary = session.sql(f"""
        SELECT
            COUNT(DISTINCT REGION)           AS regions,
            COUNT(DISTINCT PRODUCT_CATEGORY) AS categories,
            SUM(TOTAL_SALES)                 AS grand_total_sales,
            SUM(ORDER_COUNT)                 AS grand_total_orders
        FROM {table_name}
    """).collect()

    if summary:
        row = summary[0]
        print(f"  Regions:       {row['REGIONS']}")
        print(f"  Categories:    {row['CATEGORIES']}")
        print(f"  Total Sales:   ${row['GRAND_TOTAL_SALES']:,.2f}")
        print(f"  Total Orders:  {row['GRAND_TOTAL_ORDERS']:,}")
