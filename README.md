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


kubectl kustomize <kustomization_directory>
kubectl apply -k <kustomization_directory>

[helm 集成 kustomization](https://austindewey.com/2020/07/27/patch-any-helm-chart-template-using-a-kustomize-post-renderer/)


```bash
helm install my-nginx $PATH_TO_CHART --post-renderer=./hook.sh
```