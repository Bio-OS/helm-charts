FROM jupyterhub/k8s-hub:2.0.0

USER root
RUN pip install -U --no-deps jupyterhub-kubespawner==4.3.0
USER ${NB_USER}

COPY myproxy.py myspawner.py myauthenticator.py /usr/local/etc/jupyterhub/
