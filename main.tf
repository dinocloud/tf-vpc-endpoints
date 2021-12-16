locals {
  endpoints = merge(
    lookup(var.vpc_endpoints, "s3", false) != false ? {
      "S3" = {
        service_name        = "com.amazonaws.${var.region}.s3"
        vpce_type           = "Gateway"
        private_dns_enabled = false
      }
    } : {},
    lookup(var.vpc_endpoints, "ecr", false) != false ? {
      "ECR_API" = {
        service_name = "com.amazonaws.${var.region}.ecr.api"
        vpce_type    = "Interface"
      }
      "ECR_DKR" = {
        service_name = "com.amazonaws.${var.region}.ecr.dkr"
        vpce_type    = "Interface"
      }
    } : {},
    lookup(var.vpc_endpoints, "ssm", false) != false ? {
      "SSM" = {
        service_name = "com.amazonaws.${var.region}.ssm"
        vpce_type    = "Interface"
      }
      "SSMMessages" = {
        service_name = "com.amazonaws.${var.region}.ssmmessages"
        vpce_type    = "Interface"
      }
    } : {},
    lookup(var.vpc_endpoints, "ecs", false) != false ? {
      "ECS" = {
        service_name = "com.amazonaws.${var.region}.ecs"
        vpce_type    = "Interface"
      }
      "ECS-Agent" = {
        service_name = "com.amazonaws.${var.region}.ecs-agent"
        vpce_type    = "Interface"
      }
      "ECS-Telemetry" = {
        service_name = "com.amazonaws.${var.region}.ecs-telemetry"
        vpce_type    = "Interface"
      }
    } : {},
    lookup(var.vpc_endpoints, "secretsmanager", false) != false ? {
      "SecretsManager" = {
        service_name = "com.amazonaws.${var.region}.secretsmanager"
        vpce_type    = "Interface"
      }
    } : {},
    lookup(var.vpc_endpoints, "kms", false) != false ? {
      "KMS" = {
        service_name = "com.amazonaws.${var.region}.kms"
        vpce_type    = "Interface"
      }
    } : {},
    lookup(var.vpc_endpoints, "ec2", false) != false ? {
      "EC2" = {
        service_name = "com.amazonaws.${var.region}.ec2"
        vpce_type    = "Interface"
      }
      "EC2Messages" = {
        service_name = "com.amazonaws.${var.region}.ec2messages"
        vpce_type    = "Interface"
      }
    } : {},
  )

  associations = setproduct(
    [for k, v in local.endpoints : aws_vpc_endpoint.vpc_endpoint[k].id if v.vpce_type == "Gateway"],
  var.route_table_ids)
}

resource "aws_security_group" "vpce_sg" {
  name        = "${var.environment}-vpces-sg"
  description = "${var.environment}-vpces-sg"
  vpc_id      = var.vpc_id
  tags        = var.tags

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = var.ingress_cidrs
  }
}

resource "aws_vpc_endpoint" "vpc_endpoint" {
  for_each            = local.endpoints
  vpc_id              = var.vpc_id
  service_name        = each.value.service_name
  vpc_endpoint_type   = each.value.vpce_type
  private_dns_enabled = lookup(each.value, "private_dns_enabled", true)
  tags                = var.tags

  subnet_ids         = each.value.vpce_type == "Interface" ? var.subnet_ids : null
  security_group_ids = each.value.vpce_type == "Interface" ? concat([aws_security_group.vpce_sg.id], var.extra_sgs) : null
}

resource "aws_vpc_endpoint_route_table_association" "vpce_rt_assoc" {
  count           = length(local.associations)
  route_table_id  = element(local.associations[count.index], 1)
  vpc_endpoint_id = element(local.associations[count.index], 0)
}