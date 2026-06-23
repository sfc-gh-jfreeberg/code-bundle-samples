#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — override via environment variables or edit here
# ---------------------------------------------------------------------------
CONNECTION="${CB_CONNECTION:-}"
SNOW_CMD="snow${CONNECTION:+ --connection ${CONNECTION}}"

BUNDLE_NAME="SALES_AGGREGATION"
STAGE_NAME="CODE_BUNDLE_STAGE"
STAGE_PATH="@${STAGE_NAME}/python-on-wh"

SOURCE_TABLE="${CB_SOURCE_TABLE:-RAW_SALES}"
OUTPUT_TABLE="${CB_OUTPUT_TABLE:-SALES_AGGREGATED}"
DAYS_BACK="${CB_DAYS_BACK:-30}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# 0. Create Secret, Network Rule, and External Access Integration
# ---------------------------------------------------------------------------
echo ">>> Creating Secret POKEMON_API_KEY..."
${SNOW_CMD} sql -q "CREATE OR REPLACE SECRET POKEMON_API_KEY
    TYPE = GENERIC_STRING
    SECRET_STRING = 'my-placeholder-api-key'
    COMMENT = 'API key for PokeAPI (Code Bundle sample)';"

echo ">>> Creating Network Rule POKEAPI_NETWORK_RULE..."
${SNOW_CMD} sql -q "CREATE OR REPLACE NETWORK RULE POKEAPI_NETWORK_RULE
    TYPE = HOST_PORT
    MODE = EGRESS
    VALUE_LIST = ('pokeapi.co');"

echo ">>> Creating External Access Integration POKEAPI_ACCESS_INTEGRATION..."
${SNOW_CMD} sql -q "CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION POKEAPI_ACCESS_INTEGRATION
    ALLOWED_NETWORK_RULES = (POKEAPI_NETWORK_RULE)
    ALLOWED_AUTHENTICATION_SECRETS = (POKEMON_API_KEY)
    ENABLED = TRUE
    COMMENT = 'Allows Code Bundle egress to pokeapi.co';"

# ---------------------------------------------------------------------------
# 1. Create sample source table with minimal data
# ---------------------------------------------------------------------------
echo ">>> Creating sample source table ${SOURCE_TABLE}..."
${SNOW_CMD} sql -q "CREATE TABLE IF NOT EXISTS ${SOURCE_TABLE} (
    ORDER_DATE       DATE,
    REGION           VARCHAR,
    PRODUCT_CATEGORY VARCHAR,
    SALE_AMOUNT      NUMBER(12, 2)
);"

echo ">>> Inserting sample rows into ${SOURCE_TABLE}..."
${SNOW_CMD} sql -q "INSERT INTO ${SOURCE_TABLE} (ORDER_DATE, REGION, PRODUCT_CATEGORY, SALE_AMOUNT)
SELECT * FROM VALUES
    (DATEADD('day', -1,  CURRENT_DATE), 'North America', 'Software',  1200.00),
    (DATEADD('day', -3,  CURRENT_DATE), 'North America', 'Hardware',   850.50),
    (DATEADD('day', -5,  CURRENT_DATE), 'Europe',        'Software',  2300.00),
    (DATEADD('day', -7,  CURRENT_DATE), 'Europe',        'Services',   670.00),
    (DATEADD('day', -10, CURRENT_DATE), 'APAC',          'Software',  3100.75),
    (DATEADD('day', -12, CURRENT_DATE), 'APAC',          'Hardware',  1450.00),
    (DATEADD('day', -15, CURRENT_DATE), 'North America', 'Services',   990.25),
    (DATEADD('day', -20, CURRENT_DATE), 'Europe',        'Hardware',  1800.00),
    (DATEADD('day', -25, CURRENT_DATE), 'APAC',          'Services',   540.00),
    (DATEADD('day', -28, CURRENT_DATE), 'North America', 'Software',  4200.00)
AS t (ORDER_DATE, REGION, PRODUCT_CATEGORY, SALE_AMOUNT);"

# ---------------------------------------------------------------------------
# 2. Ensure the stage exists
# ---------------------------------------------------------------------------
echo ">>> Creating/replacing stage..."
${SNOW_CMD} sql -q "CREATE OR REPLACE STAGE ${STAGE_NAME}
               COMMENT = 'Stage for Code Bundle source files';"

# ---------------------------------------------------------------------------
# 3. Upload project files to stage
# ---------------------------------------------------------------------------
echo ">>> Uploading project files to ${STAGE_PATH}..."
${SNOW_CMD} stage copy "${SCRIPT_DIR}" "@${STAGE_PATH}" --recursive --overwrite

# ---------------------------------------------------------------------------
# 4. CREATE CODE BUNDLE
# ---------------------------------------------------------------------------
echo ">>> Creating Code Bundle ${BUNDLE_NAME}..."
${SNOW_CMD} sql -q "CREATE OR REPLACE CODE BUNDLE ${BUNDLE_NAME}
               FROM ${STAGE_PATH}
               COMMENT = 'Snowpark sales aggregation sample — warehouse compute';"

# ---------------------------------------------------------------------------
# 5. EXECUTE CODE BUNDLE
# ---------------------------------------------------------------------------
echo ">>> Executing Code Bundle (sales aggregation)..."
${SNOW_CMD} sql -q "EXECUTE CODE BUNDLE ${BUNDLE_NAME}
               ENTRYPOINT = 'jobs/main.py'
               ARGUMENTS = '--source-table ${SOURCE_TABLE} --output-table ${OUTPUT_TABLE} --days-back ${DAYS_BACK}';"

# ---------------------------------------------------------------------------
# 6. EXECUTE CODE BUNDLE — API ingestion
# ---------------------------------------------------------------------------
echo ">>> Executing Code Bundle (api-ingestion)..."
${SNOW_CMD} sql -q "EXECUTE CODE BUNDLE ${BUNDLE_NAME}
               ENTRYPOINT = 'jobs/api-ingestion.py';"

echo ">>> Done. Results written to ${OUTPUT_TABLE}"
