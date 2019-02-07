provider "aws" {
  region = "us-east-1"
}
resource "aws_security_group" "SG-INSTANCE" {
  vpc_id = "${var.vpc-id}"

  ingress {
    description = "ssh port"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "ec2_sg"
  }
}
resource "aws_instance" "EC2" {
  ami = "${var.instance_ami}"
  instance_type = "t2.micro"
  subnet_id = "${var.subnet-id}"
  vpc_security_group_ids = ["${aws_security_group.SG-INSTANCE.id}"]
  user_data = "${file("userdata.sh")}"
  tags {
    Name = "tf_ec2"
  }
}
resource "aws_security_group" "SG-ELB" {
  vpc_id = "${var.vpc-id}"

  ingress {
    from_port = 80
    protocol = "tcp"
    to_port = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags {
    Name = "terra_elb_sg"
  }
}

resource "aws_elb" "ELB" {
  subnets         = ["${var.subnet-id}"]
  security_groups = ["${aws_security_group.SG-ELB.id}"]
  instances = ["${aws_instance.EC2.id}"]

  listener {
    instance_port     = "80"
    instance_protocol = "HTTP"
    lb_port           = "80"
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/index.php"
    interval            = 6
    healthy_threshold   = 2
    unhealthy_threshold = 5
    timeout             = 4
  }
  tags {
    Name = "tf-elb"
  }
}
