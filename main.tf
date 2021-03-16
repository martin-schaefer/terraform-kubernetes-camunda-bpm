terraform {
  required_version = ">= 0.13"
  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = ">= 1.13.3"
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
  default = "7.14.0"
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
        }
      }

      spec {
        automount_service_account_token = true
        container {
          name  = var.name
          image = "camunda/camunda-bpm-platform:run-${var.tag}"

          port {
            name           = "http"
            container_port = 8080
          }

          resources {
            requests = {
              cpu = "100m"
              memory = "1000Mi"
            }
            limits = {
              cpu = "2000m"
              memory = "2000Mi"
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
    }
  }

  spec {
    selector = {
      "app.kubernetes.io/name" = var.name
    }
    port {
      name = "http"
      port = 8080
    }
  }
}


