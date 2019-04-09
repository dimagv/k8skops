#!/bin/bash

#Set all the variables in this section
CLUSTER_NAME="cluster1"
DNS_ZONE="k8s.ironjab.com"
REGION="us-east-1"
BUCKET="ironjab-k8s-velero"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
ROLE_NAME="k8s-velero-${CLUSTER_NAME}.${DNS_ZONE}"
POLICY_NAME="k8s-velero-${CLUSTER_NAME}.${DNS_ZONE}"

#Best-effort install script prerequisites, otherwise they will need to be installed manually.
if [[ -f /usr/bin/apt-get && ! -f /usr/bin/jq ]]
then
  sudo apt-get update
  sudo apt-get install -y jq
fi
if [[ -f /bin/yum && ! -f /bin/jq ]]
then
  echo "This may fail if epel cannot be installed. In that case, correct/install epel and retry."
  sudo yum install -y epel-release
  sudo yum install -y jq || exit
fi

echo "7️⃣  Set up Velero"
printf "\n"

printf "   a) Creating IAM policy…\n"
cat > policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ec2:DescribeVolumes",
            "ec2:DescribeSnapshots",
            "ec2:CreateTags",
            "ec2:CreateVolume",
            "ec2:CreateSnapshot",
            "ec2:DeleteSnapshot"
        ],
        "Resource": "*"
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:GetObject",
            "s3:DeleteObject",
            "s3:PutObject",
            "s3:AbortMultipartUpload",
            "s3:ListMultipartUploadParts"
        ],
        "Resource": [
            "arn:aws:s3:::${BUCKET}/*"
        ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "s3:ListBucket"
        ],
        "Resource": [
            "arn:aws:s3:::${BUCKET}"
        ]
    }
  ]
}
EOF

unset TESTOUTPUT
TESTOUTPUT=$(aws iam list-policies | jq --arg policy "$POLICY_NAME" -r '.Policies[] | select(.PolicyName == $policy) | .Arn')
if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
then
  printf " ✅  Policy already exists\n"
  printf " ✅  Deleting existing policy\n"
  POLICY_ARN=$TESTOUTPUT
  aws iam detach-role-policy --role-name $ROLE_NAME --policy-arn $POLICY_ARN
  aws iam delete-policy --policy-arn $POLICY_ARN
fi

printf " ✅  Policy does not exist, creating now\n"
POLICY=$(aws iam create-policy --policy-name $POLICY_NAME --policy-document file://policy.json)
POLICY_ARN=$(echo $POLICY | jq -r '.Policy.Arn')
printf " ✅ \n"

printf "   b) Creating IAM role…\n"
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/nodes.${CLUSTER_NAME}.${DNS_ZONE}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

unset TESTOUTPUT
TESTOUTPUT=$(aws iam list-roles | jq --arg role "$ROLE_NAME" -r '.Roles[] | select(.RoleName == $role) | .Arn')
if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
then
  printf " ✅  Role already exists\n"
  printf " ✅  Deleting existing role\n"
  aws iam delete-role --role-name $ROLE_NAME
fi

printf " ✅  Role does not exist, creating now\n"
ROLE=$(aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json)
printf " ✅ \n"

printf "   c) Attaching policy to role…\n"
aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name $ROLE_NAME
printf " ✅ \n"

printf "   d) Deploying velero…\n"
sed -i -e "s@{{BUCKET}}@${BUCKET}@g" src/velero/05-backupstoragelocation.yaml
sed -i -e "s@{{REGION}}@${REGION}@g" src/velero/05-backupstoragelocation.yaml
sed -i -e "s@{{REGION}}@${REGION}@g" src/velero/06-volumesnapshotlocation.yaml
sed -i -e "s@{{ROLE_NAME}}@${ROLE_NAME}@g" src/velero/10-deployment.yaml
kubectl apply -f src/velero
printf " ✅ \n"

printf "   e) Cleaning…\n"
rm trust-policy.json policy.json
printf " ✅ \n"

printf "Done\n"
