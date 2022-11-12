# Running Linkerd in Production

## Pre-requisites

* kubectl
* step
* helm
* make
* A configured Kubernetes cluster with 2 or more worker nodes

## Step 1: Create the root certificate

```
$ make create-root-cert
```

## Step 2: Create the issuer certificate

```
$ make create-issuer-cert
```

## Step 3: Update or tweak the HA configuration

The configuration is available in `values-ha.yaml` and
`viz-values-ha.yaml`. Tweak the config as required.

## Step 4: Install CRDs and Control Plan

```
$ make install
$ linkerd check
```

Give some time for the control plane to spin up and be available
and then proceed to step 5.

## Step 5: Install the viz extension

```
$ make viz-install
$ linkerd viz check
```

# Reference

* [Buoyant Service Mesh Academy](https://github.com/BuoyantIO/service-mesh-academy)
