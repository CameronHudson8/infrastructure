resource "kubernetes_namespace" "kafka" {
  metadata {
    name = "kafka"
  }
}

resource "kubernetes_service" "kafka" {
  metadata {
    name      = "kafka"
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }
  spec {
    cluster_ip = "None"
    port {
      name = "broker"
      port = 9092
    }
    port {
      name = "controller"
      port = 9094
    }
    selector = {
      app = "kafka"
    }
  }
}

locals {
  kafka = {
    broker_port     = some([for port in kubernetes_service.kafka.spec[0].port : port.port if port.name == "broker"])
    container_name  = "kafka"
    controller_port = some([for port in kubernetes_service.kafka.spec[0].port : port.port if port.name == "controller"])
    pod_replicas    = 3
  }
}

resource "kubernetes_stateful_set" "kafka" {
  metadata {
    name      = local.kafka.container_name
    namespace = kubernetes_namespace.kafka.metadata[0].name
  }
  spec {
    pod_management_policy = "Parallel"
    replicas              = local.kafka.pod_replicas
    selector {
      match_labels = kubernetes_service.kafka.spec[0].selector
    }
    service_name = kubernetes_service.metadata[0].name
    volume_claim_template {
      metadata {
        name = "${local.kafka.container_name}-$POD_ID"
      }
      spec {
        access_modes = "ReadWriteOnce"
        resources {
        }
        # selector {

        # }
        # volume_mode = 
        # volume_name = 
        storage_class_name = var.storage_class_name
      }
    }
    template {
      metadata {
        labels = kubernetes_service.kafka.spec[0].selector
      }
      spec {
        container {
          env {
            name = "KAFKA_ADVERTISED_LISTENERS"
            value = join(
              ",",
              # The default does not include the controller; Instead, the controller is the sole transport in the KAFKA_LISTENERS.
              [
                "BROKER://${local.kafka.container_name}-$POD_ID.${kubernetes_service.kafka.metadata[0].name}.${kubernetes_namespace.kafka.metadata[0].name}.svc.cluster.local:${local.kafka.broker_port}",
                "CONTROLLER://${local.kafka.container_name}-$POD_ID.${kubernetes_service.kafka.metadata[0].name}.${kubernetes_namespace.kafka.metadata[0].name}.svc.cluster.local:${local.kafka.controller_port}",
              ]
            )
          }
          env {
            name  = "KAFKA_CONTROLLER_LISTENER_NAMES"
            value = "CONTROLLER"
          }
          env {
            name = "KAFKA_CONTROLLER_QUORUM_VOTERS"
            value = join(
              ",",
              [
                # default = 1@localhost:9093
                for pod_id in range(local.kafka.pod_replicas)
                : "${pod_id}@${local.kafka.container_name}-${pod_id}.${kubernetes_service.kafka.metadata[0].name}.${kubernetes_namespace.kafka.metadata[0].name}.svc.cluster.local:${local.kafka.controller_port}"
              ]
            )
          }
          env {
            name  = "KAFKA_GROUP_INITIAL_REBALANCE_DELAY_MS"
            value = "0"
          }
          env {
            name = "KAFKA_LISTENERS"
            value = join(
              ",",
              [
                "BROKER://:${local.kafka.broker_port}",
                "CONTROLLER://:${local.kafka.controller_port}",
              ]
            )
          }
          env {
            name  = "KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
            value = "CONTROLLER:PLAINTEXT,BROKER:PLAINTEXT"
          }
          env {
            name  = "KAFKA_NODE_ID"
            value = "$POD_ID"
          }
          #   env {
          #     name  = "KAFKA_NUM_PARTITIONS"
          #     value = "3"
          #   
          env {
            name  = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"
            value = "3"
          }
          env {
            name  = "KAFKA_PROCESS_ROLES"
            value = "broker,controller"
          }
          env {
            name  = "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR"
            value = "1"
          }
          env {
            name  = "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR"
            value = "3"
          }
          image = "apache/kafka:${var.kafka_version}"
          name  = "kafka"
          liveness_probe {
            exec {
              command = [
                "/opt/kafka/bin/kafka-topics.sh",
                "--list",
                "--bootstrap-server=localhost:9092",
              ]
            }
          }
          readiness_probe {
            exec {
              command = [
                "/opt/kafka/bin/kafka-topics.sh",
                "--list",
                "--bootstrap-server=localhost:9092",
              ]
            }
          }
          # security_context 
          # }
          # startup_probe {
          # }
        }
      }
    }
  }
}
