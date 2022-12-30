output "monitoring_namespace" {
	value = kubernetes_namespace.ns-monitoring.metadata.0.name
}