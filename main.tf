data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}



################################################################################
# VPC Module
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  
  # Public Subnet (Inspection Appliance - Needs direct IGW access)
  public_subnets  = [var.inspection_subnet_cidr]
  public_subnet_names = ["inspection-subnet"]
  
  # Private Subnet (Application Server - Needs routing via Inspection)
  private_subnets = [var.public_subnet_cidr]
  private_subnet_names = ["public-subnet-application"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  # Ensure we have IGW
  create_igw = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

# START: Custom Routing Logic

# 1. Edge Route Table (Ingress Routing)
# Routes traffic destined for the Public Subnet (App) to the Inspection ENI
resource "aws_route_table" "edge_ingress" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block           = var.public_subnet_cidr
    network_interface_id = module.inspection_instance.primary_network_interface_id
  }

  tags = {
    Name = "${local.name}-edge-rt"
  }
}

resource "aws_route_table_association" "edge_ingress" {
  gateway_id     = module.vpc.igw_id
  route_table_id = aws_route_table.edge_ingress.id
}

# 2. Application Subnet Custom Route (Egress)
# Traffic from the Application Subnet destined for the Internet (0.0.0.0/0)
# must go through the Inspection ENI to ensure symmetric routing.
resource "aws_route" "app_to_inspection" {
  route_table_id         = module.vpc.private_route_table_ids[0]
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = module.inspection_instance.primary_network_interface_id
}

# END: Custom Routing Logic


################################################################################
# Security Groups Module
################################################################################

module "inspection_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-inspection-sg"
  description = "Security group for inspection appliance"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"] # 'all-icmp' enables ping for troubleshooting
  
  # SSH access
  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = var.allowed_mgmt_cidr
    }
  ]

  egress_rules = ["all-all"]
}

module "application_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-application-sg"
  description = "Security group for application server"
  vpc_id      = module.vpc.vpc_id

  # Ingress from ANY (0.0.0.0/0) because traffic comes from Inspection Appliance
  # which preserves source IP if just routing, OR if masquerading acts as source.
  # The requirement says "routing", implying source IP preservation.
  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"] # 'all-icmp' enables ping for troubleshooting

  # SSH access
  ingress_with_cidr_blocks = [
    {
      rule        = "ssh-tcp"
      cidr_blocks = var.allowed_mgmt_cidr
    }
  ]

  egress_rules = ["all-all"]
}

################################################################################
# Compute Module
################################################################################

# Inspection Appliance
module "inspection_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${local.name}-inspection"

  instance_type          = var.instance_type
  ami                    = data.aws_ami.amazon_linux.id
  key_name               = var.ssh_key_name
  monitoring             = true
  vpc_security_group_ids = [module.inspection_sg.security_group_id]
  subnet_id              = module.vpc.public_subnets[0] # Inspection Subnet (Now Public)
  associate_public_ip_address = true

  # Critical for Routing
  source_dest_check      = false

  user_data = file("${path.module}/scripts/inspection_userdata.sh")

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Role        = "inspection"
  }
}

# Application Server
module "application_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 5.0"

  name = "${local.name}-application"

  instance_type          = var.instance_type
  ami                    = data.aws_ami.amazon_linux.id
  key_name               = var.ssh_key_name
  monitoring             = true
  vpc_security_group_ids = [module.application_sg.security_group_id]
  subnet_id              = module.vpc.private_subnets[0] # Public Subnet (Now "Private" routing)
  associate_public_ip_address = true

  user_data = file("${path.module}/scripts/app_userdata.sh")

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Role        = "application"
  }
}
