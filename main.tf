provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster_auth" "ms-sssm" {
  name = var.kubernetes_cluster_id
}

provider "kubernetes" {
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
  host                   = var.kubernetes_cluster_endpoint
  token                  = data.aws_eks_cluster_auth.ms-sssm.token
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
    host                   = var.kubernetes_cluster_endpoint
    token                  = data.aws_eks_cluster_auth.ms-sssm.token
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