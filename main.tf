terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  vpc_cidr = "10.0.0.0/16"
  cloudmap_namespace_name = "app.local"
  unique_suffix = "9d25709fbcea"

  canaries = {
    "v5" = {
      route_weight = 100
    },
//    "v6" = {
//      route_weight = 0
//    }
  }
}

resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_service_discovery_private_dns_namespace" "namespace" {
  name = local.cloudmap_namespace_name
  vpc  = aws_vpc.main.id
}

resource "aws_appmesh_mesh" "mesh" {
  name = "${terraform.workspace}-mesh-${local.unique_suffix}"
}

resource "aws_appmesh_virtual_node" "canary" {
  for_each = local.canaries

  name      = "VirtualNode${each.key}-${local.unique_suffix}"
  mesh_name = aws_appmesh_mesh.mesh.name

  spec {
    service_discovery {
      aws_cloud_map {
        namespace_name = aws_service_discovery_private_dns_namespace.namespace.name
        service_name   = aws_service_discovery_service.canary[each.key].name
      }
    }

    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
    }
  }

}

resource "aws_service_discovery_service" "canary" {
  for_each = local.canaries

  name        = "app-${each.key}-discovery-${local.unique_suffix}"
  description = "Service based on a private DNS namespace"
  dns_config {
    dns_records {
      type = "A"
      ttl  = 60
    }
    routing_policy = "MULTIVALUE"
    namespace_id   = aws_service_discovery_private_dns_namespace.namespace.id
  }
}

resource "aws_appmesh_virtual_router" "router" {
  name      = "VirtualRouter-${local.unique_suffix}"
  mesh_name = aws_appmesh_mesh.mesh.name

  spec {
    listener {
      port_mapping {
        port     = 80
        protocol = "http"
      }
    }
  }
}

resource "aws_appmesh_route" "app_route" {
  name                = "AppMeshRoute-${local.unique_suffix}"
  mesh_name           = aws_appmesh_mesh.mesh.name
  virtual_router_name = aws_appmesh_virtual_router.router.name

  spec {
    http_route {
      action {
        # Use a dynamic block to create weighted_target entries for each canary
        dynamic "weighted_target" {
          for_each = local.canaries

          content {
            virtual_node = aws_appmesh_virtual_node.canary[weighted_target.key].name
            weight       = weighted_target.value.route_weight
          }
        }
      }
      match {
        prefix = "/"
      }
    }
  }

}
