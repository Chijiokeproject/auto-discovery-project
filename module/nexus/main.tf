# IAM Role for SSM
resource "aws_iam_role" "nexus_ssm_role" {
  name = "${var.name}-nexus-ssm-role"

  # Allows EC2 service to assume this role
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action    = "sts:AssumeRole"
    }]
  })
}

# Attach SSM permissions so EC2 can be managed via Systems Manager
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.nexus_ssm_role.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile to associate the IAM role with the EC2 instance
resource "aws_iam_instance_profile" "ssm_profile" {
  name = "${var.name}-nexus-instance-profile"
  role = aws_iam_role.nexus_ssm_role.id
}

# Nexus Security Group
resource "aws_security_group" "nexus_sg" {
  name   = "${var.name}-nexus-sg"
  vpc_id = var.vpc_id

  # Allow HTTPS access (for future SSL setup)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Nexus default UI/API port
  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Data source to get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance to create a Nexus server
resource "aws_instance" "nexus_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.medium"
  subnet_id                   = var.subnet_id
  key_name                    = var.key_name # SSH key
  vpc_security_group_ids      = [aws_security_group.nexus_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  associate_public_ip_address = true
  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    encrypted   = true
  }
  metadata_options {
    http_tokens = "required"
  }
  # user_data = ""
  tags = {
    Name = "${var.name}-nexus"
  }
}

# Create a new load balancer
resource "aws_elb" "elb_nexus" {
  name            = "${var.name}elb-nexus"
  subnets         = var.subnet_ids
  security_groups = [aws_security_group.elb_nexus_sg.id]

  listener {
    instance_port      = 8081
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "http"
    #ssl_certificate_id = var.aws_acm_certificate
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:8081"
    interval            = 30
  }

  instances                   = [aws_instance.nexus_server.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "${var.name}-elb-nexus"
  }
}

# Nexus Security Group
resource "aws_security_group" "elb_nexus_sg" {
  name   = "${var.name}-elb-nexus-sg"
  vpc_id = var.vpc_id

  # Allow HTTPS access 
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ACM certificate
# resource "aws_acm_certificate" "personal-project-acm-cert" {
#   domain_name       = var.domain
#   validation_method = "DNS"

#   tags = {
#     Name = "${var.name}-acm-cert"
#   }
# }

# import route 53 zone id
data "aws_route53_zone" "personal-project-zone" {
  name         = var.domain
  private_zone = false
}

# Route 53 Record
resource "aws_route53_record" "nexus_dns" {
  zone_id = data.aws_route53_zone.personal-project-zone.zone_id
  name    = "nexus.${var.domain}"
  type    = "A"

  alias {
    name                   = aws_elb.elb_nexus.dns_name
    zone_id                = aws_elb.elb_nexus.zone_id
    evaluate_target_health = true
  }
}