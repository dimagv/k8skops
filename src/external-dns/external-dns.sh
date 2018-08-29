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

echo "7️⃣  Set up ExternalDNS"
printf "\n"

printf "   a) Creating IAM role with trust policy...\n"
cat > trust-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
          "Sid": "",
          "Effect": "Allow",
          "Principal": {
            "AWS": "arn:aws:iam::${AWS_ACCOUNT_ID}:role/nodes.${CLUSTER_NAME}.${DNS_ZONE}"
          },
          "Action": "sts:AssumeRole"
        }
    ]
}
EOF

ROLE_NAME=k8s-external-dns
unset TESTOUTPUT
TESTOUTPUT=$(aws iam list-roles | jq -r '.Roles[] | select(.RoleName == ${ROLE_NAME}) | .Arn')
if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
then
  printf " ✅  Policy already exists\n"
else
  printf " ✅  Policy does not yet exist, creating now.\n"
  aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file://trust-policy.json
  printf " ✅ \n"
fi


printf "   b) Creating IAM policy to allow external-dns access to AWS route53…\n"
cat > route53-policy.json << EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
            "route53:ChangeResourceRecordSets"
            ],
            "Resource": [
            "arn:aws:route53:::hostedzone/*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
            "route53:ListHostedZones",
            "route53:ListResourceRecordSets"
            ],
            "Resource": [
            "*"
            ]
        }
    ]
}
EOF

POLICY_NAME=k8s-external-dns-policy
unset TESTOUTPUT
TESTOUTPUT=$(aws iam list-policies | jq -r '.Policies[] | select(.PolicyName == ${POLICY_NAME}) | .Arn')
if [[ $? -eq 0 && -n "$TESTOUTPUT" ]]
then
  printf " ✅  Policy already exists\n"
  POLICY_ARN=$TESTOUTPUT
else
  printf " ✅  Policy does not yet exist, creating now.\n"
  POLICY=$(aws iam create-policy --policy-name ${POLICY_NAME} --policy-document file://route53-policy.json)
  POLICY_ARN=$(echo $POLICY | jq -r '.Policy.Arn')
  printf " ✅ \n"
fi

printf "   b) Attaching policy to IAM Role…\n"
aws iam attach-role-policy --policy-arn $POLICY_ARN --role-name $ROLE_NAME
printf " ✅ \n"

sed -i -e "s@{{DNS_ZONE}}@${DNS_ZONE}@g" deployment.yaml
kubectl apply -f .

printf "Done\n"