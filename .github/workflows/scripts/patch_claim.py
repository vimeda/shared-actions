import subprocess
import json
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
    existing_yaml_data['spec']['parameters']['envVariables'][0]['variables'] = clean_json_data(json_data)
    return existing_yaml_data

def main():
    try:
        # Command to get JSON from the provided command
        command = 'op items get order-srv --vault=errsir3kqd4gdjgaxliofyskey --format=json | jq ".fields | map({(.label): .value}) | {envVariables: {variables: .}}"'
        json_output = run_command(command)

        # Load the existing YAML file with multiple documents
        with open('claims.yaml', 'r') as file:
            existing_yaml_data_list = list(yaml.safe_load_all(file))

        # Find the 'kind: XLambda' document in the list of documents
        xlambda_documents = [doc for doc in existing_yaml_data_list if doc.get('kind') == 'XLambda']

        if not xlambda_documents:
            print("No 'kind: XLambda' document found in claims.yaml.")
            return

        # Assuming there is only one 'kind: XLambda' document, take the first one
        xlambda_document = xlambda_documents[0]

        # Parse the JSON output
        parsed_json = json.loads(json_output)

        # Merge the parsed JSON with the existing YAML for the 'kind: XLambda' document
        merged_yaml_data = merge_yaml_with_json(xlambda_document, parsed_json['envVariables']['variables'])

        # Update the 'kind: XLambda' document in the list
        existing_yaml_data_list[existing_yaml_data_list.index(xlambda_document)] = merged_yaml_data

        # Write the updated YAML back to the file
        with open('claims.yaml', 'w') as file:
            yaml.dump_all(existing_yaml_data_list, file, default_flow_style=False)  # Set default_flow_style to False

    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
