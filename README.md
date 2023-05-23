# helm-charts

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

Once Helm has been set up correctly, add the repo as follows:

  helm repo add bioos https://markthink.github.io/helm-charts

If you had already added this repo earlier, run `helm repo update` to retrieve
the latest versions of the packages.  You can then run `helm search repo
bioos` to see the charts.

To install the <chart-name> chart:

    helm install my-<chart-name> <alias>/<chart-name>

To uninstall the chart:

    helm delete my-<chart-name>


NFS_SERVER=192.168.0.100
NFS_PATH=/nfs
cat sc.yaml | sed "s/server: 192.168.46.255/server: ${NFS_SERVER}/g"|sed "s#share: /nfs#share: ${NFS_PATH}#g" > /tmp/sc.yaml