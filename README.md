# helm-charts
# Usage
### 环境依赖

- k8s 
- docker/containerd
- mysql
- helm 
- nfs

### 条件
您自己的具有管理员（root）访问权限的服务器。这可以是本地计算机、远程托管计算机、每个访问 JupyterHub 的用户都应该在计算机上拥有一个标准用户帐户。安装将通过命令行完成 
- 如果您使用 SSH 远程登录到您的计算机

本教程在 CentOS 7.9 +、Ubuntu 22.04 +上测试
### Step1 k8s
这里以 minikube 为例进行本地环境的构建，生产环境建议选择 kubespray 进行高可用部署

Minikube的安装见：[Minikube Start](https://minikube.sigs.k8s.io/docs/start/)
可以参考如下：
```
# 创建Minikube集群
$ minikube start \
    --container-runtime="containerd" \
    --image-mirror-country=cn \
    --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers \
    --driver=docker \   
    --apiserver-ips='180.xxx.xx.xx' # 可选配置，如果需要外网访问，需要这里配置主机的外网IP
```
如果环境已经安装好 docker 使用 minikube start --driver=none 启动时出现如下错误
```
Sorry, Kubernetes 1.27.4 requires conntrack to be installed in root's path
```
这是缺少 conntrack ,使用 yum 安装即可

```
$ yum install epel-release
$ yum install conntrack-tools

#或者
$ apt install conntrack
```
首先为方便后续直接使用kubectl命令，我们使用以下命令追加 kubectl 快捷方式([kubectl命令行](https://kubernetes.io/zh-cn/docs/reference/kubectl/))
```
echo 'alias kubectl="minikube kubectl --"' >> ~/.bashrc
source ~/.bashrc
```

#### 安装网络插件

为了实现这些pod的跨主机通信所以我们必须要安装CNI网络插件，这里选择calico网络。(如果您使用的是arm机器，请选择下载对应架构版本并修改命令：https://github.com/containernetworking/plugins/releases/)

```
# 配置 calico cni 网络
$ mkdir -p /opt/cni/bin && wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
$ tar -xvf cni-plugins-linux-amd64-v1.3.0.tgz -C /opt/cni/bin
$ kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.1/manifests/calico.yaml
```
#### 安装 ingress 控制器

Ingress 部署可参考[官网链接](https://kubernetes.github.io/ingress-nginx/deploy/),还可以参考 kubespray 的 [nginx-ingress](https://github.com/kubernetes-sigs/kubespray/tree/master/roles/kubernetes-apps/ingress_controller/ingress_nginx) 部署配置.

```
# 安装 ingress 控制器(国内可能镜像下载会有问题)
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.7.1/deploy/static/provider/cloud/deploy.yaml

```
#### 安装 helm
安装helm部署包（如已有helm则可跳过这步），如果在arm架构下，需将helm地址修改为：
`https://get.helm.sh/helm-v3.12.0-linux-arm64.tar.gz`

```
$ wget https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
$ tar xvf helm-v3.12.0-linux-amd64.tar.gz \
    --strip-components=1 -C /usr/local/bin
```
#### 安装 csi-driver-nfs
可参考如下部署

```
$ helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts

# 修改如下 values.yaml 中image repo 的地址为国内地址，如上所示 
$ wget https://github.com/kubernetes-csi/csi-driver-nfs/blob/master/charts/v4.2.0/csi-driver-nfs/values.yaml

$ helm install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --version v4.2.0 -f values.yaml

```
如果下载 image 有问题，可以实用国内地址
```
image:
    nfs:
        repository: dyrnq/nfsplugin
        tag: v4.2.0
        pullPolicy: IfNotPresent
    csiProvisioner:
        repository: dyrnq/csi-provisioner
        tag: v3.3.0
        pullPolicy: IfNotPresent
    livenessProbe:
        repository: dyrnq/livenessprobe
        tag: v2.8.0
        pullPolicy: IfNotPresent
    nodeDriverRegistrar:
        repository: dyrnq/csi-node-driver-registrar
        tag: v2.6.2
        pullPolicy: IfNotPresent
```


Bioos 开源版本以 [Helm](https://helm.sh) 形式分发.

本仓库提供 helm 包的分发，适用于 github 部署 helm 仓库

```bash
$ helm repo add bioos https://markthink.github.io/helm-charts
helm search repo bioos
```

如果要更新仓库，执行  `helm repo update` 获取最新的仓库部署包


### Step2. 安装 mysql 

```bash
$ helm install mysql \
  --set auth.rootPassword="admin",auth.database=bioos,auth.username=admin,auth.password=admin,global.storageClass=nfs-csi,primary.persistence.size=50Gi \
  oci://registry-1.docker.io/bitnamicharts/mysql
```

### Step2. 安装 cromwell/jupyterhub

参考 charts/cromwell/values.yaml|charts/jupyterhub/values.example.yaml 修改配置

```bash
$ helm install cromwell bioos/cromwell -f values_well.yaml
$ helm install jupyterhub bioos/jupyterhub -f values_hub.yaml
```

### Step3. 安装 Bioos apiserver/web

参考 charts/bioos/values.yaml 修改配置

```bash
$ helm install cromwell bioos/bioos -f values.yaml
```


# 参考资源：
- [helm 集成 kustomization](https://austindewey.com/2020/07/27/patch-any-helm-chart-template-using-a-kustomize-post-renderer/)
- https://github.com/kubernetes-sigs/kustomize/issues/680
- https://github.com/kubernetes-sigs/kustomize/issues/3787

```bash
$ helm install demo $PATH_TO_CHART --post-renderer=./hook.sh
```

