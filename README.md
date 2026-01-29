# AWS VPC Ingress Routing with Terraform

This Terraform project deploys an AWS architecture demonstrating **VPC Ingress Routing**. It routes inbound traffic destined for a public application server through a centralized inspection appliance (EC2 instance) before it reaches the destination. This pattern is often used for intrusion detection/prevention systems (IDS/IPS) or traffic analysis.

## Architecture

1.  **VPC**: A standard VPC with:
    *   **Public Subnet (Application)**: Hosts the web server.
    *   **Private Subnet (Inspection)**: Hosts the inspection appliance.
2.  **Edge Route Table**: A custom route table associated with the Internet Gateway (IGW) ensures that traffic destined for the **Public Subnet** is first routed to the **Inspection Instance's ENI**.
3.  **Inspection Instance**: An Amazon Linux 2023 EC2 instance configured to forward IP packets. It acts as a gateway/router for the application traffic.
4.  **Application Instance**: An Amazon Linux 2023 EC2 instance running Apache HTTPD to serve a simple web page.

## Prerequisites

*   [Terraform](https://www.terraform.io/) (v1.0+)
*   [AWS CLI](https://aws.amazon.com/cli/) configured with appropriate credentials.

## Usage

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/FonNkwenti/tf-vpc-ingress-routing.git
    cd tf-vpc-ingress-routing
    ```

2.  **Initialize Terraform:**
    ```bash
    terraform init
    ```

3.  **Configure Variables:**
    Create a `terraform.tfvars` file to override the default values. For example:

    ```hcl
    region                 = "us-east-1"
    vpc_cidr               = "10.0.0.0/16"
    inspection_subnet_cidr = "10.0.50.0/24"
    public_subnet_cidr     = "10.0.100.0/24"
    ssh_key_name           = "CHANGE_ME" # Replace with your actual key name
    instance_type          = "t3.micro"
    allowed_mgmt_cidr      = "0.0.0.0/0"
    ```

4.  **Plan and Apply:**
    ```bash
    terraform plan
    terraform apply
    ```

5.  **Verify:**
    After applying, Terraform will output the `application_public_ip`. Access this IP in your browser or via `curl`.
    ```bash
    curl http://<application_public_ip>
    ```
    If successful, you will see: `<h1>Application Server Reached!</h1>...`

## Project Structure

*   `main.tf`: Core infrastructure resources (VPC, Route Tables, Instances, Security Groups).
*   `variables.tf`: Input variable definitions.
*   `outputs.tf`: Output value definitions.
*   `providers.tf`: AWS provider configuration.
*   `scripts/`:
    *   `inspection_userdata.sh`: Startup script for the inspection instance (enables IP forwarding).
    *   `app_userdata.sh`: Startup script for the application server (installs Apache).

## Inputs

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `region` | AWS Region | `string` | `us-east-1` |
| `vpc_cidr` | CIDR block for the VPC | `string` | `10.0.0.0/16` |
| `inspection_subnet_cidr` | CIDR for inspection subnet | `string` | `10.0.50.0/24` |
| `public_subnet_cidr` | CIDR for public subnet | `string` | `10.0.100.0/24` |
| `ssh_key_name` | SSH key name for instances | `string` | `CHANGE_ME` |
| `instance_type` | EC2 instance type | `string` | `t3.micro` |
| `allowed_mgmt_cidr` | CIDR allowed for SSH access | `string` | `0.0.0.0/0` |

## Outputs

| Name | Description |
|------|-------------|
| `vpc_id` | The ID of the VPC |
| `application_public_ip` | Public IP of the application server |
| `application_private_ip` | Private IP of the application server |
| `inspection_public_ip` | Public IP of the inspection appliance |
| `inspection_instance_id` | Instance ID of the inspection appliance |
| `application_instance_id` | Instance ID of the application server |
| `inspection_eni_id` | ENI ID of the inspection appliance (target for ingress routing) |
