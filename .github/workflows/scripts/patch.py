import subprocess
import json
import os
import ruamel.yaml as yaml

def run_command(command):
    return subprocess.check_output(command, shell=True).decode().strip()

def clean_json_data(json_data):
    cleaned_data = []
    for entry in json_data:
        cleaned_entry = {key: value for key, value in entry.items() if value is not None}
        if cleaned_entry:  # Only append if the dictionary is not empty
            cleaned_data.append(cleaned_entry)
    return cleaned_data

def merge_yaml_with_json(existing_yaml_data, json_data):
    if existing_yaml_data is None:
        existing_yaml_data = {}
    existing_yaml_data['spec']['parameters']['envVariables'] = [{'variables': {k: v for entry in clean_json_data(json_data) for k, v in entry.items()}}]
    return existing_yaml_data

def process_file(filename):
    try:
        github_repository = os.environ.get('GITHUB_REPOSITORY')
        repo_name = github_repository.split('/')[1]
        vault_id = os.environ.get('VAULT_ID')

        print(f"This is the vault ID {vault_id}")
        print(f"This is the repo name {repo_name}")

        # Command to get JSON from the provided command
        command = 'op items get ' + repo_name + ' --vault=' + vault_id + ' --format=json | jq ".fields | map({(.label): .value}) | {\"envVariables\": {\"variables\": .}}"'
        json_output = run_command(command)

        # Load the existing YAML file with multiple documents
        with open(filename, 'r') as file:
            existing_yaml_data_list = list(yaml.safe_load_all(file))

        # Find the 'kind: XLambda' document in the list of documents
        xlambda_documents = [doc for doc in existing_yaml_data_list if doc.get('kind') == 'XLambda']

        if not xlambda_documents:
            print(f"No 'kind: XLambda' document found in {filename}.")
            return

        # Assuming there is only one 'kind: XLambda' document, take the first one
        xlambda_document = xlambda_documents[0]

        # Merge the parsed JSON with the existing YAML for the 'kind: XLambda' document
        parsed_json = json.loads(json_output)
        merged_yaml_data = merge_yaml_with_json(xlambda_document, parsed_json['envVariables']['variables'])

        # Update the 'kind: XLambda' document in the list
        existing_yaml_data_list[existing_yaml_data_list.index(xlambda_document)] = merged_yaml_data

        # Write the updated YAML back to the file
        with open(filename, 'w') as file:
            yaml.dump_all(existing_yaml_data_list, file, default_flow_style=False)  # Set default_flow_style to False

    except Exception as e:
        print(f"An error occurred while processing {filename}: {e}")

def main():
    try:
        # Load all files ending with "-claims.yaml" in the directory
        for filename in os.listdir():
            if filename.endswith("-claims.yaml"):
                process_file(filename)

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
