import escapism
import string

from kubespawner import proxy
from kubespawner.objects import make_ingress
from kubernetes_asyncio import client

from jupyterhub.utils import exponential_backoff

class KubeIngressProxy(proxy.KubeIngressProxy):
    async def add_route(self, routespec, target, data):
        # Create a route with the name being escaped routespec
        # Use full routespec in label
        # 'data' is JSON encoded and put in an annotation - we don't need to query for it

        safe_name = self._safe_name_for_routespec(routespec).lower()
        common_labels = {}
        if data.get('hub', False):
            # BioOS: hub does not have key `user` or `services` to call _expand_user_properties
            common_labels = self.common_labels
        else:
            # BioOS: user does not have key `services` to call _expand_user_properties
            if 'services' not in data:
                data.update({'services': ''})
            common_labels = self._expand_all(self.common_labels, routespec, data)
        common_labels.update({'component': self.component_label})
        endpoint, service, ingress = make_ingress(
            name=safe_name,
            routespec=routespec,
            target=target,
            common_labels=common_labels,
            data=data,
        )
        # BioOS: final '/' will not match ingress Prefix
        for r in ingress.spec.rules:
            for i in range(len(r.http.paths)):
                if r.http.paths[i].path.endswith('/'):
                    r.http.paths[i].path = r.http.paths[i].path.rstrip('/')

        async def ensure_object(create_func, patch_func, body, kind):
            try:
                await create_func(namespace=self.namespace, body=body)
                self.log.info('Created %s/%s', kind, safe_name)
            except client.rest.ApiException as e:
                if e.status == 409:
                    # This object already exists, we should patch it to make it be what we want
                    self.log.warn(
                        "Trying to patch %s/%s, it already exists", kind, safe_name
                    )
                    await patch_func(
                        namespace=self.namespace,
                        body=body,
                        name=body.metadata.name,
                    )
                else:
                    raise

        if endpoint is not None:
            await ensure_object(
                self.core_api.create_namespaced_endpoints,
                self.core_api.patch_namespaced_endpoints,
                body=endpoint,
                kind='endpoints',
            )

            await exponential_backoff(
                lambda: f'{self.namespace}/{safe_name}'
                in self.endpoint_reflector.endpoints.keys(),
                'Could not find endpoints/%s after creating it' % safe_name,
            )
        else:
            delete_endpoint = self.core_api.delete_namespaced_endpoints(
                name=safe_name,
                namespace=self.namespace,
                body=client.V1DeleteOptions(grace_period_seconds=0),
            )
            await self._delete_if_exists('endpoint', safe_name, delete_endpoint)

        await ensure_object(
            self.core_api.create_namespaced_service,
            self.core_api.patch_namespaced_service,
            body=service,
            kind='service',
        )

        await exponential_backoff(
            lambda: f'{self.namespace}/{safe_name}'
            in self.service_reflector.services.keys(),
            'Could not find service/%s after creating it' % safe_name,
        )

        await ensure_object(
            self.networking_api.create_namespaced_ingress,
            self.networking_api.patch_namespaced_ingress,
            body=ingress,
            kind='ingress',
        )

        await exponential_backoff(
            lambda: f'{self.namespace}/{safe_name}'
            in self.ingress_reflector.ingresses.keys(),
            'Could not find ingress/%s after creating it' % safe_name,
        )
