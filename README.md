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
## 4. Créer un PersistentVolume et PersistentVolumeClaim
Déclarez un PersistentVolume (PV) et un PersistentVolumeClaim (PVC) dans Kubernetes pour le bucket S3. Utiliser les fichiers PV and PVC.

## Conclusion
Ce mini-projet démontre comment utiliser le Mountpoint for Amazon S3 CSI Driver pour monter un bucket S3 dans un pod Kubernetes sur EKS. En utilisant des IAM Policies et des Roles, nous avons sécurisé l'accès au bucket S3 pour les pods de Kubernetes.
