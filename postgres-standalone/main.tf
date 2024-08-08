provider "kubernetes" {
  config_path = "~/.kube/config"  # Adjust if needed for your environment
}

# Namespace for PostgreSQL
resource "kubernetes_namespace" "postgres_ns" {
  metadata {
    name = "postgres"
  }
}

# Persistent Volume for PostgreSQL (Cluster-scoped, no namespace)
resource "kubernetes_persistent_volume" "postgres_pv" {
  metadata {
    name = "postgres-pv"
  }

  spec {
    capacity = {
      storage = "5Gi"
    }

    access_modes = ["ReadWriteOnce"]

    persistent_volume_source {
      host_path {
        path = "/mnt/data/postgres"
      }
    }
  }
}

# Persistent Volume Claim for PostgreSQL (Namespace-scoped)
resource "kubernetes_persistent_volume_claim" "postgres_pvc" {
  metadata {
    name      = "postgres-pvc"
    namespace = kubernetes_namespace.postgres_ns.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "5Gi"
      }
    }
  }
}

# PostgreSQL Deployment
resource "kubernetes_deployment" "postgres_deployment" {
  metadata {
    name      = "postgres-deployment"
    namespace = kubernetes_namespace.postgres_ns.metadata[0].name
    labels = {
      app = "postgres"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "postgres"
      }
    }

    template {
      metadata {
        labels = {
          app = "postgres"
        }
      }

      spec {
        container {
          name  = "postgres"
          image = "postgres:latest"

          env {
            name  = "POSTGRES_USER"
            value = "postgres"
          }

          env {
            name  = "POSTGRES_PASSWORD"
            value = "password"
          }

          port {
            container_port = 5432
          }

          volume_mount {
            name       = "postgres-storage"
            mount_path = "/var/lib/postgresql/data"
          }
        }

        volume {
          name = "postgres-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.postgres_pvc.metadata[0].name
          }
        }
      }
    }
  }
}

# PostgreSQL Service with NodePort
resource "kubernetes_service" "postgres_service" {
  metadata {
    name      = "postgres-service"
    namespace = kubernetes_namespace.postgres_ns.metadata[0].name
  }

  spec {
    selector = {
      app = "postgres"
    }

    type = "NodePort"

    port {
      port        = 5432
      target_port = 5432
      node_port   = 32000  # Port range 30000-32767 for NodePort
    }
  }
}

output "postgres_connection_info" {
  value = "PostgreSQL is accessible at $(kubectl get nodes -o jsonpath='{.items[0].status.addresses[0].address}'):32000"
}
