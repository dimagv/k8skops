#!/bin/bash

#Set all the variables in this section
CLUSTER_NAME="cluster1"
DNS_ZONE="k8s.ironjab.com"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')
ROLE_NAME="k8s-cluster-autoscaler-${CLUSTER_NAME}.${DNS_ZONE}"
POLICY_NAME="k8s-cluster-autoscaler-${CLUSTER_NAME}.${DNS_ZONE}"

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


echo "7️⃣  Set up Cluster Autoscaler role"
printf "\n"

printf "   a) Creating IAM role with trust policy…\n"
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
  printf " ✅  Policy already exists\n"
else
  printf " ✅  Policy does not yet exist, creating now.\n"
  ROLE_ARN=$(aws iam create-role --role-name $ROLE_NAME --assume-role-policy-document file://trust-policy.json)
  printf " ✅ \n"
fi


printf "   b) Creating IAM policy to allow cluster-autoscaler access to AWS resources…\n"
cat > policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    }
  ]
}
EOF

unset TESTOUTPUT
TESTOUTPUT=$(aws iam list-policies | jq --arg policy "$POLICY_NAME" -r '.Policies[] | select(.PolicyName == $policy) | .Arn')
if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
then
  printf " ✅  Policy already exists\n"
  POLICY_ARN=$TESTOUTPUT
else
  printf " ✅  Policy does not yet exist, creating now.\n"
  POLICY=$(aws iam create-policy --policy-name $POLICY_NAME --policy-document file://policy.json)
  POLICY_ARN=$(echo $POLICY | jq -r '.Policy.Arn')
  printf " ✅ \n"
fi

printf "   c) Attaching policy to IAM Role…\n"
aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name $ROLE_NAME
printf " ✅ \n"

printf "   d) Cleanup. Deleting policies…\n"
rm trust-policy.json policy.json
printf " ✅ \n"

printf "Done\n"