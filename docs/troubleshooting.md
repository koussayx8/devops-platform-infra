# 🔧 Troubleshooting Guide - DevOps Platform Infrastructure

## Table of Contents

- [Quick Diagnostic Commands](#quick-diagnostic-commands)
- [Infrastructure Issues](#infrastructure-issues)
- [EKS Cluster Issues](#eks-cluster-issues)
- [ArgoCD Issues](#argocd-issues)
- [Application Issues](#application-issues)
- [Networking Issues](#networking-issues)
- [Performance Issues](#performance-issues)
- [Monitoring Issues](#monitoring-issues)
- [Cost and Resource Issues](#cost-and-resource-issues)
- [Security Issues](#security-issues)
- [Getting Help](#getting-help)

## Quick Diagnostic Commands

Run these commands to quickly assess the health of your infrastructure:

```bash
# Check cluster connectivity
kubectl cluster-info

# Check all nodes
kubectl get nodes

# Check all pods across namespaces
kubectl get pods -A

# Check for failed pods
kubectl get pods -A | grep -v Running | grep -v Completed

# Check recent events
kubectl get events -A --sort-by='.lastTimestamp' | tail -20

# Check resource usage
kubectl top nodes
kubectl top pods -A

# Check ArgoCD applications
kubectl get applications -n argocd

# Check ingress status
kubectl get ingress -A
```

## Infrastructure Issues

### Issue: Terraform Apply Fails

#### Symptom

```
Error: Error creating VPC: VpcLimitExceeded
```

or

```
Error: error creating IAM Role: EntityAlreadyExists
```

#### Causes

1. AWS resource limits reached
2. Resources already exist from previous deployment
3. Insufficient IAM permissions
4. Network connectivity issues

#### Solutions

**Solution 1: Check AWS Limits**

```bash
# Check VPC limit
aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-F678F1CE

# Check EKS cluster limit
aws service-quotas get-service-quota \
  --service-code eks \
  --quota-code L-1194D53C

# Request limit increase if needed
aws service-quotas request-service-quota-increase \
  --service-code vpc \
  --quota-code L-F678F1CE \
  --desired-value 10
```

**Solution 2: Import Existing Resources**

```bash
# List existing VPCs
aws ec2 describe-vpcs

# Import existing VPC into Terraform state
terraform import module.vpc.aws_vpc.main vpc-xxxxxxxxx

# Or destroy existing resources
terraform destroy
```

**Solution 3: Verify IAM Permissions**

```bash
# Check current IAM user/role
aws sts get-caller-identity

# Verify required permissions
# Required policies:
# - AmazonVPCFullAccess
# - AmazonEKSClusterPolicy
# - IAMFullAccess (or specific permissions)
# - EC2FullAccess
```

**Solution 4: Fix State Lock**

```bash
# If state is locked
aws dynamodb delete-item \
  --table-name terraform-state-locks \
  --key '{"LockID": {"S": "devops-terraform-state/devops-platform/terraform.tfstate"}}'

# Then retry
terraform apply
```

### Issue: Terraform State Corrupted

#### Symptom

```
Error: Failed to refresh state: state snapshot was created by Terraform vX.Y.Z
```

#### Solution

```bash
# List state versions in S3
aws s3api list-object-versions \
  --bucket devops-terraform-state \
  --prefix devops-platform/terraform.tfstate

# Download a previous version
aws s3api get-object \
  --bucket devops-terraform-state \
  --key devops-platform/terraform.tfstate \
  --version-id <version-id> \
  terraform.tfstate.backup

# Restore state
mv terraform.tfstate.backup terraform.tfstate

# Re-run terraform
terraform init
terraform plan
```

### Issue: S3 Backend Access Denied

#### Symptom

```
Error: Error loading state: AccessDenied
```

#### Solution

```bash
# Check bucket policy
aws s3api get-bucket-policy \
  --bucket devops-terraform-state

# Verify IAM permissions
aws iam get-user-policy \
  --user-name your-username \
  --policy-name TerraformStateAccess

# Test bucket access
aws s3 ls s3://devops-terraform-state/

# Add required permissions to IAM user/role
```

## EKS Cluster Issues

### Issue: Cannot Connect to EKS Cluster

#### Symptom

```
Unable to connect to the server: dial tcp: lookup xxxxx.eks.us-east-1.amazonaws.com: no such host
```

#### Solutions

**Solution 1: Update kubeconfig**

```bash
# Get cluster name
aws eks list-clusters --region us-east-1

# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name dev-cluster

# Verify
kubectl cluster-info
```

**Solution 2: Check Cluster Status**

```bash
# Describe cluster
aws eks describe-cluster \
  --name dev-cluster \
  --region us-east-1

# Check if cluster is ACTIVE
# Check endpoint access settings
```

**Solution 3: Verify IAM Permissions**

```bash
# Check if user has access to cluster
aws eks describe-cluster \
  --name dev-cluster \
  --region us-east-1

# Check aws-auth ConfigMap
kubectl get configmap aws-auth -n kube-system -o yaml

# Add your IAM user/role if missing
kubectl edit configmap aws-auth -n kube-system
```

### Issue: Nodes Not Joining Cluster

#### Symptom

```
kubectl get nodes
# Returns: No resources found
```

#### Causes

1. IAM role not properly configured
2. Security group blocking communication
3. Subnet tags missing
4. Node group in failed state

#### Solutions

**Solution 1: Check Node Group Status**

```bash
# Describe node group
aws eks describe-nodegroup \
  --cluster-name dev-cluster \
  --nodegroup-name dev-cluster-node-group \
  --region us-east-1

# Check health issues
# Look for CREATE_FAILED or DEGRADED status
```

**Solution 2: Verify IAM Role**

```bash
# Check node IAM role
aws iam get-role --role-name dev-cluster-node-group-role

# Verify attached policies
aws iam list-attached-role-policies \
  --role-name dev-cluster-node-group-role

# Required policies:
# - AmazonEKSWorkerNodePolicy
# - AmazonEKS_CNI_Policy
# - AmazonEC2ContainerRegistryReadOnly
```

**Solution 3: Check Security Groups**

```bash
# Get node security group
aws ec2 describe-security-groups \
  --filters "Name=tag:Name,Values=*node*"

# Verify inbound rules allow:
# - All traffic from cluster security group
# - Self-referencing rule for node-to-node communication
```

**Solution 4: Verify Subnet Tags**

```bash
# Check private subnet tags
aws ec2 describe-subnets --subnet-ids subnet-xxxxx

# Required tags:
# kubernetes.io/cluster/dev-cluster = shared
# kubernetes.io/role/internal-elb = 1
```

### Issue: Insufficient Capacity for Spot Instances

#### Symptom

```
Nodes not launching: InsufficientInstanceCapacity
```

#### Solutions

**Solution 1: Use Multiple Instance Types**

Edit `terraform/terraform.tfvars`:

```hcl
eks_node_instance_types = ["m7i-flex.large", "m6i.large", "m5.large"]
```

**Solution 2: Switch to On-Demand**

```hcl
eks_node_capacity_type = "ON_DEMAND"
```

**Solution 3: Try Different AZs**

```hcl
availability_zones = ["us-east-1a", "us-east-1c", "us-east-1d"]
```

## ArgoCD Issues

### Issue: ArgoCD Applications Stuck in OutOfSync

#### Symptom

```
kubectl get applications -n argocd
NAME              SYNC STATUS
ski-station-dev   OutOfSync
```

#### Solutions

**Solution 1: Force Sync**

```bash
# Check what's out of sync
kubectl describe application ski-station-dev -n argocd

# Force sync
kubectl patch application ski-station-dev -n argocd \
  --type merge \
  --patch '{"operation":{"sync":{"revision":"HEAD","prune":true}}}'

# Or use ArgoCD CLI
argocd app sync ski-station-dev --force
```

**Solution 2: Check Repository Access**

```bash
# Test repository access
git ls-remote https://github.com/koussayx8/devops-platform-infra.git

# Check ArgoCD repo server logs
kubectl logs -n argocd deployment/argocd-repo-server

# Verify repository credentials (if private)
kubectl get secrets -n argocd | grep repo
```

**Solution 3: Reset Application**

```bash
# Delete and recreate application
kubectl delete application ski-station-dev -n argocd
kubectl apply -f argocd/applications/ski-station-dev.yaml

# Wait for sync
kubectl wait --for=condition=synced --timeout=600s \
  application/ski-station-dev -n argocd
```

### Issue: ArgoCD Cannot Reach Git Repository

#### Symptom

```
Failed to load target state: rpc error: code = Unknown desc = authentication required
```

#### Solutions

**Solution 1: For Public Repositories**

```bash
# Verify repository URL is correct
kubectl get application ski-station-dev -n argocd -o yaml

# Test from pod
kubectl run test --rm -it --image=alpine -- \
  sh -c "apk add git && git ls-remote https://github.com/koussayx8/devops-platform-infra.git"
```

**Solution 2: For Private Repositories**

```bash
# Create repository secret
kubectl create secret generic repo-secret \
  -n argocd \
  --from-literal=username=<username> \
  --from-literal=password=<token>

# Update application to use secret
```

**Solution 3: Check Network Connectivity**

```bash
# Check if ArgoCD can reach GitHub
kubectl exec -n argocd deployment/argocd-repo-server -- \
  curl -I https://github.com

# Check DNS resolution
kubectl exec -n argocd deployment/argocd-repo-server -- \
  nslookup github.com
```

### Issue: ArgoCD Ingress Not Working

#### Symptom

Cannot access ArgoCD UI via browser

#### Solutions

**Solution 1: Check Ingress Status**

```bash
# Get ingress details
kubectl get ingress argocd-server-ingress -n argocd
kubectl describe ingress argocd-server-ingress -n argocd

# Check ALB controller logs
kubectl logs -n kube-system deployment/aws-load-balancer-controller

# Wait for ALB to be provisioned (can take 3-5 minutes)
```

**Solution 2: Port Forward (Temporary Access)**

```bash
# Port forward to local machine
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Access via: https://localhost:8080
```

**Solution 3: Check ALB in AWS Console**

```bash
# List load balancers
aws elbv2 describe-load-balancers \
  | jq '.LoadBalancers[] | select(.LoadBalancerName | contains("argocd"))'

# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
```

## Application Issues

### Issue: Pods Stuck in Pending State

#### Symptom

```
kubectl get pods -n ski-station
NAME                    READY   STATUS    RESTARTS   AGE
api-xxxxx               0/1     Pending   0          5m
```

#### Causes

1. Insufficient cluster resources
2. Node selector constraints
3. Persistent volume not available
4. Image pull errors

#### Solutions

**Solution 1: Check Pod Events**

```bash
# Describe pod
kubectl describe pod api-xxxxx -n ski-station

# Look for events like:
# - 0/2 nodes are available: Insufficient cpu
# - FailedScheduling: No nodes available
```

**Solution 2: Check Node Resources**

```bash
# Check node capacity
kubectl describe nodes

# Check resource usage
kubectl top nodes

# If insufficient, scale up
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name <asg-name> \
  --desired-capacity 3
```

**Solution 3: Check Persistent Volumes**

```bash
# List PVCs
kubectl get pvc -n ski-station

# Describe PVC
kubectl describe pvc mysql-pvc -n ski-station

# Check storage class
kubectl get storageclass
```

### Issue: Pods in CrashLoopBackOff

#### Symptom

```
NAME                    READY   STATUS             RESTARTS   AGE
api-xxxxx               0/1     CrashLoopBackOff   5          10m
```

#### Solutions

**Solution 1: Check Logs**

```bash
# Get current logs
kubectl logs api-xxxxx -n ski-station

# Get previous logs
kubectl logs api-xxxxx -n ski-station --previous

# Follow logs
kubectl logs -f api-xxxxx -n ski-station
```

**Solution 2: Check Configuration**

```bash
# Check environment variables
kubectl get pod api-xxxxx -n ski-station -o yaml | grep -A 20 env:

# Check ConfigMaps
kubectl get configmap -n ski-station
kubectl describe configmap app-config -n ski-station

# Check Secrets
kubectl get secrets -n ski-station
```

**Solution 3: Check Dependencies**

```bash
# Check if MySQL is running
kubectl get pods -n ski-station | grep mysql

# Test database connection from debug pod
kubectl run debug --rm -it --image=mysql:8.0 -- \
  mysql -h mysql-service -u springuser -p
```

### Issue: ImagePullBackOff Error

#### Symptom

```
NAME                    READY   STATUS             RESTARTS   AGE
api-xxxxx               0/1     ImagePullBackOff   0          2m
```

#### Solutions

**Solution 1: Verify Image Exists**

```bash
# Check image in ECR
aws ecr describe-images \
  --repository-name ski-station-api \
  --region us-east-1

# Check image tag
aws ecr list-images \
  --repository-name ski-station-api \
  --region us-east-1
```

**Solution 2: Check Image Pull Secrets**

```bash
# List secrets
kubectl get secrets -n ski-station

# Verify ECR secret
kubectl get secret ecr-registry-secret -n ski-station -o yaml

# Recreate secret if needed
kubectl create secret docker-registry ecr-registry-secret \
  --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n ski-station
```

**Solution 3: Check Node IAM Role**

```bash
# Verify node role has ECR permissions
aws iam list-attached-role-policies \
  --role-name dev-cluster-node-group-role

# Should include AmazonEC2ContainerRegistryReadOnly
```

### Issue: Database Connection Failures

#### Symptom

Application logs show:

```
Cannot connect to database: Connection refused
```

#### Solutions

**Solution 1: Check MySQL Pod**

```bash
# Check MySQL pod status
kubectl get pod -n ski-station -l app=mysql

# Check MySQL logs
kubectl logs -n ski-station deployment/mysql

# Exec into MySQL pod
kubectl exec -it -n ski-station deployment/mysql -- mysql -u root -p
```

**Solution 2: Verify Service**

```bash
# Check service
kubectl get svc mysql-service -n ski-station

# Test from another pod
kubectl run test --rm -it --image=mysql:8.0 -- \
  mysql -h mysql-service.ski-station.svc.cluster.local -u springuser -p
```

**Solution 3: Check Environment Variables**

```bash
# Verify database credentials in deployment
kubectl get deployment ski-station-api -n ski-station -o yaml | grep -A 10 SPRING_DATASOURCE

# Update if incorrect
kubectl set env deployment/ski-station-api \
  -n ski-station \
  SPRING_DATASOURCE_URL=jdbc:mysql://mysql-service:3306/stationSki
```

## Networking Issues

### Issue: Cannot Access Application via ALB

#### Symptom

Browser shows "This site can't be reached" when accessing ALB URL

#### Solutions

**Solution 1: Wait for ALB Provisioning**

```bash
# Check ingress status
kubectl get ingress ski-station-ingress -n ski-station

# Describe ingress
kubectl describe ingress ski-station-ingress -n ski-station

# ALB can take 3-5 minutes to provision
# Look for "Successfully reconciled" events
```

**Solution 2: Check ALB Target Health**

```bash
# Get ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `ski-station`)].LoadBalancerArn' \
  --output text)

# Get target groups
aws elbv2 describe-target-groups \
  --load-balancer-arn $ALB_ARN

# Check target health
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>

# Targets should be "healthy"
```

**Solution 3: Check Security Groups**

```bash
# Check ALB security group
aws ec2 describe-security-groups \
  --filters "Name=tag:ingress.k8s.aws/resource,Values=LoadBalancer"

# Verify inbound rules allow:
# - Port 80 from 0.0.0.0/0
# - Port 443 from 0.0.0.0/0 (if using HTTPS)
```

**Solution 4: Verify Service Endpoints**

```bash
# Check service endpoints
kubectl get endpoints -n ski-station

# Service should have endpoint IPs listed
# If no endpoints, pods are not healthy
```

### Issue: Internal Service Communication Fails

#### Symptom

Frontend cannot reach API

#### Solutions

**Solution 1: Test Service Discovery**

```bash
# From frontend pod
kubectl exec -it -n ski-station deployment/ski-station-frontend -- \
  curl http://ski-station-api-service:8089/api/actuator/health

# Should return {"status":"UP"}
```

**Solution 2: Check DNS Resolution**

```bash
# Test DNS from pod
kubectl exec -it -n ski-station deployment/ski-station-frontend -- \
  nslookup ski-station-api-service

# Verify CoreDNS is running
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**Solution 3: Check Network Policies**

```bash
# List network policies
kubectl get networkpolicies -n ski-station

# If policies exist, verify they allow required traffic
kubectl describe networkpolicy <policy-name> -n ski-station
```

## Performance Issues

### Issue: High CPU/Memory Usage

#### Symptom

Nodes or pods consuming excessive resources

#### Solutions

**Solution 1: Identify Resource Hogs**

```bash
# Check node resource usage
kubectl top nodes

# Check pod resource usage
kubectl top pods -A --sort-by=cpu
kubectl top pods -A --sort-by=memory

# Get detailed pod metrics
kubectl describe node <node-name>
```

**Solution 2: Adjust Resource Limits**

Edit deployment resource limits:

```yaml
resources:
  requests:
    memory: "500Mi"
    cpu: "300m"
  limits:
    memory: "1Gi"
    cpu: "500m"
```

**Solution 3: Scale Application**

```bash
# Horizontal scaling
kubectl scale deployment ski-station-api \
  --replicas=3 \
  -n ski-station

# Or configure HPA
kubectl autoscale deployment ski-station-api \
  --min=2 --max=5 \
  --cpu-percent=70 \
  -n ski-station
```

**Solution 4: Scale Cluster**

```bash
# Update node group desired capacity
aws eks update-nodegroup-config \
  --cluster-name dev-cluster \
  --nodegroup-name dev-cluster-node-group \
  --scaling-config desiredSize=4

# Or update via Terraform
# Edit terraform.tfvars: eks_node_desired_size = 4
# terraform apply
```

### Issue: Slow Application Response

#### Symptom

Application takes long time to respond

#### Solutions

**Solution 1: Check Application Logs**

```bash
# Check API logs for slow queries
kubectl logs -n ski-station deployment/ski-station-api | grep -i "slow"

# Check database logs
kubectl logs -n ski-station deployment/mysql
```

**Solution 2: Check Database Performance**

```bash
# Exec into MySQL
kubectl exec -it -n ski-station deployment/mysql -- mysql -u root -p

# Run performance queries
SHOW PROCESSLIST;
SHOW STATUS LIKE 'Slow_queries';

# Check indexes
SHOW INDEX FROM <table_name>;
```

**Solution 3: Review Resource Allocation**

```bash
# Check if pods are throttled
kubectl describe pod <pod-name> -n ski-station | grep -i throttl

# Increase resource limits if needed
```

## Monitoring Issues

### Issue: Prometheus Not Scraping Metrics

#### Symptom

No metrics showing in Grafana

#### Solutions

**Solution 1: Check Prometheus Targets**

```bash
# Port forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Open http://localhost:9090/targets in browser
# Check if targets are UP

# Or use kubectl
kubectl exec -n monitoring deployment/prometheus -- \
  wget -qO- http://localhost:9090/api/v1/targets | jq '.data.activeTargets'
```

**Solution 2: Verify ServiceMonitor**

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n ski-station

# Describe ServiceMonitor
kubectl describe servicemonitor ski-station-api -n ski-station

# Verify selector matches service labels
```

**Solution 3: Check Prometheus Configuration**

```bash
# Check Prometheus config
kubectl get configmap prometheus-config -n monitoring -o yaml

# Verify scrape configs are present
```

### Issue: Grafana Cannot Connect to Prometheus

#### Symptom

Grafana shows "No data" for all dashboards

#### Solutions

```bash
# Check Grafana logs
kubectl logs -n monitoring deployment/grafana

# Verify data source configuration
kubectl exec -n monitoring deployment/grafana -- \
  curl http://prometheus:9090/-/healthy

# Check service endpoints
kubectl get endpoints -n monitoring
```

## Cost and Resource Issues

### Issue: Unexpected High AWS Costs

#### Symptom

AWS bill higher than expected

#### Solutions

**Solution 1: Identify Cost Drivers**

```bash
# Check running EC2 instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' \
  --output table

# Check EBS volumes
aws ec2 describe-volumes \
  --query 'Volumes[*].[VolumeId,Size,VolumeType,State]' \
  --output table

# Check load balancers
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[*].[LoadBalancerName,Type,State.Code]' \
  --output table

# Check NAT gateways
aws ec2 describe-nat-gateways \
  --filter "Name=state,Values=available"
```

**Solution 2: Optimize Resources**

```bash
# Scale down nodes
kubectl scale deployment <deployment-name> --replicas=1 -n <namespace>

# Use Spot instances
# Edit terraform.tfvars: eks_node_capacity_type = "SPOT"

# Use single NAT gateway (non-prod)
# Edit terraform.tfvars: single_nat_gateway = true

# Delete unused resources
terraform destroy -target=module.monitoring
```

**Solution 3: Set Up Cost Alerts**

```bash
# Create billing alarm
aws cloudwatch put-metric-alarm \
  --alarm-name high-billing-alarm \
  --alarm-description "Alert when bill exceeds $200" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 200 \
  --comparison-operator GreaterThanThreshold
```

## Security Issues

### Issue: Pod Security Violations

#### Symptom

Pods fail to start due to security policies

#### Solutions

```bash
# Check pod security policies
kubectl get psp

# Describe PSP
kubectl describe psp restricted

# Update pod security context
kubectl edit deployment <deployment-name> -n <namespace>
```

### Issue: Secrets Exposed in Logs

#### Symptom

Sensitive data visible in logs or kubectl describe

#### Solutions

```bash
# Move secrets to Kubernetes Secrets
kubectl create secret generic db-secret \
  --from-literal=password=<password> \
  -n ski-station

# Update deployment to use secrets
kubectl set env deployment/ski-station-api \
  --from=secret/db-secret \
  -n ski-station

# Rotate compromised secrets
kubectl delete secret db-secret -n ski-station
kubectl create secret generic db-secret \
  --from-literal=password=<new-password> \
  -n ski-station
kubectl rollout restart deployment/ski-station-api -n ski-station
```

## Getting Help

### Documentation Resources

- [Main README](../README.md)
- [Architecture Guide](./architecture.md)
- [Deployment Guide](./deployment-guide.md)
- [ArgoCD Setup](./argocd-setup.md)

### Support Channels

1. **Check Existing Issues**: Search GitHub issues for similar problems
2. **Create New Issue**: Provide detailed information:
   - Error messages
   - kubectl describe output
   - Logs
   - Steps to reproduce
3. **Contact DevOps Team**: For urgent production issues

### Useful External Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [AWS EKS Troubleshooting](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html)
- [ArgoCD Troubleshooting](https://argo-cd.readthedocs.io/en/stable/operator-manual/troubleshooting/)
- [Terraform AWS Provider Issues](https://github.com/hashicorp/terraform-provider-aws/issues)

---

**Document Version:** 1.0  
**Last Updated:** October 2, 2025  
**Author:** Koussay
