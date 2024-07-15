dependencies {
  paths = [
    "../prometheus-operator",
  ]
}

include "backend" {
  path = find_in_parent_folders("backend.hcl")
}

locals {
  env_vars    = read_terragrunt_config(find_in_parent_folders("env-vars.hcl")).locals
  global_vars = read_terragrunt_config(find_in_parent_folders("global-vars.hcl")).locals
}

generate "providers" {
  path      = "terragrunt-generated-providers.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    terraform {
      required_providers {
        kubernetes = {
          source  = "hashicorp/kubernetes"
          version = "~> 2.0"
        }
      }
      required_version = "~> 1.0"
    }

    provider "kubernetes" {
      config_path    = "~/.kube/config"
      config_context = ${jsonencode(local.env_vars.kube_context)}
    }
  EOF
}

generate "module" {
  path      = "terragrunt-generated-module.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    module "prometheus" {
      alertmanager_replicas                = ${jsonencode(local.env_vars.alertmanager_replicas)}
      kube_prometheus_alerts_to_disable    = ${jsonencode(local.env_vars.kube_prometheus_alerts_to_disable)}
      kube_prometheus_version              = ${jsonencode(local.global_vars.kube_prometheus_version)}
      kube_state_metrics_version           = ${jsonencode(local.global_vars.kube_state_metrics_version)}
      monitoring_emails_from               = ${jsonencode(local.global_vars.monitoring_emails_from)}
      monitoring_emails_from_auth_password = ${jsonencode(local.global_vars.monitoring_emails_from_auth_password)}
      monitoring_emails_to_address         = ${jsonencode(local.global_vars.monitoring_emails_to_address)}
      prometheus_replicas                  = ${jsonencode(local.env_vars.prometheus_replicas)}
      source                               = "../../../modules/monitoring"
    }
  EOF
}