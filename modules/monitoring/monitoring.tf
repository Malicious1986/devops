resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  namespace        = var.namespace
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.chart_version
  create_namespace = true
  cleanup_on_fail  = true
  force_update     = false

  values = [
    file("${path.module}/values.yaml"),
    jsonencode({
      grafana = {
        adminPassword = var.grafana_admin_password
      }
    })
  ]

  timeout = 900
}
