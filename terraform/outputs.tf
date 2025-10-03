output "cluster_name" {
  value = module.eks.cluster_id
}

output "kubeconfig" {
  value     = module.eks.kubeconfig_raw
  sensitive = true
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}
