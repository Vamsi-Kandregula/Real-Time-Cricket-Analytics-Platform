import os
import sys
import subprocess

def main():
    # Resolve the project root (parent directory of 'scripts')
    project_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    dbt_dir = os.path.join(project_root, "dbt_project")
    
    print("Running dbt...")
    
    # 1. dbt run
    cmd_run = ["dbt", "run", "--profiles-dir", "."]
    print(f"Executing: {' '.join(cmd_run)} in {dbt_dir}")
    
    try:
        # Running synchronously and directing stdout/stderr to the console
        result_run = subprocess.run(
            cmd_run,
            cwd=dbt_dir,
            check=True
        )
        print("dbt run completed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error: dbt run failed with return code {e.returncode}", file=sys.stderr)
        sys.exit(1)
    except FileNotFoundError:
        print("Error: 'dbt' executable not found. Make sure dbt is installed and in your PATH.", file=sys.stderr)
        sys.exit(1)

    print("Running dbt tests...")
    
    # 2. dbt test
    cmd_test = ["dbt", "test", "--profiles-dir", "."]
    print(f"Executing: {' '.join(cmd_test)} in {dbt_dir}")
    
    try:
        result_test = subprocess.run(
            cmd_test,
            cwd=dbt_dir,
            check=True
        )
        print("dbt tests completed successfully.")
    except subprocess.CalledProcessError as e:
        print(f"Error: dbt test failed with return code {e.returncode}", file=sys.stderr)
        sys.exit(1)
        
    print("dbt steps completed successfully.")

if __name__ == "__main__":
    main()

