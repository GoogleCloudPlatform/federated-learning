---
apiVersion: v1
kind: PersistentVolume
metadata:
    name: nvflare-pv
    labels:
        app: nvflare
spec:
    accessModes:
        - ReadWriteMany
    capacity:
        storage: 5Gi
    storageClassName: nvflare-storage-class
    mountOptions:
        - implicit-dirs
    csi:
        driver: gcsfuse.csi.storage.gke.io
        volumeHandle: ${NVFLARE_WORKSPACE_BUCKET_NAME}
        volumeAttributes:
            gcsfuseLoggingSeverity: warning
