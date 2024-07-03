# Step Scaling Policy for Scale Out
resource "aws_autoscaling_policy" "jm_asg_scale_out_policy" {
  name                      = "jm-asg-scale-out-policy"
  autoscaling_group_name    = aws_autoscaling_group.jm_asg.name
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "StepScaling"
  estimated_instance_warmup = 300 # 5 minutes

  step_adjustment {
    metric_interval_lower_bound = 0
    scaling_adjustment          = 1
  }
}

# CloudWatch Metric Alarm for Scale Out
resource "aws_cloudwatch_metric_alarm" "jm_asg_scale_out_alarm" {
  alarm_name          = "jm-asg-scale-out-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120" # 2 minutes
  statistic           = "Average"
  threshold           = "80"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.jm_asg.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for scale out"
  alarm_actions     = [aws_autoscaling_policy.jm_asg_scale_out_policy.arn]
}

# Step Scaling Policy for Scale In
resource "aws_autoscaling_policy" "jm_asg_scale_in_policy" {
  name                      = "jm-asg-scale-in-policy"
  autoscaling_group_name    = aws_autoscaling_group.jm_asg.name
  adjustment_type           = "ChangeInCapacity"
  policy_type               = "StepScaling"
  estimated_instance_warmup = 300 # 5 minutes

  step_adjustment {
    metric_interval_upper_bound = 0
    scaling_adjustment          = -1
  }
}

# CloudWatch Metric Alarm for Scale In
resource "aws_cloudwatch_metric_alarm" "jm_asg_scale_in_alarm" {
  alarm_name          = "jm-asg-scale-in-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120" # 2 minutes
  statistic           = "Average"
  threshold           = "20"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.jm_asg.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for scale in"
  alarm_actions     = [aws_autoscaling_policy.jm_asg_scale_in_policy.arn]
}
