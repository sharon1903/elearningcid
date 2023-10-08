output "domain_name" {    
    value = var.domain_name
}

output "elearning_cert_arn" { 
    value = aws_acm_certificate.elearning_acm_cert.arn
}