# Mini-Projet: Monter un Bucket S3 dans un Pod Kubernetes sur EKS avec Mountpoint for Amazon S3 CSI Driver

## Description

Ce mini-projet montre comment monter un bucket S3 dans un pod Kubernetes sur Amazon EKS en utilisant le **Mountpoint for Amazon S3 CSI Driver**. Cela permet aux pods d'accéder directement à un bucket S3 via une interface de système de fichiers, tout en profitant de l'intégration avec les IAM Policies et Roles pour sécuriser l'accès.

## Prérequis

Avant de commencer, assurez-vous d'avoir :

- Un cluster Amazon EKS configuré.
- Un bucket S3 existant.
- Les permissions nécessaires pour créer des roles et policies IAM.
- **kubectl** et **eksctl** installés et configurés.
- Le **Amazon S3 CSI Driver** installé dans votre cluster EKS.

## Étapes du projet

## 1. Installer le Amazon S3 CSI Driver

Le CSI Driver pour Amazon S3 doit être installé sur votre cluster.Utilisez Helm pour l'installation :
```bash
helm repo add aws-s3-csi-driver https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-s3-csi-driver \
  aws-s3-csi-driver/aws-s3-csi-driver \
  --namespace kube-system
```

## 2. Créer la Policy IAM pour le Bucket S3
Créez une IAM Policy qui donne les permissions nécessaires à votre pod pour interagir avec le bucket S3. la policy nécessaire se trouve dans le fcihier AmazonS3DriverPolicy.json
```bash
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "MountpointFullBucketAccess",
            "Effect": "Allow",
            "Action": [
                "*"
            ],
            "Resource": [
                "arn:aws:s3:::example-bucket"
            ]
        },
        {
            "Sid": "MountpointFullObjectAccess",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:AbortMultipartUpload",
                "s3:DeleteObject"
            ],
            "Resource": [
                "arn:aws:s3:::example-bucket/*"
            ]
        }
    ]
}
```

## 3. Créer un Role IAM pour les Pods
Créez un IAM Role associé à la policy que vous venez de créer pour permettre aux pods d'utiliser les permissions S3.
```bash
eksctl create iamserviceaccount \
  --name s3-access-sa \
  --namespace default \
  --cluster <nom-du-cluster-eks> \
  --attach-policy-arn arn:aws:iam::<account-id>:policy/<nom-de-la-policy> \
  --approve
```
Ajouter la section Trust Relationship de votre role, ajoute le code suivant:
```bash
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::ACCOUNT_iD:oidc-provider/oidc.eks.AWS_REGION.amazonaws.com/id/OIDC_PROVIDER_ID"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.AWS_REGION.amazonaws.com/id/OIDC_PROVIDER_ID:aud": "sts.amazonaws.com",
                    "oidc.eks.AWS_REGION.amazonaws.com/id/OIDC_PROVIDER_ID:sub": "system:serviceaccount:kube-system:s3-csi-*"
                }
            }
        }
    ]
}
```
## 4. Créer un PersistentVolume et PersistentVolumeClaim
Déclarez un PersistentVolume (PV) et un PersistentVolumeClaim (PVC) dans Kubernetes pour le bucket S3. Utiliser les fichiers PV and PVC.

### PersistentVolume
```bash
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv
spec:
  capacity:
    storage: 120Gi 
  accessModes:
    - ReadWriteMany 
  mountOptions:
    - allow-delete
    - region eu-west-1  
  csi:
    driver: s3.csi.aws.com 
    volumeHandle: s3-csi-driver-volume
    volumeAttributes:
      bucketName: microservice-logs 
```

### PersistentVolumeClaim
```bash
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: s3-claim
spec:
  accessModes:
    - ReadWriteMany 
  storageClassName: "" 
  resources:
    requests:
      storage: 120Gi 
  volumeName: pv
```

## 5. Déployer le Pod avec Accès S3
```bash
---
apiVersion: v1
kind: Pod
metadata:
  name: s3-app
spec:
  containers:
    - name: app
      image: centos
      command: ["/bin/sh"]
      args: ["-c", "echo 'Hello from the container!' >> /data/$(date -u).txt; tail -f /dev/null"]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: s3-claim
```

## 6. Vérification
Une fois le pod déployé, accédez à celui-ci pour vérifier que le bucket S3 est bien monté.
```bash
kubectl exec -it s3-csi-pod -- /bin/sh
cd /data
ls
```

## Conclusion
Ce mini-projet démontre comment utiliser le Mountpoint for Amazon S3 CSI Driver pour monter un bucket S3 dans un pod Kubernetes sur EKS. En utilisant des IAM Policies et des Roles, nous avons sécurisé l'accès au bucket S3 pour les pods de Kubernetes.
