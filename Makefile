CERT_ROOT:=$(PWD)
KUBECTL=k3s kubectl

create-root-cert:
	step certificate create \
		root.linkerd.cluster.local \
		"${CERT_ROOT}/ca.crt" "${CERT_ROOT}/ca.key" \
		--profile root-ca \
		--no-password --insecure

create-issuer-cert:
	step certificate create \
		identity.linkerd.cluster.local \
		${CERT_ROOT}/issuer.crt ${CERT_ROOT}/issuer.key \
		--profile intermediate-ca \
		--not-after 8760h --no-password --insecure \
		--ca ${CERT_ROOT}/ca.crt --ca-key ${CERT_ROOT}/ca.key

create-certificates: create-root-cert create-issuer-cert

disable-admission-webhook:
	$(KUBECTL) label namespace kube-system config.linkerd.io/admission-webhooks=disabled

add-helm-repo:
	helm repo add linkerd https://helm.linkerd.io/stable

# Refer: https://linkerd.io/2.12/features/cni/
# Some clusters that do not support CAP_NET_ADMIN may require the --set cniEnabled=true
# to be passed to Helm.
install-crds:
	helm install linkerd-crds linkerd/linkerd-crds \
		  -n linkerd --create-namespace 

uninstall-crds:
	helm uninstall linkerd-crds -n linkerd

install-control-plane:
	helm install linkerd-control-plane \
		-n linkerd \
		--set-file identityTrustAnchorsPEM=${CERT_ROOT}/ca.crt \
		--set-file identity.issuer.tls.crtPEM=${CERT_ROOT}/issuer.crt \
		--set-file identity.issuer.tls.keyPEM=${CERT_ROOT}/issuer.key \
		--set identity.issuer.crtExpiry=$(date -d '+8760 hour' +"%Y-%m-%dT%H:%M:%SZ") \
		-f values-ha.yaml \
		linkerd/linkerd-control-plane

uninstall-control-plane:
	helm uninstall linkerd-control-plane -n linkerd

install-viz:
	helm install linkerd-viz -n linkerd-viz --create-namespace \
		-f viz-values-ha.yaml \
		linkerd/linkerd-viz

uninstall-viz:
	helm uninstall linkerd-viz -n linkerd-viz

install: add-helm-repo disable-admission-webhook install-crds install-control-plane
	@echo Please wait till the control plane components are up, and install \
		the viz extension with \"make viz\"

uninstall: uninstall-viz uninstall-control-plane uninstall-crds

