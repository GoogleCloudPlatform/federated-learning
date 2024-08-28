---
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - nvflare/base-storage
  - nvflare/server1
  - nvflare/client1
  - nvflare/client2

namespace: ${NVFLARE_EXAMPLE_WORKLOADS_KUBERNETES_NAMESPACE}

images:
  - name: nvflare-tensorflow
    newName: ${NVFLARE_EXAMPLE_CONTAINER_IMAGE_LOCALIZED_ID}
    newTag: ${NVFLARE_EXAMPLE_CONTAINER_IMAGE_TAG}
