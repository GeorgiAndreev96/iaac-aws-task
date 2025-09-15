# AWS Infrastructure Automation Challenge

This repository contains the **Infrastructure-as-Code (IaC)** setup for a basic web application stack on AWS. And install SSL Checker via setup_sslchecker.sh file

## 🔎 Overview
- **Web Servers:** EC2 instances  
- **Load Balancer:** Application Load Balancer (ALB)  
- **Database:** RDS (MySQL/PostgreSQL)  

---

## 🚀 Deploying with Terraform

This project provisions the infrastructure for the **SSL Checker** application using **Terraform** on AWS.  

It creates:  
- **2 EC2 instances** (`web1` running backend + frontend, `web2` for redundancy / Nginx)  
- **2 RDS MySQL instance**  
- **DB Subnet Group and VPC**  

---

## 📂 Project Structure (Terraform)

```
terraform/
│── main.tf           # Defines EC2, RDS, networking
│── variables.tf      # Input variables (subnet IDs, SGs, DB settings)
│── outputs.tf        # Outputs (public IPs, RDS endpoint)
│── provider.tf       # AWS provider configuration
│── terraform.tfvars  # Your specific values (gitignored)
```


## ⚙️ Prerequisites

- Terraform installed (v1.5+)
- AWS CLI configured with credentials (`aws configure`)
- SSH key pair uploaded in AWS (e.g., `terraform-key`)

  
## 🛠️ Deployment Steps

1. Navigate into the Terraform directory:

    ```bash
    cd terraform
    ```

2. Initialize Terraform:

    ```bash
    terraform init
    ```

3. Preview planned resources:

    ```bash
    terraform plan -out=tfplan
    ```

4. Apply changes to deploy infrastructure:

    ```bash
    terraform apply tfplan
    ```

**This will:**

- Launch 2 EC2 instances with loadbalancer above them
- Install backend/frontend via `setup_sslchecker.sh` on both servers  
- Create 2 RDS MySQL instances
- Connect SSL Checker to DB

## ✅ Check Outputs

```bash
terraform output




