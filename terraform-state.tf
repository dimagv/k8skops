terraform {
  backend "s3" {
    bucket = "insurancetruck-terraform-ss"
    key    = "insurancetruck"
    region = "eu-central-1"
    dynamodb_table = "insurancetruck-terraform-lock" # DynamoDB table to use for state locking and consistency
  }
}