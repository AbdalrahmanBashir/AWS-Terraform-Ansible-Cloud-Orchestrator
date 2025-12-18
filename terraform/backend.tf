terraform {
    backend "s3" {
        bucket = "bashir-tf-state-2025"
        key = "dev/platform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-lock"
        encrypt = true
    }
}