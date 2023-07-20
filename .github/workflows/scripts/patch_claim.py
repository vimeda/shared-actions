import ruamel.yaml

def replace_env_variables(original_file, patch_file):
    with open(original_file, 'r') as f1, open(patch_file, 'r') as f2:
        claim_data = ruamel.yaml.safe_load_all(f1)
        patch_data = ruamel.yaml.safe_load_all(f2)

        # Convert the data to a list so that we can modify the documents
        claim_data = list(claim_data)
        patch_data = list(patch_data)

    for i, doc in enumerate(claim_data):
        if doc['kind'] == 'XLambda':
            # Merge the envVariables from patch_file into claim_data
            claim_data[i]['spec']['parameters']['envVariables'][0]['variables'] = patch_data[0]['envVariables'][0]['variables']

    # Write the updated data back to claim.yaml
    with open(original_file, 'w') as f1:
        yaml = ruamel.yaml.YAML()
        yaml.preserve_quotes = True
        yaml.indent(mapping=2, sequence=4, offset=2)
        yaml.dump_all(claim_data, f1)

claim_file = "../claims.yaml"
patch_file = "./envs.out"

replace_env_variables(claim_file, patch_file)
