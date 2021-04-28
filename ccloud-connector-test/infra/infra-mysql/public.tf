resource "aws_security_group" "db" {
    name = "vpc_lab"
    description = "Allow incoming TCP connections."

    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = aws_vpc.default.id

    tags = {
        Name = "db"
    }
}

data "template_file" "user_data_db" {
  template = file("install_mysql.sh")
}

resource "aws_instance" "db-instance" {
    ami = lookup(var.amis, var.aws_region)
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.large"
    key_name = var.aws_key_name
    vpc_security_group_ids = [aws_security_group.db.id]
    subnet_id = aws_subnet.ap-southeast-1a-public.id
    associate_public_ip_address = true
    source_dest_check = false

    user_data = data.template_file.user_data_db.rendered

    tags = {
        Name = "db-instance"
    }
}

resource "aws_eip" "db-eip" {
    instance = aws_instance.db-instance.id
    vpc = true
}

output "instance_ips" {
  value = aws_instance.db-instance.public_ip
}

output "instance_dns" {
  value = aws_instance.db-instance.public_dns
}
