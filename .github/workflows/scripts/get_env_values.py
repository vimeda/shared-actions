import subprocess
import json
import os
def run_op_command(command):
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error executing the command: {e}")
        print(f"Command returned non-zero exit code: {e.returncode}")
        print(f"Command output: {e.output}")
        return None
    except Exception as ex:
        print(f"An unexpected error occurred: {ex}")
        return None

def save_to_env(labels_values, output_file):
    # Filter out null or empty values
    labels_values = {label: value for label, value in labels_values.items() if value is not None and value.strip() != ""}

    with open(output_file, "w") as env_file:
        env_file.write("envVariables:\n")
        env_file.write("  - variables:\n")
        for label, value in labels_values.items():
            env_file.write(f"      {label}: {value}\n")

def main():

    github_repository = os.environ.get('GITHUB_REPOSITORY')
    repo_name = github_repository.split('/')[1]

    # Execute the initial op command to get the sample data
    initial_command = 'op items get order-srv --vault=errsir3kqd4gdjgaxliofyskey --format=json'
    print("Fetching sample data...")
    sample_data = run_op_command(initial_command)

    if sample_data is None:
        print("Error fetching sample data.")
        return

    # Parse the JSON data
    try:
        parsed_data = json.loads(sample_data)
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON data: {e}")
        return

    labels_values = {}

    # Extract the label and execute the command for each label
    print("Fetching values for labels...")
    for field in parsed_data['fields']:
        label = field['label']
        value = run_op_command(f'op read op://errsir3kqd4gdjgaxliofyskey/{repo_name}/{label}')
        if value is not None:
            labels_values[label] = value

    # Set the output file name
    output_file = "./envs.out"

    # Save the values to the output file
    save_to_env(labels_values, output_file)
    print("Values saved to .env file.")

if __name__ == "__main__":
    main()
