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

# Initialize YAML data with parameter values
data = {
    "envVariables": [{
        "variables": {param: value for param, value in parameter_values.items()}
    }]
}

# Specify the output file path
output_file_path = "./envs.out"

# Write the updated YAML to the new file "envs.out" (overwriting if it exists)
with open(output_file_path, "w") as file:
    yaml.dump(data, file)

