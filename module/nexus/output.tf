output "nexus_instance_id" {
  value = aws_instance.nexus_server.id
}

output "nexus_public_ip" {
  value = aws_instance.nexus_server.public_ip
}

output "alb_dns_name" {
  value = aws_elb.elb_nexus.dns_name
}

output "route53_record" {
  value = aws_route53_record.nexus_dns.fqdn
}