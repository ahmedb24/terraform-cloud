#############################
##Creating bucket for s3 backend
#########################

# resource "aws_s3_bucket" "terraform-state" {
#   bucket        = "terraform-ahmed-dev"
# }

# resource "aws_s3_bucket_versioning" "version" {
#   bucket = aws_s3_bucket.terraform-state.id
#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "first" {
#   bucket = aws_s3_bucket.terraform-state.id
#   rule {
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }


# Creating VPC
module "VPC" {
  source                         = "./modules/VPC"
  region                         = var.region
  vpc_cidr                       = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_classiclink             = var.enable_classiclink
  public_sn_count                = var.public_sn_count
  private_sn_count               = var.private_sn_count
  max_subnets                    = var.max_subnets
  enable_classiclink_dns_support = var.enable_classiclink_dns_support
  private_subnets                = [for i in range(1, 8, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_subnets                 = [for i in range(2, 5, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
}

# Creating Security
module "security" {
  source = "./modules/Security"
  vpc_id = module.VPC.vpc_id
}

# #Module for Application Load balancer, this will create Extenal Load balancer and internal load balancer
module "ALB" {
  source             = "./modules/ALB"
  name               = join("-", [var.name, "ext-alb"])
  vpc_id             = module.VPC.vpc_id
  public-sg          = module.security.ALB-sg
  private-sg         = module.security.IALB-sg
  public-sbn-1       = module.VPC.public_subnets-1
  public-sbn-2       = module.VPC.public_subnets-2
  private-sbn-1      = module.VPC.private_subnets-1
  private-sbn-2      = module.VPC.private_subnets-2
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
}

module "AutoScaling" {
  source = "./modules/Autoscaling"
  # ami-web           = lookup(var.ami, var.region, "ami-066fe873bf6478b40")
  # ami-bastion       = lookup(var.ami, var.region, "ami-028fa79f6e6052a9c")
  # ami-nginx         = lookup(var.ami, var.region, "ami-0e57ecde442b59faa")
  ami-web           = "ami-0158eafefcf9c1918"
  ami-bastion       = "ami-066cd2a0da587cc39"
  ami-nginx         = "ami-0ba600043349cd6e9"
  desired_capacity  = 1
  min_size          = 1
  max_size          = 2
  web-sg            = [module.security.web-sg]
  bastion-sg        = [module.security.bastion-sg]
  nginx-sg          = [module.security.nginx-sg]
  wordpress-alb-tgt = module.ALB.wordpress-tgt
  nginx-alb-tgt     = module.ALB.nginx-tgt
  tooling-alb-tgt   = module.ALB.tooling-tgt
  instance_profile  = module.VPC.instance_profile
  public_subnets    = [module.VPC.public_subnets-1, module.VPC.public_subnets-2]
  private_subnets   = [module.VPC.private_subnets-1, module.VPC.private_subnets-2]
  keypair           = var.keypair

}

# Module for Elastic Filesystem; this module will create elastic file system in the webservers availablity
# zone and allow traffic from the webservers

module "EFS" {
  source       = "./modules/EFS"
  efs-subnet-1 = module.VPC.private_subnets-1
  efs-subnet-2 = module.VPC.private_subnets-2
  efs-sg       = [module.security.datalayer-sg]
  account_no   = var.account_no
}

