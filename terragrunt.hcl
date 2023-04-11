remote_state {
    backend = "s3"
    config = {
        bucket         = "dev-terraform-state-backend-lahiru"
        key            = "${path_relative_to_include()}/terrafrom.tfstate"
        region         = "us-east-1"
        encrypt        = true
        dynamodb_table = "dev-terraform_state"
    }
    generate = {
        path           = "backend.tf"
        if_exists      = "overwrite_terragrunt"
    }
}

generate "provider" {
        path = "provider.tf"
        if_exists = "overwrite_terragrunt"
        contents = <<EOF
            provider "aws" {
            region = "us-east-1"
            }
            
        EOF
}