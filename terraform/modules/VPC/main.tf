# Get list of availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_shuffle" "public_az" {
  input        = data.aws_availability_zones.available.names
  result_count = var.max_subnets
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block                     = var.vpc_cidr
  enable_dns_support             = var.enable_dns_support
  enable_dns_hostnames           = var.enable_dns_hostnames
  enable_classiclink             = var.enable_classiclink
  enable_classiclink_dns_support = var.enable_classiclink_dns_support

  tags = merge(
    var.tags,
    {
      Name = format("%s-VPC", var.name)
    },
  )
}

# Create public subnets
resource "aws_subnet" "public" {
  count                   = var.public_sn_count == null ? length(data.aws_availability_zones.available.names) : var.public_sn_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnets[count.index]
  map_public_ip_on_launch = true
  availability_zone       = var.public_sn_count == null ? data.aws_availability_zones.available.names[count.index] : random_shuffle.public_az.result[count.index]

  tags = merge(
    var.tags, 
    {
     Name = format("PublicSubnet-%s", count.index)
    }
  )
}

# Create private subnets
resource "aws_subnet" "private" {
  count                   = var.private_sn_count == null ? length(data.aws_availability_zones.available.names) : var.private_sn_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.private_subnets[count.index]
  map_public_ip_on_launch = false
  availability_zone       = var.private_sn_count == null ? data.aws_availability_zones.available.names[count.index] : random_shuffle.public_az.result[count.index]

  tags = merge(
    var.tags, 
    {
     Name = format("%s-PrivateSubnet-%s", var.name, count.index)
    }
  )
}