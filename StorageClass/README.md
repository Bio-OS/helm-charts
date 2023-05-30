# StorageClass

使用 Kustomize 处理相关变参,代码结构如下：

```bash
root@opensource-bioos:~/helm-charts/StorageClass# tree .
.
├── base
│   ├── kustomization.yaml
│   └── yaml
│       ├── ingress-nginx.yaml
│       └── sc.yaml
└── overlays
    ├── dev
    │   └── kustomization.yaml
    └── prod
        └── kustomization.yaml

5 directories, 5 files
```
配置文件目录结构如上

- base 是基础的资源配置文件
- overlays 根据不同的环境配置相关的变量

进入目录执行下面的命令查看生成结果，生成之前，需要修改kustomization.yaml 文件
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
# https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patches/
# https://kubectl.docs.kubernetes.io/references/kustomize/kustomization/patchesjson6902/
resources:
# - yaml/ingress-nginx.yaml
- yaml/sc.yaml

patches:
- patch: |-
    - op: replace
      path: /parameters/server
      value: 192.168.46.300  #这里填写 nfs server 地址
    - op: replace
      path: /parameters/share
      value: /nfs #这里填写 nfs server 根目录地址
  target:
    kind: StorageClass
    name: nfs-csi
    
- patch: |-
    - op: replace
      path: /spec/csi/volumeAttributes/server
      value: 192.168.46.300    
    - op: replace
      path: /spec/csi/volumeAttributes/share
      value: /nfs
    - op: replace
      path: /spec/csi/volumeHandle
      value: 192.168.46.300#nfs#bioos-storage# 
    - op: replace
      path: /spec/capacity/storage
      value: 50Gi
  target:
    kind: PersistentVolume
    name: bioos-storage

- patch: |-
    - op: replace
      path: /spec/resources/requests/storage
      value: 50Gi  #这里配置存储块的大小
  target:
    kind: PersistentVolumeClaim
    name: bioos-storage-pvc
```

填写正确的 server 相关信息，执行命令检查无误
```bash
# kubectl kustomize <kustomization_directory>
cd base
kubectl kustomize .
```
执行下面的命令完成资源创建
```bash
# kubectl apply -k <kustomization_directory>
cd base
kubectl apply -k .
```