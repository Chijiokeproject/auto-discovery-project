locals {
  name = "personal-project"
}
# Create keypair resource
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "${local.name}-key.pem"
  file_permission = "400"
}
resource "aws_key_pair" "public_key" {
  key_name   = "${local.name}-key"
  public_key = tls_private_key.keypair.public_key_openssh
}
# Data source to get the latest RedHat AMI
data "aws_ami" "redhat" {
  most_recent = true
  owners      = ["309956199498"] # RedHat's owner ID
  filter {
    name   = "name"
    values = ["RHEL-9*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
resource "aws_instance" "jenkins_server" {
  ami                         = data.aws_ami.redhat.id # redhat in eu-west-2
  instance_type               = "t3.medium"
  key_name                    = aws_key_pair.public_key.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.ssm_instance_profile.name
  root_block_device {
    volume_size = 20    # Size in GB
    volume_type = "gp3" # General Purpose SSD (recommended)
    encrypted   = true  # Enable encryption (best practice)
  }
  # #user_data = templatefile("./jenkins_userdata.sh", {
  #   nr-key    = "",
  #   nr-acc-id = ""
  #   region    = var.region
  # })
  metadata_options {
    http_tokens = "required"

  }

  tags = {
    Name = "${local.name}-jenkins-server"
  }
}
# Create IAM role for Jenkins
resource "aws_iam_role" "ssm-jenkins-role" {
  name = "${local.name}-ssm-jenkins-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
# Attach the AmazonSSMManagedInstanceCore policy to the role
resource "aws_iam_role_policy_attachment" "jenkins_ssm_managed_instance_core" {
  role       = aws_iam_role.ssm-jenkins-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}
# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "jenkins-admin-role-attachment" {
  role       = aws_iam_role.ssm-jenkins-role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
# Create IAM instance profile for Jenkins
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "${local.name}-ssm-jenkins-profile"
  role = aws_iam_role.ssm-jenkins-role.name
}

# Create jenkins security group
resource "aws_security_group" "jenkins_sg" {
  name        = "${local.name}-jenkins-sg"
  description = "HTTPS"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# # Create ACM certificate with DNS validation
# resource "aws_acm_certificate" "personal-project-acm-cert" {
#   domain_name               = var.domain
#   subject_alternative_names = ["*.${var.domain}"]
#   validation_method         = "DNS"
#   lifecycle {
#     create_before_destroy = true
#   }
#   tags = {
#     Name = "${local.name}-acm-cert"
#   }
# }

# data "aws_route53_zone" "personal-project-zone" {
#   name         = var.domain
#   private_zone = false
# }

# # Fetch DNS Validation Records for ACM Certificate
# resource "aws_route53_record" "acm_validation_record" {
#   for_each = {
#     for dvo in aws_acm_certificate.personal-project-acm-cert.domain_validation_options : dvo.domain_name => {
#       name   = dvo.resource_record_name
#       record = dvo.resource_record_value
#       type   = dvo.resource_record_type
#     }
#   }

#   # Create DNS Validation Record for ACM Certificate
#   zone_id         = data.aws_route53_zone.personal-project-zone.zone_id
#   allow_overwrite = true
#   name            = each.value.name
#   type            = each.value.type
#   ttl             = 60
#   records         = [each.value.record]
#   depends_on      = [aws_acm_certificate.personal-project-acm-cert]
# }

# # Validate the ACM Certificate after DNS Record Creation
# resource "aws_acm_certificate_validation" "personal-project_cert_validation" {
#   certificate_arn         = aws_acm_certificate.personal-project-acm-cert.arn
#   validation_record_fqdns = [for record in aws_route53_record.acm_validation_record : record.fqdn]
#   depends_on              = [aws_acm_certificate.personal-project-acm-cert]
# }

# # Create elastic Load Balancer for Jenkins
# resource "aws_elb" "elb_jenkins" {
#   name               = "elb-jenkins"
#   security_groups    = [aws_security_group.jenkins-elb-sg.id]
#   availability_zones = ["eu-west-2a", "eu-west-2b"]
#   listener {
#     instance_port      = 8080
#     instance_protocol  = "HTTP"
#     lb_port            = 443
#     lb_protocol        = "HTTPS"
#     ssl_certificate_id = aws_acm_certificate.personal-project-acm-cert.id
#   }
#   health_check {
#     healthy_threshold   = 3
#     unhealthy_threshold = 2
#     interval            = 30
#     timeout             = 5
#     target              = "TCP:8080"
#   }
#   instances                   = [aws_instance.jenkins_server.id]
#   cross_zone_load_balancing   = true
#   idle_timeout                = 400
#   connection_draining         = true
#   connection_draining_timeout = 400
#   tags = {
#     Name = "${local.name}-jenkins-server"
#   }
# }
# # Create Security group for the jenkins elb
# resource "aws_security_group" "jenkins-elb-sg" {
#   name        = "${local.name}-jenkins-elb-sg"
#   description = "Allow HTTPS"

#   ingress {
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# # Create Route 53 record for jenkins server
# resource "aws_route53_record" "jenkins-record" {
#   zone_id = data.aws_route53_zone.personal-project-zone.zone_id
#   name    = "jenkins.${var.domain}"
#   type    = "A"
#   alias {
#     name                   = aws_elb.elb_jenkins.dns_name
#     zone_id                = aws_elb.elb_jenkins.zone_id
#     evaluate_target_health = true
#   }
# }

