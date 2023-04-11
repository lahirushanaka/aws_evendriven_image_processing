locals {
    vpc_name = "k8s-vpc"
    aws_region = "us-east-1"
    az_codes = ["a","b","c"]
    environment = "dev"
    network_cidr = "10.10.0.0/16"
    private_subnet_cidrs = ["10.10.1.0/24", "10.10.2.0/24","10.10.3.0/24"]
    public_subnet_cidrs = ["10.10.4.0/24", "10.10.5.0/24", "10.10.6.0/24"]
    kms_arn = "arn:aws:kms:us-east-1:077044312487:key/6e036c21-63c0-44de-859b-14e965607987"
    cluster_name = "eks-app"
    cluster_version= "1.23"
    alb_image_version = "v2.4.5"
}