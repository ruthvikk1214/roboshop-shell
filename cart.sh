#!/bin/bash

USERID=$(id -u)
LOGS_FOLDER="/var/log/shell-roboshop"
LOGS_FILE="$LOGS_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.rk1214.in


if [ $USERID -ne 0 ]; then
    echo -e "$R Please run this script with root user access $N" | tee -a $LOGS_FILE
    exit 1
fi

mkdir -p $LOGS_FOLDER

VALIDATE(){
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y
dnf module enable nodejs:20 -y
VALIDATE $? "Disabling current nodejs version and enabling required version"

dnf install nodejs -y
VALIDATE $? "Installing nodejs"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating the roboshop user"
else 
echo "The roboshop user is already created.. "
fi

mkdir -p /app 
VALIDATE $? " creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
cd /app 
unzip /tmp/cart.zip

VALIDATE $? "Downloading and unzipping content to app directory"

cd /app 
npm install 
VALIDATE $? "Installing dependencies"

cp $SCRIPT_DIR/cart.service  /etc/systemd/system/cart.service

systemctl daemon-reload
VALIDATE $? " Reloading the daemon"

systemctl enable cart 
systemctl start cart
VALIDATE $? " Enabling and starting cart service"

