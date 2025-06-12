# AWS Landing Zone Terraform Structure

This repository implements an AWS Landing Zone following the AWS Security Reference Architecture (SRA) principles with a multi-account, multi-domain approach for enterprise-grade cloud infrastructure management.

## Architecture Overview

The landing zone is organized into distinct domains, each handling specific aspects of the AWS infrastructure:

```
domain/
backup/          # Database backup management
bootstrap/       # Initial infrastructure setup
identity/        # AWS Identity Center configuration
logging/         # Centralized logging infrastructure
networking/      # Network foundation and connectivity
org/             # AWS Organizations management
security/        # Security services and policies
sharedservices/  # Common services across accounts
workloads/       # Application workloads by region
    app/
        ap-southeast-2/
        eu-west-1/
        eu-west-2/
```

## Domain Descriptions

### Bootstrap Domain
**Purpose**: Foundation setup for the entire landing zone
- Creates S3 state buckets for Terraform state management
- Establishes IAM User for automation
- Creates IAM Role with AdministratorAccess for cross-account operations
- Must be deployed first before all other domains

### Org Domain  
**Purpose**: AWS Organizations management (Organization Account)
- Manages AWS Organizations structure
- Implements Service Control Policies (SCPs)
- Handles account creation and organizational units
- Configures organization-wide settings and governance

### Identity Domain
**Purpose**: AWS Identity Center (SSO) configuration
- Registers and configures AWS Identity Center instance
- Manages SSO users and groups
- Defines permission sets and access policies
- Handles federated identity integration

### Security Domain
**Purpose**: Security services and compliance
- Deploys AWS Config for compliance monitoring
- Implements AWS Security Hub for security findings
- Configures AWS GuardDuty for threat detection
- Manages security policies and standards

### Logging Domain
**Purpose**: Centralized logging infrastructure
- Sets up CloudTrail for API logging
- Configures log aggregation and retention
- Implements log analysis and monitoring
- Manages log shipping to security account

### Networking Domain
**Purpose**: Network foundation and connectivity
- Creates VPCs and subnet architecture
- Implements network security groups and NACLs
- Manages VPC peering and transit gateway
- Configures DNS and connectivity solutions

### Backup Domain
**Purpose**: Database backup management using AWS Backup
- Implements AWS Backup service configuration
- Creates backup vaults and policies
- Manages cross-region backup replication
- Provides secondary safeguarding for critical databases
- Handles backup retention and compliance

### Shared Services Domain
**Purpose**: Common services across accounts
- Deploys shared infrastructure components
- Manages common utilities and tools
- Implements cross-account resource sharing
- Handles centralized service management

### Workloads Domain
**Purpose**: Application workloads by region
- **Regional Structure**: Segregated by geographic regions
  - `ap-southeast-2/` - Asia Pacific (Sydney)
  - `eu-west-1/` - Europe (Ireland)  
  - `eu-west-2/` - Europe (London)
- **Application Bootstrapping**: Sets up application infrastructure
- **IAM Management**: Creates IAM users per application, per region
- **Workload Isolation**: Each region can support different workload types
- **Regional Compliance**: Handles region-specific requirements

## Makefile Usage

The repository includes a comprehensive Makefile for managing Terraform operations across all domains.

### Prerequisites

1. **AWS Authentication**: Set AWS credentials
   ```bash
   export AWS_ACCESS_KEY_ID="your-access-key"
   export AWS_SECRET_ACCESS_KEY="your-secret-key"
   ```

2. **Required Variables**:
   - `DOMAIN`: The domain to operate on
   - `REGION`: AWS region (for workloads domain)

### Core Commands

#### Initialize Domain
```bash
# Initialize a domain (creates .terraform directory and downloads providers)
make init DOMAIN=bootstrap

# Initialize with region (for workloads)
make init DOMAIN=workloads REGION=eu-west-1
```

#### Plan Changes
```bash
# Plan changes for a domain
make plan DOMAIN=identity

# Plan with region
make plan DOMAIN=workloads REGION=ap-southeast-2
```

#### Apply Changes
```bash
# Apply changes (requires region validation for workloads)
make apply DOMAIN=security

# Apply with region
make apply DOMAIN=workloads REGION=eu-west-2
```

#### Destroy Resources
```bash
# Destroy domain resources
make destroy DOMAIN=logging
```

