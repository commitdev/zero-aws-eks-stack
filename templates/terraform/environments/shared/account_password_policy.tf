# This will enforce security policies for the entire account around what kinds of passwords IAM users can set.
resource "aws_iam_account_password_policy" "account_password_policy" {
  minimum_password_length        = 14
  require_numbers                = true
  require_symbols                = true
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  allow_users_to_change_password = true
  password_reuse_prevention      = 24
  hard_expiry                    = false
  max_password_age               = 180
}

# # The above settings are quite secure, while also being more user friendly by allowing longer between password resets, and not hard-locking an account when the password expires.
# # To fully comply with the AWS CIS Benchmark, you can instead use the policy below.
# # https://docs.aws.amazon.com/securityhub/latest/userguide/securityhub-cis-controls.html
# resource "aws_iam_account_password_policy" "aws_foundations_benchmark_policy" {
#   minimum_password_length        = 14
#   require_numbers                = true
#   require_symbols                = true
#   require_lowercase_characters   = true
#   require_uppercase_characters   = true
#   allow_users_to_change_password = true
#   password_reuse_prevention      = 24
#   hard_expiry                    = true
#   max_password_age               = 90
# }



