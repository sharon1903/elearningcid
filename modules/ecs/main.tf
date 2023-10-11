#create security group to allow port 443 and port 80
resource "aws_security_group" "e-learningSG" {
  name        = "e-learningSG"
  description = "Allow TLS inbound traffic https and http"
  vpc_id      = var.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "e-learningSG"
  }
}

#Create aws application loadbalancer
resource "aws_lb" "e-learning-alb" {
  name               = "e-learning-lb-tf"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.e-learningSG.id]
  subnets            = [var.pub-sub1,var.pub-sub2]

  enable_deletion_protection = false

  tags = {
    Name = "e-learning-alb"
}
}

#create target group
resource "aws_alb_target_group" "e-learning-ntg" {
  name        = "e-learning-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    healthy_threshold   = "3"
    interval            = "90"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

#Create Listener (redirectng port 80 to 443 )
resource "aws_alb_listener" "e-learning-http" {
  load_balancer_arn = aws_lb.e-learning-alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.e-learning-ntg.arn
  }




  /* default_action {
    type = "redirect"
 
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
   }
  } */

 }

#Create Listener (forwarding to 443 )
resource "aws_alb_listener" "e-learning-https" {
  load_balancer_arn = aws_lb.e-learning-alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  
  #NOTE..WE TAKE IT FROM ACM MODULE.....LINE 96
  certificate_arn   = var.elearning_certificate_arn
  

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.e-learning-ntg.arn
  }

} 


/* #Create ECR
resource "aws_ecr_repository" "elearning-repo" {
  name                 = "elearning-repo"
  image_tag_mutability = "IMMUTABLE"
}

resource "aws_ecr_lifecycle_policy" "e-learning" {
  repository = aws_ecr_repository.elearning-repo.name
 
  policy = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Keep last 10 images",
            "selection": {
                "tagStatus": "tagged",
                "tagPrefixList": ["v"],
                "countType": "imageCountMoreThan",
                "countNumber": 10
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
 */

resource "aws_ecs_cluster" "e-learning-cluster" {
  name = "e-learning-cluster"
  tags = {
    Name        = "e-learning-cluster"
  
  }
}


#Create ECS task
resource "aws_security_group" "e-learning-ecs-tasks" {
  name        = "ecs-tasks-security-group"

  description = "allow inbound access from the ALB only"
  vpc_id      = var.vpc_id

  /* ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.e-learningSG.id]
  } */
ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups = ["${aws_security_group.e-learningSG.id}"] 
  } 

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
}
}

#create a ecs cluster
resource "aws_iam_role" "ecs_task_role" {
  name = "e-learningTaskRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
}
]
}
EOF
}

#Task role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "e-learning-ecsTaskExecutionRole"
 
  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
}
]
}
EOF
}


resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Creating task definition without json file(create some variables)
resource "aws_ecs_task_definition" "e-learning-td" {
  family                   = "e-learning-service"
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn  
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  container_definitions = jsonencode([
    {

      name      = "e-learning-web"
      cpu       = 10
      memory    = 256
      image     = "sharon1903/e-learning-waso:v2"
      essential = true
      portMappings = [
        {
          protocol      = "tcp"   
          containerPort = 80
          hostPort      = 80
        }
]
}
])
}


#Create cluster service
resource "aws_ecs_service" "e-learning-service" {
  name            = "e-learning-service"
  cluster         = aws_ecs_cluster.e-learning-cluster.id
  task_definition = aws_ecs_task_definition.e-learning-td.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200
  platform_version                   = "1.4.0"
  scheduling_strategy                = "REPLICA"

  network_configuration {
    security_groups  = [aws_security_group.e-learning-ecs-tasks.id]
    subnets          = [var.priv-sub1,var.priv-sub2]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.e-learning-ntg.arn
    container_name   = "e-learning-web"
    container_port   = 80
  }

 lifecycle {
   ignore_changes = [task_definition, desired_count]
}
}

# Create autoscaling group
resource "aws_appautoscaling_target" "e-learning-asg" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.e-learning-cluster.name}/${aws_ecs_service.e-learning-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace= "ecs"
}

#Application auto-scaling policy
resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.e-learning-asg.resource_id
  scalable_dimension = aws_appautoscaling_target.e-learning-asg.scalable_dimension
  service_namespace  = aws_appautoscaling_target.e-learning-asg.service_namespace
 
  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
   }
 
   target_value = 80
}
}