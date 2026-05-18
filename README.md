# ☁️ Ziggy — AWS 3-Tier Web Architecture

A fully working **3-tier web application** deployed on AWS, demonstrating industry-standard separation of concerns across Presentation, Application, and Database layers — with Terraform for infrastructure provisioning and Auto Scaling Groups for high availability.

---

## 🏗️ Architecture

```
Internet
   │
   ▼
[External ALB]  ← internet-facing, public subnets
   │
   ▼
[Nginx EC2 - Web Tier]  ← serves HTML frontend, proxies /api/* calls
   │  (public subnets, ASG: min 1 / max 3)
   ▼
[Internal ALB]  ← private, routes to app tier only
   │
   ▼
[Node.js EC2 - App Tier]  ← Express REST API, business logic
   │  (private subnets, ASG: min 1 / max 3)
   ▼
[RDS MySQL - DB Tier]  ← Multi-AZ, private subnets, no public access
```

**Traffic flow:**
1. User hits the External ALB DNS
2. ALB routes to Nginx (Web Tier EC2) in public subnets
3. Nginx serves the frontend and proxies `/api/*` to the Internal ALB
4. Internal ALB routes to Node.js (App Tier EC2) in private subnets
5. Node.js queries RDS MySQL in the isolated DB subnets

---

## 📂 Repository Structure

```
ziggy-aws-3tier-architecture/
├── app/
│   ├── backend/
│   │   ├── server.js        # Node.js Express API (App Tier)
│   │   ├── package.json
│   │   └── schema.sql       # RDS database schema + seed data
│   └── frontend/
│       └── index.html       # Frontend — fetches menu, places orders via /api
├── nginx/
│   └── nginx.conf           # Real Nginx config — serves frontend + proxies API
├── scripts/
│   ├── web-tier-setup.sh    # EC2 user-data: installs Nginx, deploys frontend
│   └── app-tier-setup.sh    # EC2 user-data: installs Node.js, starts with PM2
├── terraform/
│   ├── main.tf              # Root module — wires VPC, EC2, RDS, ALB together
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── modules/
│       ├── vpc/             # VPC, subnets, IGW, NAT, route tables
│       ├── security_groups/ # Layered SGs per tier
│       ├── alb/             # External + internal Application Load Balancers
│       ├── ec2/             # Launch Template + Auto Scaling Group (reusable)
│       └── rds/             # RDS MySQL Multi-AZ
└── screenshots/             # AWS Console screenshots per service
```

---

## ☁️ AWS Services Used

| Service | Role |
|---|---|
| **VPC** | Network isolation — 3 subnet tiers across 2 AZs |
| **EC2** | Web tier (Nginx) and App tier (Node.js) |
| **Auto Scaling Groups** | Maintain availability, scale on CPU load |
| **Application Load Balancer** | External (public) + Internal (private) |
| **RDS MySQL** | Multi-AZ managed database in private subnets |
| **S3** | Static asset storage |
| **Security Groups** | Layered access control — each tier talks only to adjacent tier |
| **NAT Gateway** | Outbound internet for private EC2 instances |

---

## 🔐 Security Design

- **RDS** — not publicly accessible; accepts connections only from the App Tier SG on port 3306
- **App Tier EC2** — no public IP; accepts traffic only from Internal ALB SG on port 3000
- **Web Tier EC2** — accepts HTTP only from External ALB SG on port 80
- **Least-privilege SGs** — no tier can talk directly to a non-adjacent tier
- **DB credentials** — passed via EC2 user-data environment variables; never hardcoded

---

## 🚀 Deploy with Terraform

```bash
cd terraform/

# 1. Copy and fill in your values
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your key_name and db_password

# 2. Initialise providers and modules
terraform init

# 3. Preview what will be created
terraform plan

# 4. Deploy (~5–8 minutes)
terraform apply

# 5. Get your app URL
terraform output external_alb_dns
```

> **Destroy when done** (avoids AWS charges):
> ```bash
> terraform destroy
> ```

---

## ⚙️ Manual Deployment Steps

If deploying manually via AWS Console:

1. **VPC** — Create VPC (`10.0.0.0/16`), 6 subnets (2 public, 2 private-app, 2 private-db), IGW, NAT GW, route tables
2. **Security Groups** — Create SGs per tier following least-privilege rules above
3. **RDS** — Launch MySQL 8.0, Multi-AZ, in `private-db` subnets, attach DB SG. Run `schema.sql`
4. **Internal ALB** — Create internal ALB in `private-app` subnets. Target group: port 3000, `/health` check
5. **App Tier** — Launch EC2 (Ubuntu 22.04) in `private-app` subnets. Run `scripts/app-tier-setup.sh` as user-data
6. **External ALB** — Create internet-facing ALB in public subnets. Target group: port 80, `/health` check
7. **Web Tier** — Launch EC2 (Ubuntu 22.04) in public subnets. Run `scripts/web-tier-setup.sh` as user-data (pass internal ALB DNS)
8. **Test** — Hit external ALB DNS in browser. Menu loads from Node.js → RDS

---

## 📸 Screenshots

| Component | Screenshot |
|---|---|
| VPC & Subnets | `screenshots/VPC/` |
| EC2 Instances & ALB | `screenshots/Ec2 & alb/` |
| RDS Connection | `screenshots/RDS-database/` |
| Website Live | `screenshots/App-live/` |
| Architecture Diagram | `screenshots/architecture/` |

---

## 📈 Future Enhancements

- [ ] HTTPS via ACM + Route 53 custom domain
- [ ] CloudWatch alarms + SNS notifications
- [ ] AWS Secrets Manager for DB credentials (replace env vars)
- [ ] CI/CD pipeline with GitHub Actions
- [ ] WAF in front of External ALB

---

## 👨‍💻 Author

**Prateek Kulkarni**
