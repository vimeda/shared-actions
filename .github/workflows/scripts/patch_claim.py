import ruamel.yaml

def merge_env_variables(claims_file, env_file, output_file):
    yaml = ruamel.yaml.YAML()

    with open(claims_file, "r") as claims, open(env_file, "r") as envs:
        claims_data = list(yaml.load_all(claims))
        env_data = yaml.load(envs)

        # Find the section with kind "XLambda" and merge envVariables
        for item in claims_data:
            if item.get('kind') == 'XLambda':
                item['spec']['parameters']['envVariables'] = env_data['envVariables']
                break

    with open(output_file, "w") as output:
        yaml.dump_all(claims_data, output)

if __name__ == "__main__":
    claims_file = "./claims.yaml"  # Replace with your claims.yaml file
    env_file = "./envs.out"  # Replace with the output file generated previously
    output_file = claims_file  # Replace with the desired output file name
    merge_env_variables(claims_file, env_file, output_file)
