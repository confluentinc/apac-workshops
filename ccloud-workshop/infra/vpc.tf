resource "aws_vpc" "default" {
    cidr_block = var.vpc_cidr
    enable_dns_hostnames = true
    tags = {
        Name = "confluent-vpc"
    }
}

resource "aws_internet_gateway" "default" {
    depends_on = [aws_vpc.default,]

    vpc_id = aws_vpc.default.id
    
    tags = {
        Name = "igw"
    }
}

resource "aws_subnet" "ap-southeast-1a-public" {
    depends_on = [aws_vpc.default,]
    vpc_id = aws_vpc.default.id

    cidr_block = var.public_subnet_cidr
    availability_zone = "ap-southeast-1a"

    map_public_ip_on_launch = true

    tags = {
        Name = "Public Subnet"
    }
}

resource "aws_route_table" "ap-southeast-1a-public" {
    depends_on = [aws_vpc.default, aws_internet_gateway.default,]

    vpc_id = aws_vpc.default.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.default.id
    }

    tags = {
        Name = "Public Subnet"
    }
}

resource "aws_route_table_association" "a" {
    depends_on = [aws_subnet.ap-southeast-1a-public, aws_route_table.ap-southeast-1a-public]
    subnet_id = aws_subnet.ap-southeast-1a-public.id
    route_table_id = aws_route_table.ap-southeast-1a-public.id
}
