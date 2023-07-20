#!/usr/bin/env python3

import yaml
import subprocess

# Fetch parameter values from AWS Systems Manager Parameter Store
parameter_values = {}
with open("../envs", "r") as env_file:
    for line in env_file:
        parameter = line.strip()
        value = subprocess.check_output(
            ["aws-vault", "exec", "precious.okwu", "--", "aws", "ssm", "get-parameter", "--name", parameter, "--query", "Parameter.Value", "--output", "text"],
            universal_newlines=True
        ).strip()
        parameter_values[parameter] = value

# Specify the output file path
output_file_path = "./envs.out"

# Write the parameter-value pairs as plain text to the new file "envs.out" (overwriting if it exists)
with open(output_file_path, "w") as file:
    for param, value in parameter_values.items():
        file.write(f"{param}: {value}\n")

# Store the value in a YAML file
yaml_data = {
    "envVariables": [
        {"variables": parameter_values}
    ]
}

# Write the YAML data to the "envs.out" file in YAML format
with open(output_file_path, "w") as yaml_file:
    yaml.dump(yaml_data, yaml_file, default_flow_style=False)
