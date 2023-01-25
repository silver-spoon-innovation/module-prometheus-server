provider "aws" {
  region = var.aws_region
  profile = var.aws_profile
}

provider "kubernetes" {
  cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
  host                   = var.kubernetes_cluster_endpoint
  exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name]
      command     = "aws"
    }
}

provider "helm" {
  kubernetes {
    cluster_ca_certificate = base64decode(var.kubernetes_cluster_cert_data)
    host                   = var.kubernetes_cluster_endpoint
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", var.kubernetes_cluster_name]
      command     = "aws"
    }
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
  timeout          = 3600
  depends_on       = [kubernetes_namespace.ns-monitoring]

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
    type  = "string"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
    type  = "string"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.storage_size
    type  = "string"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = var.storage_class_name
    type  = "string"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.accessModes[0]"
    value = "ReadWriteOnce"
    type  = "string"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.storage_size
    type  = "string"
  }
}

resource "helm_release" "prom-mongodb-sssm" {
  name             = "prom-mongodb-sssm"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-mongodb-exporter"
  namespace        = kubernetes_namespace.ns-monitoring.metadata.0.name
  create_namespace = false
  timeout          = 3600
  depends_on       = [kubernetes_namespace.ns-monitoring, helm_release.kube-prometheus-sssm]

  set {
    name  = "mongodb.uri"
    value = var.mongodb_connection_strings
    type  = "string"
  }

  set {
    name  = "serviceMonitor.enabled"
    value = "true"
  }

  # set {
  #   name  = "serviceMonitor.namespace"
  #   value = kubernetes_namespace.ns-monitoring.metadata.0.name
  #   type  = "string"
  # }
}