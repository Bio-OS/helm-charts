# BioOS Install Docs

# 一、Prerequisites
1. 系统要求:
   - CentOS 7.9 +
   - Ubuntu 22.04 +
2. 部署环境支持外网访问（需访问 dockerhub）
3. 资源最低要求：最少 8 cpu and 16G memory
4. 已安装Docker：Docker安装可参看：Docker安装
5. 已部署Kubernetes：minikube安装
6. 强烈推荐版本：
- Minikube: v1.31.2
- kubernetes: 1.24.15
- Helm: 3.12.0
- MySQL: 8.0.34
# 二、部署前K8S环境准备
在开始Bio-OS部署前，请确保您已经在环境中获取了Bio-OS的开源[helm charts](https://github.com/Bio-OS/helm-charts)，Bio-OS支持部署在ARM64及x86_64架构，另外Bio-OS的部署需要基于Kubernetes，您可以选择部署Kubernetes社区版或Minikube。本文档内容基于x86架构，如您使用环境为arm架构，请注意对应镜像和工具需选择arm版本安装。
## 2.1 启动Minikube
此处已假定您已安装Minikube，Minikube的安装可见：Minikube Start。这里以 minikube 为例进行本地环境的构建，生产环境建议选择 kubespray 进行高可用部署。
```bash
# root 用户执行
minikube start \
  --image-mirror-country=cn \
  --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
  --force \
  --addons ingress \
  --cni flannel \
  --kubernetes-version 1.24.15 \
  --nodes 4 \
  --ports 80,443 \
  --service-cluster-ip-range '10.255.0.0/16' \ #可自行修改,但不建议修改
  --subnet '10.254.0.0/16' # 可执行修改,但不建议修改

# 快捷键配置
echo 'alias kubectl="minikube kubectl -- "' >> ~/.bashrc
source ~/.bashrc
```

## 2.2 安装 Helm
安装helm部署包（注意：helm 版本必须大于 2.0 版本，如已有helm则可跳过这步）。如果在arm架构下，需将helm地址修改为：https://get.helm.sh/helm-v3.12.0-linux-arm64.tar.gz
```bash
wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
tar xvf helm-v3.12.0-linux-amd64.tar.gz --strip-components=1 -C /usr/local/bin
```

## 2.3 NFS-Server 部署参考：
这里以 Ubuntu 为例部署 NFS 服务，变量 NFS_PATH 对应 NFS 存储目录。**(root 用户执行)**
```bash
#!/bin/bash
#
# Desc: Install NFS Server. OS: Ubuntu
# 
# Install NFS Server
# 
# 

function installNFSServer() {
    apt update && apt install -y nfs-kernel-server nfs-common
}

# Config NFS Server
function configNFS() {
    NFS_PATH=/nfs
    mkdir -p ${NFS_PATH}/bioos-storage && chmod -R 777 ${NFS_PATH}
    chown -R nobody:nogroup ${NFS_PATH}
    echo "${NFS_PATH} *(insecure,rw,sync,root_squash,no_subtree_check,all_squash)" >> /etc/exports
    systemctl restart nfs-server
    systemctl restart rpcbind
    exportfs -arv
    showmount -e localhost
}

# Set up auto-start on boot.
function autoStart() {
    systemctl enable nfs-server
    systemctl enable rpcbind
}

function main() {
    installNFSServer
    configNFS
    autoStart
}

main

```

安装后检查：
```bash
root@registry:/home/vagrant# systemctl status nfs-server
● nfs-server.service - NFS server and services
     Loaded: loaded (/lib/systemd/system/nfs-server.service; enabled; vendor preset: enabled)
    Drop-In: /run/systemd/generator/nfs-server.service.d
             └─order-with-mounts.conf
     Active: active (exited) since Thu 2023-05-18 21:33:05 CDT; 10s ago
    Process: 35987 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
    Process: 35988 ExecStart=/usr/sbin/rpc.nfsd (code=exited, status=0/SUCCESS)
   Main PID: 35988 (code=exited, status=0/SUCCESS)
        CPU: 6ms

May 18 21:33:05 registry systemd[1]: Starting NFS server and services...
May 18 21:33:05 registry systemd[1]: Finished NFS server and services...
```

## 2.4 安装 NFS-CSI 存储服务
```bash
# 参考文档：https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/charts/README.md
# 添加 nfs-csi helm repo
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

# 创建 NFS Secret
kubectl -n kube-system create secret generic mount-options --from-literal mountOptions="nfsvers=3,hard"

# install nfs-csi helm chart
helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs \
    --namespace kube-system \
    --version v4.4.0 \
    --set image.nfs.repository=dyrnq/nfsplugin \
    --set image.csiProvisioner.repository=dyrnq/csi-provisioner \
    --set image.csiSnapshotter.repository=dyrnq/csi-snapshotter \
    --set image.livenessProbe.repository=dyrnq/livenessprobe \
    --set image.nodeDriverRegistrar.repository=dyrnq/csi-node-driver-registrar \
    --set image.externalSnapshotter.repository=dyrnq/snapshot-controller
```
安装 storageClass，nfs-csi 默认不提供 sc 资源，需要我们手动安装 sc(参考文档：https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/deploy/example/storageclass-nfs.yaml)
将以下命令复制并在shell中执行。
```bash
cat << EOF | kubectl apply -f -
cat << EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-csi
provisioner: nfs.csi.k8s.io
parameters:
  server: ${NFS-SERVER-IPADDRESS}   # 这里填 NFS Server 地址
  share: /nfs
  csi.storage.k8s.io/provisioner-secret-name: "mount-options"
  csi.storage.k8s.io/provisioner-secret-namespace: "kube-system"
reclaimPolicy: Delete
volumeBindingMode: Immediate
mountOptions:
  - nfsvers=4.1
  - hard

EOF
```

## 2.5 检测是否可以正常挂载 PVC
复制以下命令并在shell中执行。
```bash
cat << EOF | kubectl apply -f -
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
spec:
  storageClassName: nfs-csi
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: test-pvc-pod
spec:
  volumes:
    - name: task-pv-storage
      persistentVolumeClaim:
        claimName: test-pvc
  containers:
    - name: nginx
      image: nginx
      ports:
        - containerPort: 80
          name: "http-server"
      volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: task-pv-storage
EOF

```

查看pod状态
```bash
# Pod 状态为 Running && PVC 状态为 Bound，则 NFS Server 可用
root@n37-043-061:~# kubectl get pods
NAME           READY   STATUS    RESTARTS   AGE
test-pvc-pod   1/1     Running   0          8d
root@n37-043-061:~# kubectl get pvc
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
test-pvc   Bound    pvc-8dd031d1-2316-44b0-bd46-bdaeea7f9fd5   1Gi        RWO            nfs-csi        8d
```

# 三、Bioos 部署
Bio-OS 的部署依赖 mysql 数据库、jupyterhub以及cromwell，安装 bioos 服务前需先安装mysql、jupyterhub和cromwell。
**安装顺序：MySQL -> Jupyterhub -> Cromwell -> Bioos（必须遵从）**
## 3.1 安装 Mysql 服务
```bash
helm repo add bitnami https://charts.bitnami.com/bitnami

helm install mysql bitnami/mysql \
    --create-namespace \
    --namespace bioos \
    --version 9.12.5 \
    --set auth.rootPassword=Bytedance2023 \
    --set primary.persistence.storageClass=nfs-csi
```
命令中的rootPassword可改成自己需要的密码，但是后续步骤中都要做对应的修改。
## 3.2 安装 Jupyterhub
Bioos 使用 helm 打包，目前分为四个子包，需要注意的是 Jupyterhub 部署之后，打开浏览器获取新的 token 才能继续部署 bioos-server、web 服务。
使用 Helm 安装jupyterhub（请注意选择符合环境架构的镜像）：
```bash
helm repo add bioos https://bio-os.github.io/helm-charts/charts

helm install jupyterhub bioos/jupyterhub \
    --namespace bioos \
    --create-namespace \
    --set hub.db.url=mysql+pymysql://root:Bytedance2023@mysql.bioos.svc.cluster.local:3306/bioos \
    --set hub.db.password=Bytedance2023

# 将 jupyterhub 服务暴露出来，使浏览器可以直接访问.拿到 token 之后，就可以关掉这个端口转发。
kubectl -n bioos port-forward --address 0.0.0.0 service/hub 8081:8081
```

打开浏览器访问：http://Server-IP/jupyterhub, 申请新 token.
![jupyterhub token](./img/jupyterhub.png)
## 3.3 安装 Cromwell
```bash
helm repo add https://bio-os.github.io/helm-charts/charts

helm install cromwell bioos/cromwell \
    --create-namespace \
    --namespace bioos \
    --set persistence.internal=true \
    --set db.mysql.host=mysql.bioos.svc.cluster.local \
    --set db.mysql.username=root \
    --set db.mysql.password=Bytedance2023
```

## 3.4 安装 Bioos 服务
```bash
helm repo add https://bio-os.github.io/helm-charts/chartss

helm install bioos bioos/bioos \
    --create-namespace \
    --namespace bioos \
    --set mysql.hostname=mysql.bioos.svc.cluster.local \
    --set mysql.database=bioos \
    --set mysql.username=root \
    --set mysql.password=Bytedance2023 \
    --set wes.endpoint=http://cromwell.bioos.svc.cluster.local:8000 \ #配置cromwell在K8S中的访问地址
    --set jupyterhub.endpoint=http://{{INGRESS-ADDRESS:PORT}}/jupyterhub/ \
    --set jupyterhub.adminToken=${jupyterhub-token}  # 这里填写2.2步骤中获取的token

# 端口转发：
kubectl -n ingress-nginx port-forward --address 0.0.0.0 service/ingress-nginx-controller 8888:80
```

# 四、环境验收
执行命令 `kubectl get po ,pv,pvc,ing` 查看应用部署状态，bioos 使用了两块存储，一块用于 Mysql,一块用于 bioos 存储，并提供了若干 ingress 规则，方便子路径引用服务。
```bash
kubectl get pod,pv,pvc,ingress
```
命令状态应该如下所示：
![pod status](./img/pod-status.png)
打开浏览器访问 http://{ServerIP}/workspace，至此完成 bioos 安装.
![Server](./img/finish.png)

