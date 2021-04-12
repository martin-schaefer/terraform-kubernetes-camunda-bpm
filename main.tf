terraform {
  required_version = ">= 0.14.8"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 2.0.3"
    }
  }
}

variable "name" {
  type = string
  default = "camunda-bpm-platform"
}

variable "namespace" {
  type = string
  default = "camunda"
}

variable "tag" {
  type = string
  default = "7.15.0"
}

variable "replicas" {
  type = number
  default = 1
}

resource "kubernetes_deployment" "deployment" {
  metadata {
    name      = var.name
    namespace = var.namespace

    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/version" = var.tag
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = {
        "app.kubernetes.io/name" = var.name
      }
    }

    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = var.name
          "app.kubernetes.io/version" = var.tag
          "app.kubernetes.io/managed-by" = "terraform"
        }
      }

      spec {
        automount_service_account_token = true
        container {
          name  = var.name
          image = "camunda/camunda-bpm-platform:run-${var.tag}"
          env {
            name = "JAVA_TOOL_OPTIONS"
            value = "-XX:MaxRAMPercentage=70.0 -XX:+PrintFlagsFinal -Dspring.application.name=${var.name}"
          }
          port {
            name           = "http-service"
            container_port = 8080
          }
          resources {
            requests = {
              cpu    = "0.1"
              memory = "1Gi"
            }
            limits = {
              cpu    = "4"
              memory = "2Gi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = var.name
    namespace = var.namespace
    labels = {
      "app.kubernetes.io/name" = var.name
      "app.kubernetes.io/version" = var.tag
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      "app.kubernetes.io/name" = var.name
    }
    port {
      name = "http-service"
      port = 8080
    }
  }
}
