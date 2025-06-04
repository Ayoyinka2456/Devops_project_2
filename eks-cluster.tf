provider "aws" {
  region = "us-east-2"
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_name    = "springboot-cluster"
  cluster_version = "1.27"
  subnets         = module.vpc.private_subnets
  vpc_id          = module.vpc.vpc_id

  node_groups = {
    default = {
      desired_capacity = 2
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3.medium"
    }
  }

  manage_aws_auth = true

  aws_auth_roles = [
    {
      rolearn  = aws_iam_role.eks_cluster_role.arn
      username = "system:node:{{EC2PrivateDNSName}}"
      groups   = ["system:bootstrappers", "system:nodes"]
    }
  ]

  tags = {
    environment = "dev"
  }
}
