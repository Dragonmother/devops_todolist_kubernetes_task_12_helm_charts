# ToDoApp Kubernetes Deployment with Helm

## Prerequisites

- Docker Desktop
- kind
- kubectl
- Helm

## 1. Create Kubernetes cluster

Create the kind cluster using the provided configuration:

```bash
kind create cluster --name todoapp --config cluster.yml
```

Verify that all nodes are ready:

```bash
kubectl get nodes -o wide
```

## 2. Configure MySQL nodes

Check node labels:

```bash
kubectl get nodes --show-labels
```

Apply the required taint to each node labeled `app=mysql`:

```bash
kubectl taint nodes -l app=mysql app=mysql:NoSchedule --overwrite
```

Verify the taints:

```bash
kubectl describe nodes
```

## 3. Validate Helm chart

Update chart dependencies:

```bash
helm dependency update ./helm-chart/todoapp
```

Run Helm lint:

```bash
helm lint ./helm-chart/todoapp
```

## 4. Deploy the application

Run the bootstrap script:

```bash
bash bootstrap.sh
```

The script checks prerequisites, creates the kind cluster if necessary, installs the required components, updates Helm dependencies, and deploys the application.

## 5. Verify deployment

Check Helm release status:

```bash
helm list -A
```

Check pods:

```bash
kubectl get pods -A
```

Check services and workloads:

```bash
kubectl get all -A
```

Check persistent volumes and claims:

```bash
kubectl get pv,pvc -A
```

Check RBAC resources:

```bash
kubectl get role,rolebinding,serviceaccount -n todoapp
```

Check HPA:

```bash
kubectl get hpa -n todoapp
```

## 6. Save deployment output

Generate the deployment report:

```powershell
kubectl get all,cm,secret,ing -A | Out-File -Encoding utf8 output.log
```

The `output.log` file contains the Kubernetes resource inventory.

## 7. Cleanup

To remove the kind cluster:

```bash
kind delete cluster --name todoapp
```
