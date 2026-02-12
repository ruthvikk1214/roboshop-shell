#!/bin/bash

SG_ID="sg-0eec592803ede7730"
AMI_ID="ami-0220d79f3f480ecf5"

for INSTANCE in $@
do
    instance_id = $(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type "t3.micro"
    --security-group-ids $SG_ID \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$INSTANCE}]" \
    --query 'Instances[0].InstanceID' \
    --output text
)
if [ $INSTANCE == "frontend" ]; then
IP=$(
    aws ec2 describe-instances \
    --instance-ids $instance_id
    --query 'Reservations[].Instances[].PublicIpAddress' \
    --output text
)

done
