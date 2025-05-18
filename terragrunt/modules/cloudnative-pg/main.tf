data "http" "operator_manifests" {
  url = "https://github.com/cloudnative-pg/cloudnative-pg/releases/download/v${var.operator_version}/cnpg-${var.operator_version}.yaml"
}

locals {
  # Regular expression to find and capture each YAML document.
  # (?m:\A|^---$)? - Non-capturing group: matches a delimiter line or the start of the string.
  # ([\s\S]+?)     - Capturing group: lazily matches the document content (including newlines).
  # (?m:\z|^---$)) - Non-capturing group: matches a delimiter line or the end of the string.
  # This regex finds chunks of content between delimiter lines or string boundaries.
  document_regex = "(?m:\\A|^---$)?([\\s\\S]+?)(?m:\\z|^---$)"

  # [i][0] = the captured group for match i
  all_matches = regexall(local.document_regex, data.http.operator_manifests.response_body)

  manifests = [for match in local.all_matches : yamldecode(match[0])]

  unnamespaced_manifests = [
    for manifest in local.manifests :
    manifest
    if !contains(keys(manifest.metadata), "namespace")
  ]
  namespaced_manifests = [
    for manifest in local.manifests :
    manifest
    if contains(keys(manifest.metadata), "namespace")
  ]
}

resource "kubernetes_manifest" "unnamespaced_manifests" {
  for_each = {
    for manifest in local.unnamespaced_manifests :
    join(",", compact([
      "apiVersion=${manifest.apiVersion}",
      "kind=${manifest.kind}",
      try("namespace=${manifest.metadata.namespace}", ""),
      try("name=${manifest.metadata.name}", ""),
    ]))
    => manifest
  }
  manifest = each.value
}

resource "kubernetes_manifest" "namespaced_manifests" {
  depends_on = [kubernetes_manifest.unnamespaced_manifests]
  for_each = {
    for manifest in local.namespaced_manifests :
    join(",", compact([
      "apiVersion=${manifest.apiVersion}",
      "kind=${manifest.kind}",
      try("namespace=${manifest.metadata.namespace}", ""),
      try("name=${manifest.metadata.name}", ""),
    ]))
    => manifest
  }
  manifest = each.value
}
