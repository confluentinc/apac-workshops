resource "aws_security_group" "jupyter" {
    name = "vpc_lab"
    description = "Allow incoming HTTP connections."

    ingress {
        from_port = 8881
        to_port = 8881
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8882
        to_port = 8882
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8883
        to_port = 8883
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8884
        to_port = 8884
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8885
        to_port = 8885
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 8886
        to_port = 8886
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
        Name = "JupyterLab"
    }
}

data "template_file" "user_data_jupyter" {
  template = file("install_docker.sh")
}

resource "aws_instance" "lab-1-instance" {
    ami = lookup(var.amis, var.aws_region)
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.large"
    key_name = var.aws_key_name
    vpc_security_group_ids = [aws_security_group.jupyter.id]
    subnet_id = aws_subnet.ap-southeast-1a-public.id
    associate_public_ip_address = true
    source_dest_check = false

    user_data = data.template_file.user_data_jupyter.rendered

    tags = {
        Name = ""
    }
}

resource "aws_eip" "lab-1-eip" {
    instance = aws_instance.lab-1-instance.id
    vpc = true
}

resource "aws_instance" "lab-2-instance" {
    ami = lookup(var.amis, var.aws_region)
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.large"
    key_name = var.aws_key_name
    vpc_security_group_ids = [aws_security_group.jupyter.id]
    subnet_id = aws_subnet.ap-southeast-1a-public.id
    associate_public_ip_address = true
    source_dest_check = false

    user_data = data.template_file.user_data_jupyter.rendered

    tags = {
        Name = ""
    }
}

resource "aws_eip" "lab-2-eip" {
    instance = aws_instance.lab-2-instance.id
    vpc = true
}

resource "aws_instance" "lab-3-instance" {
    ami = lookup(var.amis, var.aws_region)
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.large"
    key_name = var.aws_key_name
    vpc_security_group_ids = [aws_security_group.jupyter.id]
    subnet_id = aws_subnet.ap-southeast-1a-public.id
    associate_public_ip_address = true
    source_dest_check = false

    user_data = data.template_file.user_data_jupyter.rendered

    tags = {
        Name = ""
    }
}

resource "aws_eip" "lab-3-eip" {
    instance = aws_instance.lab-3-instance.id
    vpc = true
}

resource "aws_instance" "lab-4-instance" {
    ami = lookup(var.amis, var.aws_region)
    availability_zone = "ap-southeast-1a"
    instance_type = "t2.large"
    key_name = var.aws_key_name
    vpc_security_group_ids = [aws_security_group.jupyter.id]
    subnet_id = aws_subnet.ap-southeast-1a-public.id
    associate_public_ip_address = true
    source_dest_check = false

    user_data = data.template_file.user_data_jupyter.rendered

    tags = {
        Name = ""
    }
}

resource "aws_eip" "lab-4-eip" {
    instance = aws_instance.lab-4-instance.id
    vpc = true
}
