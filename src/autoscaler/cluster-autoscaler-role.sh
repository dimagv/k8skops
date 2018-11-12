#!/bin/bash

#Set all the variables in this section
CLUSTER_NAME="insurancetruck"
DNS_ZONE="example.com"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --output text --query 'Account')

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
TESTOUTPUT=$(aws iam list-roles | jq -r '.Roles[] | select(.RoleName == "k8s-cluster-autoscaler") | .Arn')
if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
then
  printf " ✅  Policy already exists\n"
else
  printf " ✅  Policy does not yet exist, creating now.\n"
  ROLE_ARN=$(aws iam create-role --role-name k8s-cluster-autoscaler --assume-role-policy-document file://trust-policy.json)
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
TESTOUTPUT=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName == "k8s-cluster-autoscaler") | .Arn')
if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
then
  printf " ✅  Policy already exists\n"
  POLICY_ARN=$TESTOUTPUT
else
  printf " ✅  Policy does not yet exist, creating now.\n"
  POLICY=$(aws iam create-policy --policy-name k8s-cluster-autoscaler --policy-document file://policy.json)
  POLICY_ARN=$(echo $POLICY | jq -r '.Policy.Arn')
  printf " ✅ \n"
fi

printf "   c) Attaching policy to IAM Role…\n"
aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name k8s-cluster-autoscaler
printf " ✅ \n"

printf "   d) Cleanup. Deleting policies…\n"
rm trust-policy.json policy.json
printf " ✅ \n"

printf "Done\n"