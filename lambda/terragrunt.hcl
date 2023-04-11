include {
    path = find_in_parent_folders()
}

terraform {
  
  source = "main.tf"
}





locals {
    env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))    
}

inputs = {

    
}

