locals {
  name   = "vpc-ingress-routing"
  region = var.region
  
  # Forcing single AZ for simplicity as per original diagram
  azs    = [var.region != "" ? "${var.region}a" : "us-east-1a"]
}
