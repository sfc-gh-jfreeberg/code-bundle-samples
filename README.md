# Code Bundle Samples

Sample projects for [Snowflake Code Bundles](https://docs.snowflake.com) — a feature that lets you package and execute Python scripts directly on Snowflake compute. Upload your project, run a single command, and Snowflake injects a Snowpark session automatically.

## Samples

| Sample | Compute | Description |
|--------|---------|-------------|
| [`python-on-wh`](./python-on-wh) | Warehouse | Sales aggregation job and external API ingestion using warehouse compute |
| [`python-on-spcs`](./python-on-spcs) | Compute Pool (SPCS) | Python job running on Snowpark Container Services |

## What are Code Bundles?

Code Bundles support two compute targets:

- **Warehouse** — Run Python scripts on Snowflake warehouse compute. Best for data processing, ETL, and workloads where most processing happens on the warehouse.
- **Compute Pool (SPCS)** — Run on Snowpark Container Services. Best for GPU workloads, custom runtimes, or jobs that need stages mounted as a local file system.

A `code_bundle.yml` file in the root of your project controls compute type, runtime version, dependencies, environment variables, secrets, and external access integrations.

## Prerequisites

- Snowflake CLI with Code Bundle support:

  ```bash
  uv tool install git+https://github.com/snowflakedb/snowflake-cli@code
  # or
  pip install git+https://github.com/snowflakedb/snowflake-cli@code
  ```

- A configured Snowflake CLI connection (`snow connection list`)

## Quick deploy

Each sample includes a `deploy.sh` that creates all required Snowflake objects and executes the bundle end-to-end:

```bash
cd python-on-wh
bash deploy.sh
```

Set `CB_CONNECTION` to use a named connection:

```bash
CB_CONNECTION=my_connection bash deploy.sh
```

## Repository structure

```
code-bundle-samples/
├── python-on-wh/          # Warehouse compute sample
│   ├── code_bundle.yml    # Bundle specification
│   ├── deploy.sh          # End-to-end deploy script
│   ├── pyproject.toml     # Python dependencies
│   └── jobs/
│       ├── main.py        # Sales aggregation entrypoint
│       ├── api-ingestion.py  # External API ingestion entrypoint
│       └── utils/
│           └── helpers.py
└── python-on-spcs/        # Compute Pool (SPCS) sample
    ├── code_bundle.yml
    └── deploy.sh
```
