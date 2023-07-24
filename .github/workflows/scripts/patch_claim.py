import ruamel.yaml

def merge_variables(source_file, target_file):
    # Load the YAML data from the source file (envs.out)
    with open(source_file) as envs_file:
        envs_yaml = ruamel.yaml.round_trip_load(envs_file)

    # Extract the variables from envs.out
    variables = envs_yaml.get("envVariables", [{}])[0].get("variables", {})

    # Load the YAML data from the target file (claims.yaml)
    with open(target_file) as claims_file:
        claims_content = claims_file.read()

    # Split the YAML content into separate documents
    claims_yaml_docs = list(ruamel.yaml.round_trip_load_all(claims_content))

    # Merge the variables into each document's envVariables in claims.yaml (for kind: XLambda)
    for doc in claims_yaml_docs:
        if "kind" in doc and doc["kind"] == "XLambda" and "spec" in doc and "parameters" in doc["spec"]:
            env_vars = doc["spec"]["parameters"].setdefault("envVariables", [])
            if not env_vars:
                env_vars.append({"variables": {}})
            env_vars[0]["variables"].update(variables)

    # Write the updated YAML data back to the target file (claims.yaml)
    with open(target_file, 'w') as output:
        yaml = ruamel.yaml.YAML()
        yaml.preserve_quotes = True
        yaml.explicit_start = True
        yaml.indent(mapping=2, sequence=4, offset=2)
        for doc in claims_yaml_docs:
            yaml.dump(doc, output)

if __name__ == "__main__":
    envs_out_file = "./envs.out"
    claims_yaml_file = "./claims.yaml"

    merge_variables(envs_out_file, claims_yaml_file)
