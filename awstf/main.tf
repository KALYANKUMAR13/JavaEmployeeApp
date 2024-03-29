//Creating VPC and value of CIDR is getting from variable.tf
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
  tags = {
    Name = "aws-tf-vpc"
  }
}

//Creating a Subnet in a AZ and associated with in VPC
resource "aws_subnet" "sub1" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ca-central-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "aws-tf-subnet1"
  }
}
//Creating a Subnet in another AZ and associated with in VPC
resource "aws_subnet" "sub2" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ca-central-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "aws-tf-subnet2"
  }
}

//Creating a Internet gateway in the same VPC
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
  tags = {
    Name = "aws-tf-IG"
  }
}

# Creating a route table 
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "aws-tf-route-table"
  }
}

// Associating subnets to the Route table
resource "aws_route_table_association" "rta1" {
  subnet_id      = aws_subnet.sub1.id
  route_table_id = aws_route_table.RT.id
}
// Associating subnets to the Route table
resource "aws_route_table_association" "rta2" {
  subnet_id      = aws_subnet.sub2.id
  route_table_id = aws_route_table.RT.id
}

// Creating Security Group
resource "aws_security_group" "sg" {
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "aws-sg-tf"
  }
}
//Creating S3 bucket and provide a globally unique name
resource "aws_s3_bucket" "s3bucket" {
  bucket = "kalyankumarawstf-s3create-bucket"
  tags = {
    Name = "aws-tf-s3"
  }

}

resource "aws_instance" "webserver" {
  ami                    = "ami-05d4121edd74a9f06"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.sub1.id
  user_data              = base64encode(file("userdata.sh"))
  tags = {
    Name = "aws-ec2-w1"
  }
}

resource "aws_instance" "webserver1" {
  ami                    = "ami-05d4121edd74a9f06"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.sg.id]
  subnet_id              = aws_subnet.sub2.id
  user_data              = base64encode(file("userdata1.sh"))
  tags = {
    Name = "aws-ec2-w2"
  }
}

resource "aws_alb" "my-alb" {
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
  tags = {
    Name = "aws-lb"
  }
}

resource "aws_lb_target_group" "target-group" {
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "attach1" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.webserver.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "attach2" {
  target_group_arn = aws_lb_target_group.target-group.arn
  target_id        = aws_instance.webserver1.id
  port             = 80
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.my-alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    target_group_arn = aws_lb_target_group.target-group.arn
    type             = "forward"
    
  }
}

output "loadBalancerDns" {
  value = aws_alb.my-alb.dns_name
}
