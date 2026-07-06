import os
import sys
import datetime
import io
import pytz
import snowflake.connector

def main():
    print("Running merge_matches.sql...")

    # Load configuration
    account = os.environ.get("SNOWFLAKE_ACCOUNT")
    user = os.environ.get("SNOWFLAKE_USER")
    password = os.environ.get("SNOWFLAKE_PASSWORD")
    warehouse = os.environ.get("SNOWFLAKE_WAREHOUSE")
    database = os.environ.get("SNOWFLAKE_DATABASE")
    schema = os.environ.get("SNOWFLAKE_SCHEMA")
    role = os.environ.get("SNOWFLAKE_ROLE")

    if not all([account, user, password, warehouse, database, schema, role]):
        print("Error: All SNOWFLAKE_* environment variables must be set.", file=sys.stderr)
        sys.exit(1)

    # Get path to sql file relative to the script directory
    script_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    sql_path = os.path.join(script_dir, "sql", "merge_matches.sql")

    if not os.path.exists(sql_path):
        print(f"Error: SQL file not found at {sql_path}", file=sys.stderr)
        sys.exit(1)

    # Read SQL content
    try:
        with open(sql_path, "r", encoding="utf-8") as f:
            sql_content = f.read()
    except Exception as e:
        print(f"Error reading SQL file: {e}", file=sys.stderr)
        sys.exit(1)

    # Compute India date and replace placeholder
    tz = pytz.timezone("Asia/Kolkata")
    india_date = datetime.datetime.now(tz).strftime("%Y-%m-%d")
    sql_content = sql_content.replace("{{ params.india_date }}", india_date)

    # Connect to Snowflake and execute stream
    conn = None
    try:
        conn = snowflake.connector.connect(
            account=account,
            user=user,
            password=password,
            warehouse=warehouse,
            database=database,
            schema=schema,
            role=role
        )
        
        sql_stream = io.StringIO(sql_content)
        statement_num = 0
        for cursor in conn.execute_stream(sql_stream):
            statement_num += 1
            # Fetching results ensures the query execution finishes completely
            try:
                results = cursor.fetchall()
                print(f"Statement {statement_num} executed successfully. Query ID: {cursor.sfqid}")
            except Exception as stmt_err:
                print(f"Error executing statement {statement_num}: {stmt_err}", file=sys.stderr)
                sys.exit(1)

        print("merge_matches.sql executed successfully.")

    except Exception as e:
        print(f"Snowflake connection or execution error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        if conn:
            conn.close()

if __name__ == "__main__":
    main()
