provider "aws" {
  profile = "default"
  region  = var.region
}

//get vpc instead of creating new
data "aws_vpc" "ssx-prod-vpc" {
  filter {
    name   = "tag:Name"
    values = ["ssx-prod"]
  }
}


//subnet

# resource "aws_subnet" "azure_private" {
#   vpc_id            = data.aws_vpc.ssx-prod-vpc.id
#   cidr_block        = "10.10.0.0/24"
#   tags = {
#     Name = "azure_private"
#   }
# }

//virtual gateway
resource "aws_vpn_gateway" "azure_vpn_gateway" {
  tags = {
    Name = "azure_vpn_gateway"
  }
}

//attach virtual gateway
resource "aws_vpn_gateway_attachment" "vpn_attachment" {
  vpc_id         = data.aws_vpc.ssx-prod-vpc.id
  vpn_gateway_id = aws_vpn_gateway.azure_vpn_gateway.id
}

//internet gateway already created
# resource "aws_internet_gateway" "gw" {
#   vpc_id = data.aws_vpc.ssx-prod.id

#   tags = {
#     Name = "azure_vpc-internet-gateway"
#   }
# }
//get exiting internet gateway already created
data "aws_internet_gateway" "gw" {
  filter {
    name   = "tag:Name"
    values = ["ssx-prod"]
  }
}

//customer gateway
resource "aws_customer_gateway" "azure_new" {
  bgp_asn    = 65000
  ip_address = "23.100.11.14"
  type       = "ipsec.1"

  tags = {
    Name = "azure-vpn-customer-gateway-2"
  }
}

//route tables 
data "aws_route_table" "private" {
  vpc_id = data.aws_vpc.ssx-prod-vpc.id
  filter {
    name   = "tag:Name"
    values = ["ssx-prod-public"]
  }
}
# resource "aws_route_table" "private" {
#   vpc_id = data.aws_vpc.ssx-prod-vpc.id
#   tags = {
#     Name = "private-route-table"
#   }
# }
//create route for igw
resource "aws_route" "public_igw" {
  route_table_id            = data.aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = data.aws_internet_gateway.gw.id
}
//create routes for vgw , added additional block
resource "aws_route" "private_igw" {
  route_table_id            = data.aws_route_table.private.id
  destination_cidr_block    = "10.100.0.0/16"
  gateway_id                = aws_vpn_gateway.azure_vpn_gateway.id
}

//add new route requested
resource "aws_route" "private_igw2" {
  route_table_id            = data.aws_route_table.private.id
  destination_cidr_block    = "10.100.2.0/24"
  gateway_id                = aws_vpn_gateway.azure_vpn_gateway.id
}



resource "aws_vpn_connection" "main" {
  customer_gateway_id = aws_customer_gateway.azure_new.id
  vpn_gateway_id = aws_vpn_gateway.azure_vpn_gateway.id
  type = "ipsec.1"
  static_routes_only  = true
  tags = {
    Name = "aws_vpn_connection_new"
  }
}
//get the route tables  

resource "aws_vpn_connection_route" "route1" {
  destination_cidr_block = "10.100.0.0/16"
  vpn_connection_id      = aws_vpn_connection.main.id
}

resource "aws_vpn_connection_route" "route2" {
  destination_cidr_block = "10.100.2.0/24"
  vpn_connection_id      = aws_vpn_connection.main.id
}


