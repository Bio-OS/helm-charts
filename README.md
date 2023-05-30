# helm-charts

## Usage

Bioos 开源版本以 [Helm](https://helm.sh) 形式分发，安装参考 [Bioos 开源部署方案设计](https://bytedance.feishu.cn/docx/IrwHdNXi8oGYRPxe6VCcCPsMnmf) 

本仓库提供 helm 包的分发，适用于 github 部署 helm 仓库

```bash
helm repo add bioos https://markthink.github.io/helm-charts
helm search repo bioos
```

如果要更新仓库，执行  `helm repo update` 获取最新的仓库部署包


### Step1. 安装 mysql 

```bash
helm install mysql \
  --set auth.rootPassword="admin",auth.database=bioos,auth.username=admin,auth.password=admin,global.storageClass=nfs-csi,primary.persistence.size=50Gi \
  oci://registry-1.docker.io/bitnamicharts/mysql
```

### Step2. 安装 cromwell/jupyterhub

参考 charts/cromwell/values.yaml|charts/jupyterhub/values.example.yaml 修改配置

```bash
helm install cromwell bioos/cromwell -f values_well.yaml
helm install jupyterhub bioos/jupyterhub -f values_hub.yaml
```

### Step3. 安装 Bioos apiserver/web

参考 charts/bioos/values.yaml 修改配置

```bash
helm install cromwell bioos/bioos -f values.yaml
```


# 参考资源：
- [helm 集成 kustomization](https://austindewey.com/2020/07/27/patch-any-helm-chart-template-using-a-kustomize-post-renderer/)
- https://github.com/kubernetes-sigs/kustomize/issues/680
- https://github.com/kubernetes-sigs/kustomize/issues/3787

```bash
helm install demo $PATH_TO_CHART --post-renderer=./hook.sh
```

