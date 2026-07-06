# Cricket Live Score Data Engineering Pipeline

A production-grade, serverless data pipeline that fetches live cricket scores from CricAPI, stores raw data in AWS S3, processes it using Databricks, merges changes into Snowflake tables, and runs DBT transformations—all fully automated using **GitHub Actions**.

This pipeline replaces the original local Apache Airflow setup, removing the need for a dedicated local computer to run 24/7.

---

## Architecture Overview

```mermaid
graph TD
    A[GitHub Actions Workflow] -->|1. Fetch API| B(CricAPI)
    A -->|2. Save Raw JSON| C[(AWS S3)]
    A -->|3. Verify Upload| C
    A -->|4. Trigger Run & Poll| D[Databricks Job]
    D -->|5. Clean & Transform| C
    A -->|6. Merge Matches SQL| E[(Snowflake)]
    A -->|7. Merge Score SQL| E
    A -->|8. Run & Test| F[DBT Core]
    F -->|Transform Views/Tables| E
```

---

## Directory Structure

```text
.github/
    workflows/
        cricket_pipeline.yml     # GitHub Actions workflow running scheduled/manual runs
scripts/
    fetch_api.py                 # Fetches from CricAPI and uploads raw JSON to S3
    trigger_databricks.py        # Starts Databricks job and polls until completion
    merge_matches.py             # Executes merge_matches.sql on Snowflake
    merge_score.py              # Executes merge_score.sql on Snowflake
    run_dbt.py                   # Executes dbt run and dbt test with profiles.yml
sql/
    merge_matches.sql            # SQL template for merging matches data
    merge_score.sql              # SQL template for merging score data
models/                          # DBT models (existing)
dbt_project.yml                  # DBT project configuration (existing)
requirements.txt                 # Python dependencies
.gitignore                       # Excludes credentials & virtual envs
README.md                        # Documentation and Setup instructions
```

---

## Required GitHub Secrets

To deploy this pipeline, you must add the following **Repository Secrets** to your GitHub repository under **Settings -> Secrets and variables -> Actions -> New repository secret**:

| Secret Name | Description | Example / Format |
| :--- | :--- | :--- |
| `CRICKET_API_KEY` | API Key from CricAPI | `f851d11b-xxxx-xxxx-xxxx-xxxxxxxxxxxx` |
| `AWS_ACCESS_KEY_ID` | IAM User Access Key | `AKIAIOSFODNN7EXAMPLE` |
| `AWS_SECRET_ACCESS_KEY` | IAM User Secret Key | `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY` |
| `AWS_REGION` | S3 AWS Region | `us-east-1` |
| `S3_BUCKET` | Destination S3 Bucket Name | `airflowdemo1817` |
| `DATABRICKS_HOST` | Workspace URL (without trailing slash) | `adb-xxxxxxxxxxxx.x.azuredatabricks.net` |
| `DATABRICKS_TOKEN` | Personal Access Token (PAT) | `dapi1234567890abcdef` |
| `DATABRICKS_JOB_ID` | Databricks Job ID to trigger | `190606557968663` |
| `SNOWFLAKE_ACCOUNT` | Snowflake Account Identifier | `xy12345.us-east-1` |
| `SNOWFLAKE_USER` | Snowflake Username | `PIPELINE_USER` |
| `SNOWFLAKE_PASSWORD` | Snowflake Password | `SuperSecretPassword123` |
| `SNOWFLAKE_WAREHOUSE` | Snowflake Warehouse Name | `COMPUTE_WH` |
| `SNOWFLAKE_DATABASE` | Target Database | `CRICKET_DB` |
| `SNOWFLAKE_SCHEMA` | Target Schema | `RAW_SCHEMA` |
| `SNOWFLAKE_ROLE` | Snowflake Role | `ACCOUNTADMIN` |
| `DBT_PROFILES_YML` | Content of profiles.yml (see below) | See YAML block below |

### Recommended `DBT_PROFILES_YML` Secret Content

Add the exact block below as the value for `DBT_PROFILES_YML`. This configuration leverages env vars mapped in the GitHub workflow:

```yaml
dbt_cricket_project:
  target: dev
  outputs:
    dev:
      type: snowflake
      account: "{{ env_var('SNOWFLAKE_ACCOUNT') }}"
      user: "{{ env_var('SNOWFLAKE_USER') }}"
      password: "{{ env_var('SNOWFLAKE_PASSWORD') }}"
      role: "{{ env_var('SNOWFLAKE_ROLE') }}"
      warehouse: "{{ env_var('SNOWFLAKE_WAREHOUSE') }}"
      database: "{{ env_var('SNOWFLAKE_DATABASE') }}"
      schema: "{{ env_var('SNOWFLAKE_SCHEMA') }}"
      threads: 4
```

---

## Local Testing Instructions

You can run individual parts of the pipeline locally by configuring your terminal environment:

1. **Create a local virtual environment:**
   ```bash
   python -m venv venv
   source venv/Scripts/activate  # On Windows: venv\Scripts\activate
   pip install -r requirements.txt
   ```

2. **Set temporary environment variables** (or create a `.env` file - do not commit this file):
   ```bash
   # Windows PowerShell
   $env:CRICKET_API_KEY="your_api_key"
   $env:AWS_ACCESS_KEY_ID="your_aws_key"
   $env:AWS_SECRET_ACCESS_KEY="your_aws_secret"
   $env:AWS_REGION="us-east-1"
   $env:S3_BUCKET="airflowdemo1817"
   $env:DATABRICKS_HOST="adb-xxx.net"
   $env:DATABRICKS_TOKEN="dapi..."
   $env:DATABRICKS_JOB_ID="12345"
   $env:SNOWFLAKE_ACCOUNT="xxx"
   $env:SNOWFLAKE_USER="xxx"
   $env:SNOWFLAKE_PASSWORD="xxx"
   $env:SNOWFLAKE_WAREHOUSE="xxx"
   $env:SNOWFLAKE_DATABASE="xxx"
   $env:SNOWFLAKE_SCHEMA="xxx"
   $env:SNOWFLAKE_ROLE="xxx"
   ```

3. **Generate a local `profiles.yml` for DBT testing:**
   Save the YAML block from the secret section above as a file named `profiles.yml` in the project root folder.

4. **Execute scripts sequentially:**
   ```bash
   python scripts/fetch_api.py
   python scripts/trigger_databricks.py
   python scripts/merge_matches.py
   python scripts/merge_score.py
   python scripts/run_dbt.py
   ```

---

## Deployment & Production Execution

1. Initialize git and commit all configuration, script, and SQL files:
   ```bash
   git init
   git add .
   git commit -m "Migrate scheduler from Airflow to GitHub Actions"
   ```
2. Create a repository on GitHub, map it to your local git, and push:
   ```bash
   git remote add origin git@github.com:yourusername/cricket-data-pipeline.git
   git branch -M main
   git push -u origin main
   ```
3. Set the Repository Secrets on GitHub as described above.
4. **Validation:** Navigate to the **Actions** tab on your GitHub repository, select **Cricket Live Score Data Pipeline**, and click **Run workflow** to run a manual validation. 
5. The pipeline is scheduled to run automatically every 30 minutes (`*/30 * * * *`).
