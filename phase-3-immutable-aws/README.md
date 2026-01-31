# Phase 3: Immutable Infrastructure on AWS (Terraform)
## From Incident Response to Immutable Infrastructure

---

## Executive Summary

Following a real-world persistent malware incident across 22 domains,
this phase demonstrates a shift from reactive cleanup to immutable infrastructure.
Instead of cleaning compromised servers, they are replaced using Infrastructure as Code.


**Key Innovation:** Compromised instances are never cleaned — they are replaced.

---

## Background: From Incident to Architecture

In **Phase 1–2**, I handled a sophisticated botnet infection that leveraged:
- **Kernel-level persistence** (Linux immutable attributes)
- **Self-healing watchdog scripts**
- **Cross-domain lateral movement**

**Critical Lesson Learned:**
> Once persistence is established at the filesystem level, trust in the host is permanently lost.

Traditional "clean and patch" approaches create race conditions with advanced persistence mechanisms. **Phase 3** demonstrates the architectural correction: **Immutable Infrastructure**.

---

## Architecture Overview

### Design Philosophy
- **Goal:** Immutability by design, not high availability
- **Principle:** Zero-trust at the infrastructure layer
- **Method:** Complete instance replacement on any change

### Infrastructure Components

| Component | Configuration | Purpose |
|-----------|---------------|----------|
| **AWS VPC** | New, isolated network | Clean security boundary |
| **Public Subnet** | Single AZ | Minimal attack surface |
| **Security Group** | HTTP (80) + SSH (22) | Controlled access |
| **Launch Template** | Ubuntu 22.04 + Nginx | Immutable server definition |
| **Auto Scaling Group** | desired=1, min=1, max=1 | Automated replacement |

### Traffic Flow
```
Client → Internet → EC2 (ASG) → Nginx
```

**Intentionally Simple:** No ALB, no EIP, no configuration management tools.

### Future Architecture Vision
```mermaid
graph LR
  subgraph VPC AWS VPC 10.0.0.0/16
    direction LR
    IGW[Internet Gateway]
    subgraph PublicSubnet
      EC2[Nginx Instance (ASG)]
    end
  end

  User((User)) --> IGW
  IGW --> EC2
  classDef aws fill:#FF9900,stroke:#232F3E,color:white;
  class IGW,EC2 aws;
```

*This production-ready architecture will be implemented in Phase 4, building upon the immutable principles demonstrated here.*

---

## Why Immutable Infrastructure?

### Problems with Traditional Approaches
- ❌ **Filesystem state cannot be trusted** after compromise
- ❌ **Manual cleanup creates race conditions** with persistence mechanisms  
- ❌ **Long-lived servers ("pets") become liabilities**

### Immutable Solution
- ✅ **No SSH-based configuration changes**
- ✅ **No in-place cleanup attempts**
- ✅ **All configuration defined in code**
- ✅ **Any change results in complete instance replacement**

**Result:** Eliminates persistence by design.

---

## Technical Demonstration

### Step 1: Initial Deployment
Deploy infrastructure with `app_version = "1"`

Instance boots and renders:
```
VERSION=1
hostname=ip-10-30-1-123
boot_time=2025-01-15 10:30:00
```

### Step 2: Version Change
Update `app_version = "2"` and apply Terraform

Auto Scaling Group **replaces** the instance (not modifies)

### Step 3: Verification
New instance comes up with:
```
VERSION=2
hostname=ip-10-30-1-156  # ← Different hostname
boot_time=2025-01-15 10:35:00  # ← New boot time
```

**Proof:** The hostname and boot time change, confirming the original instance was **terminated and replaced** — not modified.

---

## Technology Stack

| Category | Tools |
|----------|-------|
| **Infrastructure as Code** | Terraform, AWS Provider |
| **Compute** | EC2, Auto Scaling Groups, Launch Templates |
| **Networking** | VPC, Security Groups |
| **Web Server** | Nginx (installed via user_data) |
| **Operating System** | Ubuntu 22.04 LTS |

---

## Intentional Design Trade-offs

This phase **intentionally excludes**:
- ❌ Application Load Balancer
- ❌ Elastic IP addresses
- ❌ High Availability / Multi-AZ deployment
- ❌ Configuration management tools (Ansible, Chef)

**Rationale:** The objective is to demonstrate **immutability**, not resilience or scale. Availability and scaling are addressed in subsequent phases (EKS).

---

## Results & Impact

### Key Achievements
- ✅ **Eliminated server-level trust requirements**
- ✅ **Proved replacement is safer than cleanup**
- ✅ **Established auditable infrastructure source of truth**
- ✅ **Demonstrated minimal architecture effectiveness**

### Business Value
- **Reduced incident response time** from hours to minutes
- **Eliminated manual cleanup procedures** and associated risks
- **Created repeatable, testable infrastructure patterns**
- **Established foundation for cloud-native security**

---

## 🚀 Next Phase: EKS Production Simulation

**Phase 4** will scale these immutable principles to Kubernetes:
- **Rolling updates** at the pod level
- **NetworkPolicy** for zero-trust networking
- **Failure containment** at cluster scale
- **Production-grade** high availability

The same immutable principle demonstrated here will be applied at the **Kubernetes orchestration layer**.

---

## 🛠️ Quick Start

```bash
# Clone and deploy
git clone <repository>
cd phase-3-immutable-aws

# Configure variables
cp terraform.tfvars.example terraform.tfvars
# Edit: region, my_ip_cidr, app_version

# Deploy
terraform init
terraform plan
terraform apply

# Test immutability
# Change app_version in terraform.tfvars
terraform apply  # Watch instance replacement
```

---

*This phase directly addresses the failure modes observed in the real-world malware incident, demonstrating how cloud-native architecture patterns solve traditional security challenges.*