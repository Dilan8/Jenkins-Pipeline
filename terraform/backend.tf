terraform {
  backend "s3" {
    bucket         = "terraform-state-cicd-409324"
    key            = "cicd-project/terraform.tfstate"
    region         = "ap-southeast-2"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}