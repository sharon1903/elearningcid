output "e-learning-sg-id" {
    value = aws_security_group.e-learningSG.id
  }


output "alb-hostname" {
    value = aws_lb.e-learning-alb.dns_name
  
}

output "alb-zone_id" {
    value = aws_lb.e-learning-alb.zone_id
  
}


output "e-learning-alb-id" {
    value = aws_lb.e-learning-alb.id
  
}

output "e-learning-alb-name" {
    value = aws_lb.e-learning-alb.name
  
}