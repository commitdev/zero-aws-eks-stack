terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

provider "aws" {
  region              = "<% index .Params `region` %>"
  allowed_account_ids = ["<% index .Params `accountId` %>"]
}

resource "aws_s3_bucket" "terraform_remote_state" {
  bucket = "<% .Name %>-${var.environment}-terraform-state"
}

resource "aws_s3_bucket_acl" "terraform_remote_state" {
  bucket = aws_s3_bucket.terraform_remote_state.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "terraform_remote_state" {
  bucket = aws_s3_bucket.terraform_remote_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_remote_state" {
  bucket = aws_s3_bucket.terraform_remote_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_remote_state" {
  bucket = aws_s3_bucket.terraform_remote_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_state_locks" {
  name           = "<% .Name %>-${var.environment}-terraform-state-locks"
  read_capacity  = 2
  write_capacity = 2
  hash_key       = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

variable "environment" {
  description = "The environment (stage/prod)"
}
