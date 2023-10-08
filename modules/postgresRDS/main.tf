resource "aws_db_subnet_group" "elearning_db_sub_grp" {
  name       = "elearning"
  subnet_ids = [var.priv-sub1-id,var.priv-sub2-id]

  tags = {
    Name = "elearning"
  }
}
resource "aws_db_instance" "elearning" {
  identifier             = "elearning"
  instance_class         = "db.t3.micro"
  allocated_storage      = 5
  engine                 = "postgres"
  engine_version         = "15"
  username               = var.db_user
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.elearning_db_sub_grp.name
  vpc_security_group_ids = [var.e-learning-sg-id]
  skip_final_snapshot = true
  deletion_protection=false
}