#### State Management
```bash
# List resources in state
make list DOMAIN=networking

# Show specific resource
make show DOMAIN=org ARGS="aws_organizations_organization.main"

# Remove resource from state
make rm DOMAIN=security ARGS="aws_config_configuration_recorder.main"

# Import existing resource
make import DOMAIN=identity ARGS="aws_identitystore_group.admins i-1234567890abcdef0"
```

#### Utility Commands
```bash
# Format all Terraform files
make fmt

# Clean Terraform cache
make clean DOMAIN=bootstrap

# Open Terraform console
make console DOMAIN=sharedservices
```

## Deployment Workflow

### 1. Bootstrap Deployment (Required First)
```bash
# Initialize and apply bootstrap domain
make init DOMAIN=bootstrap
make plan DOMAIN=bootstrap
make apply DOMAIN=bootstrap
```

### 2. Organization Setup
```bash
# Deploy organization structure
make init DOMAIN=org
make apply DOMAIN=org
```

### 3. Core Infrastructure
```bash
# Deploy in sequence
for domain in identity security logging networking; do
  make init DOMAIN=$domain
  make apply DOMAIN=$domain
done
```

### 4. Shared Services
```bash
make init DOMAIN=sharedservices
make apply DOMAIN=sharedservices
```

### 5. Backup Infrastructure
```bash
make init DOMAIN=backup
make apply DOMAIN=backup
```

### 6. Regional Workloads
```bash
# Deploy per region
for region in ap-southeast-2 eu-west-1 eu-west-2; do
  make init DOMAIN=workloads REGION=$region
  make apply DOMAIN=workloads REGION=$region
done
```

## Advanced Usage Examples

### Cross-Domain Dependencies
```bash
# Plan multiple domains to check dependencies
make plan DOMAIN=networking
make plan DOMAIN=security
make plan DOMAIN=workloads REGION=eu-west-1
```

### Regional Workload Management
```bash
# Deploy application to specific region
make apply DOMAIN=workloads REGION=ap-southeast-2 ARGS="-target=aws_iam_user.app_user"

# Plan workload changes across regions
for region in ap-southeast-2 eu-west-1 eu-west-2; do
  echo "Planning region: $region"
  make plan DOMAIN=workloads REGION=$region
done
```

### State File Management
```bash
# Backup state files (stored in S3 automatically)
# View state file location
make init DOMAIN=identity  # Shows S3 backend configuration

# State files are stored at:
# s3://myorg-tf-state/identity/terraform.tfstate
# s3://myorg-tf-state/workloads/eu-west-1/terraform.tfstate
```

## Configuration Management

### Terraform Variables
- Global variables: Each domain uses `common.auto.tfvars`
- Region-specific variables: `workloads/app/{region}/{region}.tfvars`
- Account ID configuration in `common.auto.tfvars`

### State Management
- **Remote State**: S3 backend with DynamoDB locking
- **State Key Structure**: `{domain}/[{region}/]terraform.tfstate`
- **Encryption**: All state files encrypted at rest

## Security Considerations

1. **IAM Roles**: Cross-account access via `OrganizationAccountAccessRole`
2. **State Security**: Terraform state stored in encrypted S3 bucket
3. **Credential Management**: No hardcoded credentials in code
4. **Regional Isolation**: Workloads isolated by region and account
5. **Backup Security**: Database backups encrypted and cross-region replicated

## Troubleshooting

### Common Issues
```bash
# Backend initialization issues
make clean DOMAIN=identity
make init DOMAIN=identity

# Region validation errors
make apply DOMAIN=workloads REGION=eu-west-1  # Ensure REGION is specified

# State lock issues
# Check DynamoDB table: myorg-tf-state-lock
```

### Validation Commands
```bash
# Validate Terraform syntax
terraform fmt -check -recursive

# Validate configuration
make plan DOMAIN=bootstrap ARGS="-detailed-exitcode"
```

## Contributing

1. Always run `make fmt` before committing
2. Test plans before applying: `make plan DOMAIN=<domain>`
3. Use feature branches for domain changes
4. Follow AWS Well-Architected principles

## Repository Structure Alignment

This structure aligns with AWS Security Reference Architecture (SRA) best practices:
- **Multi-account strategy** for security and compliance
- **Organizational Units** for logical separation
- **Regional distribution** for resilience and compliance
- **Centralized logging and security** monitoring
- **Identity-first approach** with AWS Identity Center