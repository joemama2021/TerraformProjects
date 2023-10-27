provider "aws"{
    region = "us-east-1"
    access_key = "__access_key__"
    secret_key = "__secret_key__"


}
//create a VPC
resource "aws_vpc" "vpc-01" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "prod-vpc"
  }
  
}

//create a gateway
resource "aws_internet_gateway" "gateway-01" {
    vpc_id = aws_vpc.vpc-01.id
  
}

//create a routing tsble
resource "aws_route_table" "rtable-01" {
    vpc_id = aws_vpc.vpc-01.id

    route  {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.gateway-01.id
    }
    
}

//create a subnet
resource "aws_subnet" "subnet-01" {
    vpc_id = aws_vpc.vpc-01.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
  
}

//link routing table to subnet
resource "aws_route_table_association" "tableass-01" {
    subnet_id = aws_subnet.subnet-01.id
    route_table_id = aws_route_table.rtable-01.id
}

//create security group
resource "aws_security_group" "sg-01" {
    name = "allow_web_traffic"
    description = "Allow web traffic"
    vpc_id = aws_vpc.vpc-01.id

    ingress  {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress  {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress  {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    egress  {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "allow-web-traffic"
    }
}

//create network interface
resource "aws_network_interface" "int-01" {
  subnet_id = aws_subnet.subnet-01.id
  security_groups = [aws_security_group.sg-01.id]
  private_ips = ["10.0.1.50"]


}

//assign an elastic ip
resource "aws_eip" "elastic-01" {
  network_interface = aws_network_interface.int-01.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [ aws_internet_gateway.gateway-01 ]
}

//create the server
resource "aws_instance" "webserver" {
  ami = "ami-0fc5d935ebf8bc3bc"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"

  key_name = "webserver01"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.int-01.id
  }

    user_data = <<-EOF
#!bin/bash/
sudo apt update -y
sudo apt isntall apache2 -y
sudo systemctl start apache2
sudo bash -c "echo your very first webserver > /var/www/html/index.html"
EOF
    tags = {
      Name = "Web server"
    }

}


