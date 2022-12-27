provider "kubernetes" {
	cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
	host                   = var.kubernetes_cluster_endpoint
	token                  = var.kubernetes_cluster_token
}

provider "helm" {
	kubernetes {
		cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
		host                   = var.kubernetes_cluster_endpoint
		token                  = var.kubernetes_cluster_token
	}
}

resource "kubernetes_namespace" "ns-monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "kube-prometheus-sssm" {
  name             = "kube-prometheus-sssm"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = kubernetes_namespace.ns-monitoring.metadata.0.name
  create_namespace = false

  depends_on = [kubernetes_namespace.ns-monitoring]
}