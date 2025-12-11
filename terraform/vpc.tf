resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "patient-service-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = { Name = "patient-service-igw" }
}

# Use available AZs in the region and distribute subnets across them
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  # for_each uses index => cidr so we can pick an AZ from var.azs by index
  for_each = { for idx, cidr in var.public_subnets : tostring(idx) => cidr }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = var.azs[tonumber(each.key) % length(var.azs)]
  map_public_ip_on_launch = true
  tags = { Name = "public-${each.value}" }
}

resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnets : tostring(idx) => cidr }
  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = var.azs[tonumber(each.key) % length(var.azs)]
  tags = { Name = "private-${each.value}" }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Allocate Elastic IPs and create one NAT Gateway per public subnet (one NAT per AZ)
resource "aws_eip" "nat" {
  for_each = aws_subnet.public
  vpc = true
  tags = { Name = "nat-eip-${each.key}" }
}

resource "aws_nat_gateway" "nat" {
  for_each = aws_subnet.public
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  tags = { Name = "nat-gw-${each.key}" }
}

# Create a private route table per private subnet and route traffic to the NAT GW in the same AZ
resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[each.key].id
  }
  tags = { Name = "private-rt-${each.key}" }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private[each.key].id
}

# Security group for Lambdas placed in the VPC
resource "aws_security_group" "lambda_sg" {
  name        = "patient-service-lambda-sg"
  description = "Security group for Lambda functions in VPC"
  vpc_id      = aws_vpc.main.id

  # Allow all outbound so Lambda can reach external services if needed
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Restrictive inbound (Lambda doesn't need inbound from internet)
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = []
  }

  tags = { Name = "patient-service-lambda-sg" }
}
