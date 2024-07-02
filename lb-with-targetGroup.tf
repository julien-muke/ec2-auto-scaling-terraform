resource "aws_lb" "jm_lb" {
  name               = "jm-lb-asg"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jm_sg_for_elb.id]
  subnets            = [aws_subnet.jm_subnet_1a.id, aws_subnet.jm_subnet_1b.id]
  depends_on         = [aws_internet_gateway.jm_gw]
}

resource "aws_lb_target_group" "jm_alb_tg" {
  name     = "jm-tf-lb-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.jm_main.id
}

resource "aws_lb_listener" "jm_front_end" {
  load_balancer_arn = aws_lb.jm_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jm_alb_tg.arn
  }
}