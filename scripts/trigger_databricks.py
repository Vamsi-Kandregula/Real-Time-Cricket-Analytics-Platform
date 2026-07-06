import os
import sys
import time
import requests

def main():
    print("Triggering Databricks Job...")
    
    # Retrieve configuration from environment
    host = os.environ.get("DATABRICKS_HOST", "").strip()
    token = os.environ.get("DATABRICKS_TOKEN", "").strip()
    job_id_str = os.environ.get("DATABRICKS_JOB_ID", "").strip()
    
    if not host or not token or not job_id_str:
        print("Error: DATABRICKS_HOST, DATABRICKS_TOKEN, and DATABRICKS_JOB_ID must all be set.", file=sys.stderr)
        sys.exit(1)
        
    try:
        job_id = int(job_id_str)
    except ValueError:
        print(f"Error: DATABRICKS_JOB_ID must be an integer, got: '{job_id_str}'", file=sys.stderr)
        sys.exit(1)

    # Format host URL
    if not host.startswith("https://") and not host.startswith("http://"):
        host = f"https://{host}"
    
    # Run Now API endpoint
    run_now_url = f"{host}/api/2.1/jobs/run-now"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    payload = {"job_id": job_id}
    
    try:
        response = requests.post(run_now_url, json=payload, headers=headers, timeout=30)
        response.raise_for_status()
        run_data = response.json()
    except Exception as e:
        print(f"Failed to trigger Databricks Job: {e}", file=sys.stderr)
        sys.exit(1)
        
    run_id = run_data.get("run_id")
    if not run_id:
        print(f"Error: Databricks response did not contain 'run_id'. Response: {run_data}", file=sys.stderr)
        sys.exit(1)
        
    print(f"Databricks job triggered successfully. Run ID: {run_id}")
    print("Waiting for Databricks...")

    # Get Run Status API endpoint
    get_run_url = f"{host}/api/2.1/jobs/runs/get"
    
    while True:
        try:
            status_response = requests.get(get_run_url, params={"run_id": run_id}, headers=headers, timeout=30)
            status_response.raise_for_status()
            status_data = status_response.json()
        except Exception as e:
            print(f"Error polling Databricks job status: {e}", file=sys.stderr)
            # We don't exit immediately on transient network errors, just warn and retry
            time.sleep(30)
            continue
            
        state = status_data.get("state", {})
        life_cycle_state = state.get("life_cycle_state")
        result_state = state.get("result_state")
        state_message = state.get("state_message", "")
        
        print(f"Job Status: life_cycle_state={life_cycle_state}, result_state={result_state}")
        
        if life_cycle_state in ["TERMINATED", "SKIPPED", "INTERNAL_ERROR"]:
            if result_state == "SUCCESS":
                print("Databricks job completed successfully.")
                sys.exit(0)
            else:
                print(f"Databricks job failed: result_state={result_state}, message={state_message}", file=sys.stderr)
                sys.exit(1)
                
        # Wait 30 seconds before polling again
        time.sleep(30)

if __name__ == "__main__":
    main()
