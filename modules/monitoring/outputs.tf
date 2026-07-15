output "grafana_service_name" {
  description = "Kubernetes service name for Grafana"
  value       = "kube-prometheus-stack-grafana"
}

output "prometheus_service_name" {
  description = "Kubernetes service name for Prometheus"
  value       = "prometheus-operated"
}

output "namespace" {
  description = "Namespace where the monitoring stack is deployed"
  value       = helm_release.kube_prometheus_stack.namespace
}
