locals {
  application_alb_name          = "${var.application_name}-${var.environment}-alb"
  application_target_group_name = "${var.application_name}-${var.environment}-tg"
  cloudfront_origin_id          = "${var.application_name}-vpc-origin"
}

# CloudFront publishes an AWS-managed prefix list containing only the network
# ranges used by CloudFront origin-facing servers. The ALB therefore remains
# internal and does not accept arbitrary VPC or internet traffic.
data "aws_ec2_managed_prefix_list" "cloudfront_origin_facing" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = "Managed-CachingDisabled"
}

data "aws_cloudfront_origin_request_policy" "all_viewer_except_host" {
  name = "Managed-AllViewerExceptHostHeader"
}

resource "aws_security_group" "application_alb" {
  name        = local.application_alb_name
  description = "CloudFront VPC origin access to the ${var.application_name} internal ALB"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name        = local.application_alb_name
    Application = var.application_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "application_alb_from_cloudfront" {
  security_group_id = aws_security_group.application_alb.id
  description       = "HTTP from CloudFront origin-facing servers"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront_origin_facing.id
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "application_alb_to_nodes" {
  security_group_id            = aws_security_group.application_alb.id
  description                  = "Health checks and application traffic to EKS Pod IPs"
  referenced_security_group_id = module.eks.node_security_group_id
  ip_protocol                  = "tcp"
  from_port                    = 8000
  to_port                      = 8000
}

resource "aws_security_group_rule" "application_nodes_from_alb" {
  description              = "Application traffic from the internal ALB"
  type                     = "ingress"
  security_group_id        = module.eks.node_security_group_id
  source_security_group_id = aws_security_group.application_alb.id
  protocol                 = "tcp"
  from_port                = 8000
  to_port                  = 8000
}

resource "aws_lb" "application" {
  name                       = local.application_alb_name
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.application_alb.id]
  subnets                    = module.vpc.private_subnets
  ip_address_type            = "ipv4"
  enable_http2               = true
  drop_invalid_header_fields = true
  idle_timeout               = var.cloudfront_origin_read_timeout_seconds + 10

  tags = {
    Application = var.application_name
  }

  lifecycle {
    precondition {
      condition     = length(local.application_alb_name) <= 32
      error_message = "The generated ALB name must not exceed 32 characters. Shorten application_name or environment."
    }
  }
}

resource "aws_lb_target_group" "application" {
  name             = local.application_target_group_name
  port             = 8000
  protocol         = "HTTP"
  protocol_version = "HTTP1"
  vpc_id           = module.vpc.vpc_id
  target_type      = "ip"

  deregistration_delay = 30

  health_check {
    enabled             = true
    path                = "/health/ready"
    port                = "traffic-port"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = {
    Application = var.application_name
  }

  lifecycle {
    precondition {
      condition     = length(local.application_target_group_name) <= 32
      error_message = "The generated target group name must not exceed 32 characters. Shorten application_name or environment."
    }
  }
}

resource "aws_lb_listener" "application_http" {
  load_balancer_arn = aws_lb.application.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}

resource "aws_cloudfront_vpc_origin" "application" {
  vpc_origin_endpoint_config {
    name                   = local.cloudfront_origin_id
    arn                    = aws_lb.application.arn
    http_port              = 80
    https_port             = 443
    origin_protocol_policy = "http-only"

    origin_ssl_protocols {
      items    = ["TLSv1.2"]
      quantity = 1
    }
  }

  tags = {
    Application = var.application_name
  }

  # AWS requires the VPC to have an attached Internet Gateway and the ALB to
  # be active with a listener before a VPC Origin can be created. Traffic does
  # not traverse the Internet Gateway; it remains on the VPC Origin path.
  depends_on = [
    module.vpc,
    aws_lb_listener.application_http,
    aws_vpc_security_group_ingress_rule.application_alb_from_cloudfront,
  ]
}

resource "aws_cloudfront_distribution" "application" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "HTTPS entry point for ${var.application_name}"
  http_version    = "http2and3"
  price_class     = var.cloudfront_price_class

  origin {
    domain_name = aws_lb.application.dns_name
    origin_id   = local.cloudfront_origin_id

    vpc_origin_config {
      vpc_origin_id            = aws_cloudfront_vpc_origin.application.id
      origin_keepalive_timeout = 5
      origin_read_timeout      = var.cloudfront_origin_read_timeout_seconds
    }
  }

  default_cache_behavior {
    target_origin_id       = local.cloudfront_origin_id
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    compress               = true

    # The service is an authenticated API. Disable caching to prevent responses
    # from being reused across sessions, and forward every viewer value except
    # Host so the ALB receives the host name it expects.
    cache_policy_id          = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id = data.aws_cloudfront_origin_request_policy.all_viewer_except_host.id
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Application = var.application_name
  }
}
