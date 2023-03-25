region = "eu-central-1"

vpc_cidr = "172.16.0.0/16"

enable_dns_support = "true"

enable_dns_hostnames = "true"

enable_classiclink = "false"

enable_classiclink_dns_support = "false"

environment = "production"

ami = {
  eu-central-1 = "ami-0d1ddd83282187d18"
  us-west-2    = "image-23834"
}

keypair = "devops"

# Ensure to change this to your acccount number
account_no = "767423351130"

master-username = "ahmed"

master-password = "devopspbl"

tags = {
  Enviroment      = "production"
  Owner-Email     = "erma2106@gmailos.com"
  Managed-By      = "Terraform"
  Billing-Account = "1234567890"
}