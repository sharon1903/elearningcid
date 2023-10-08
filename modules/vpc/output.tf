output "vpc_id" {
    value = aws_vpc.e-learning.id
}

output "vpc-cidr-block" {
    value = aws_vpc.e-learning.cidr_block
  
}

output "eaz1" {
    value =  data.aws_availability_zones.eaz.names[0]
}

output "eaz2" {
    value =  data.aws_availability_zones.eaz.names[1]
    
}

output "pub-sub1"{
    
    value = aws_subnet.e-learningpub1.id
}

output "pub-sub2" {
    value = aws_subnet.e-learningpub2.id
}

output "priv-sub1" {
    value = aws_subnet.e-learningpriv1.id
  
}
output "priv-sub2" {
    value = aws_subnet.e-learningpriv2.id
  
}

output "Internet_gateway" {
    value = aws_internet_gateway.e-learningIGW.id
}