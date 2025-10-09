Terraform module to create a Jenkins server (t3.micro)

How to use:

1. Install Terraform and configure AWS credentials (e.g., via environment variables or profile).
2. cd auto-discovery-project/jenkins
3. terraform init
4. terraform apply -var='key_name=your-key' -auto-approve

Notes:
- The instance uses Ubuntu 20.04 and installs Jenkins via apt in user_data.
- The default AMI search uses Canonical owner for Ubuntu. Adjust `data.aws_ami` filters if needed.
- This example does not create security groups or an elastic IP; for public access, consider adding a security group allowing port 8080.
