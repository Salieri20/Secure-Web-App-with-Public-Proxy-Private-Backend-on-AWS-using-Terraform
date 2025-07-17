provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-mahmoud"
    key            = "dev/terraform.tfstate"       
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

module "vpc" {
  source   = "./modules/Network/vpc"
  vpc_cidr = "10.0.0.0/16"
  vpc_name = "my-vpc"
}

module "public_subnet_1" {
  source        = "./modules/Network/subnet"
  vpc_id        = module.vpc.vpc_id
  cidr_block    = "10.0.1.0/24"
  az            = "us-east-1a"
  name          = "public-subnet-1"
  map_public_ip = true
}

module "public_subnet_2" {
  source        = "./modules/Network/subnet"
  vpc_id        = module.vpc.vpc_id
  cidr_block    = "10.0.2.0/24"
  az            = "us-east-1b"
  name          = "public-subnet-2"
  map_public_ip = true
}

module "private_subnet_1" {
  source        = "./modules/Network/subnet"
  vpc_id        = module.vpc.vpc_id
  cidr_block    = "10.0.3.0/24"
  az            = "us-east-1a"
  name          = "private-subnet-1"
  map_public_ip = false
}

module "private_subnet_2" {
  source        = "./modules/Network/subnet"
  vpc_id        = module.vpc.vpc_id
  cidr_block    = "10.0.4.0/24"
  az            = "us-east-1b"
  name          = "private-subnet-2"
  map_public_ip = false
}

module "igw" {
  source = "./modules/Network/igw"
  vpc_id = module.vpc.vpc_id
  name   = "main-igw"
}

module "nat_gw" {
  source           = "./modules/Network/natgw"
  public_subnet_id = module.public_subnet_2.subnet_id
  name             = "main-nat"
}

module "public_rt_1" {
  source      = "./modules/Network/rt"
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.public_subnet_1.subnet_id
  name        = "public-rt-1"
  subnet_type = "public"
  igw_id      = module.igw.igw_id
}

module "public_rt_2" {
  source      = "./modules/Network/rt"
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.public_subnet_2.subnet_id
  name        = "public-rt-2"
  subnet_type = "public"
  igw_id      = module.igw.igw_id
}

module "private_rt_1" {
  source      = "./modules/Network/rt"
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.private_subnet_1.subnet_id
  name        = "private-rt-1"
  subnet_type = "private"
  natgw_id    = module.nat_gw.nat_gateway_id
}

module "private_rt_2" {
  source      = "./modules/Network/rt"
  vpc_id      = module.vpc.vpc_id
  subnet_id   = module.private_subnet_2.subnet_id
  name        = "private-rt-2"
  subnet_type = "private"
  natgw_id    = module.nat_gw.nat_gateway_id
}

module "alb_sg" {
  source  = "./modules/sg"
  name    = "alb-sg"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "web_sg" {
  source  = "./modules/sg"
  name    = "web-sg"
  vpc_id  = module.vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "bastion" {
  source = "./modules/ec2"
  name = "bastion"
  role = "bastion"
  instance_type = "t2.micro"
  subnet_id = module.public_subnet_1.subnet_id
  key_name = "my-key"
  private_key_path = "C:/Users/mahmo/.ssh/my-key.pem"
  security_group_ids = [module.web_sg.sg_id]
  associate_public_ip = true
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y tmux htop
    EOF
}

module "web_ec2_1" {
  source = "./modules/ec2"
  name = "web_ec2_1"
  role = "backend"
  instance_type = "t2.micro"
  subnet_id = module.private_subnet_1.subnet_id
  key_name = "my-key"
  private_key_path  = "C:/Users/mahmo/.ssh/my-key.pem"
  app_dir           = "./app" # Folder where Flask app exists
  bastion_host = module.bastion.public_ip
  security_group_ids = [module.web_sg.sg_id]
  associate_public_ip = false
}

module "web_ec2_2" {
  source = "./modules/ec2"
  name = "web_ec2_2"
  role = "backend"
  instance_type = "t2.micro"
  subnet_id = module.private_subnet_2.subnet_id
  key_name = "my-key"
  private_key_path  = "C:/Users/mahmo/.ssh/my-key.pem"
  app_dir           = "./app" # Folder where Flask app exists
  bastion_host = module.bastion.public_ip
  security_group_ids = [module.web_sg.sg_id]
  associate_public_ip = false
}

module "alb_private" {
  source = "./modules/alb"
  name = "alb-private"
  internal = true
  security_groups = [module.alb_sg.sg_id]
  subnets = [ module.private_subnet_1.subnet_id, module.private_subnet_2.subnet_id ]
  target_port = 80
  listener_port = 80
  vpc_id = module.vpc.vpc_id
  instance_ids = {
    instance1 = module.web_ec2_1.instance_id
    instance2 = module.web_ec2_2.instance_id 
  }
}

module "reverse_proxy_1" {
  source = "./modules/ec2"
  name = "reverse_proxy_1"
  role = "proxy"
  instance_type = "t2.micro"
  subnet_id = module.public_subnet_1.subnet_id
  key_name = "my-key"
  private_key_path  = "C:/Users/mahmo/.ssh/my-key.pem"
  security_group_ids = [module.web_sg.sg_id]
  associate_public_ip = true
  user_data = templatefile("${path.module}/nginx_reverse_proxy.sh.tpl", {
  alb_dns = module.alb_private.alb_dns_name
})
}

module "reverse_proxy_2" {
  source = "./modules/ec2"
  name = "reverse_proxy_2"
  role = "proxy"
  instance_type = "t2.micro"
  subnet_id = module.public_subnet_2.subnet_id
  key_name = "my-key"
  private_key_path  = "C:/Users/mahmo/.ssh/my-key.pem"
  security_group_ids = [module.web_sg.sg_id]
  associate_public_ip = true
  user_data = templatefile("${path.module}/nginx_reverse_proxy.sh.tpl", {
  alb_dns = module.alb_private.alb_dns_name
})
}

module "alb_public" {
  source = "./modules/alb"
  name = "alb-public"
  internal = false
  security_groups = [module.alb_sg.sg_id]
  subnets = [ module.public_subnet_1.subnet_id, module.public_subnet_2.subnet_id ]
  target_port = 80
  listener_port = 80
  vpc_id = module.vpc.vpc_id
  instance_ids = {
    instance1 = module.reverse_proxy_1.instance_id
    instance2 = module.reverse_proxy_2.instance_id 
  }
}

