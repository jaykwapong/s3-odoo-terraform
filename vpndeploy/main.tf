provider "aws" {
  profile = "default"
  region  = var.region
}

//vpc
# resource "aws_vpc" "azure_vpc" {
#   cidr_block = "10.10.0.0/16"
#   tags = {
#     Name = "azure_vpc"
#   }
# }

//get vpc instead of creating new
data "aws_vpc" "ssx-prod-vpc" {
  filter {
    name   = "tag:Name"
    values = ["ssx-prod"]
  }
}


//subnet

resource "aws_subnet" "azure_private" {
  vpc_id            = data.aws_vpc.ssx-prod-vpc.id
  cidr_block        = "10.10.0.0/24"
  tags = {
    Name = "azure_private"
  }
}

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
resource "aws_customer_gateway" "azure_2" {
  bgp_asn    = 65000
  ip_address = "23.97.178.236"
  type       = "ipsec.1"

  tags = {
    Name = "azure-vpn-customer-gateway-2"
  }
}

//route tables 

resource "aws_route_table" "private" {
  vpc_id = data.aws_vpc.ssx-prod-vpc.id
  tags = {
    Name = "private-route-table"
  }
}
//create route for igw
resource "aws_route" "public_igw" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = data.aws_internet_gateway.gw.id
}
//create route for vgw
resource "aws_route" "private_igw" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "10.100.2.0/24"
  gateway_id =  data.aws_internet_gateway.gw.id
}

resource "aws_vpn_connection" "example" {
  customer_gateway_id = aws_customer_gateway.azure_2.id
  vpn_gateway_id = aws_vpn_gateway.azure_vpn_gateway.id
  type = "ipsec.1"
  tags = {
    Name = "aws_vpn_connection_new"
  }
}




# resource "aws_customer_gateway" "azure-cgw" {
#   bgp_asn    = 65000
#   ip_address = "172.83.124.10"
#   type       = "ipsec.1"

#   tags = {
#     Name = "azure-cgw"
#   }
# }

# resource "aws_vpn_gateway" "vpn_gw" {
#   vpc_id = data.aws_vpc.ssx-prod.id

#   tags = {
#     Name = "azure-vpn-gw"
#   }
# }

# resource "aws_route_table" "example" {
#   vpc_id = data.aws_vpc.ssx-prod.id

#   route {
#     cidr_block = "10.100.2.0/24"
#     gateway_id = aws_vpn_gateway.vpn_gw.id
#   }

#   tags = {
#     Name = "azure-vpn-route-table"
#   }
# }

