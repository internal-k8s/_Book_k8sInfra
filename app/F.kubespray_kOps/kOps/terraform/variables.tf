variable state_store {}

variable "policy_arns" {
  type = map(string)
  description = "Policies need to be attached to use kops"
  default = {
    "ec2" = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
    "route53" = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
    "s3" = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
    "iam" = "arn:aws:iam::aws:policy/IAMFullAccess"
    "vpc" = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
    "sqs" = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
    "eventbridge" = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
  }

}
