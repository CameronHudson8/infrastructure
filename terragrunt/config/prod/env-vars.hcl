locals {
  ingress_nginx_helm_chart_version = "4.12.0"
  ingress_nginx_service_type       = "LoadBalancer"
  kafka_storage_class_name         = "gp3"
  kafka_version                    = "3.9.0"
  kube_prometheus_version          = "v0.14.0"
  kubernetes_version               = "1.30"
  vpa_operator_version             = "1.2.0"
}
