resource "aws_vpc" "utc_app_vpc" {
  cidr_block           = "172.120.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name       = "utc-app1"
    env        = "dev"
    team       = "wdp"
    created_by = "Jean"
  }
}

resource "aws_internet_gateway" "dev_wdp_igw" {
  vpc_id = aws_vpc.utc_app_vpc.id

  tags = {
    Name = "dev-wdp-IGW"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.utc_app_vpc.id
  cidr_block              = "172.120.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.utc_app_vpc.id
  cidr_block              = "172.120.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet 2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id     = aws_vpc.utc_app_vpc.id
  cidr_block = "172.120.2.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private Subnet 1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id     = aws_vpc.utc_app_vpc.id
  cidr_block = "172.120.3.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.utc_app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_wdp_igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}



resource "aws_security_group" "webserver_sg" {
  name   = "webserver-sg"
  vpc_id = aws_vpc.utc_app_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["108.73.21.244/32"] # Replace <your_ip> with your actual IP address
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Generates a secure private k ey and encodes it as PEM
resource "tls_private_key" "utc-key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
# Create the Key Pair
resource "aws_key_pair" "utc-key" {
  key_name   = "privatekeypair"
  public_key = tls_private_key.utc-key.public_key_openssh
}
# Save file
resource "local_file" "ssh_key" {
  filename = "utc-key.pem"
  content  = tls_private_key.utc-key.private_key_pem
}

#create ec2 instances 

resource "aws_instance" "utc_dev_inst" {
  ami                    = "ami-06a0cd9728546d178"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public_subnet_1.id
  security_groups        = [aws_security_group.webserver_sg.id]
  key_name               = aws_key_pair.utc-key.key_name

  user_data = file("install.sh")

  tags = {
    Name : "utc-dev-inst"
    Team : "Cloud Transformation"
    Environment : "Dev"
    Created_by : "Jean"
  }
}
output "ssh-command" {
  value = "ssh -i utc-key.pem ec2-user@${aws_instance.utc_dev_inst.public_dns}"
}

output "public-ip" {
  value = aws_instance.utc_dev_inst.public_ip
}