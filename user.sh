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
VALIDATE $? " Disabling existing version of nodejs and enabling nodejs 20 version"

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

curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip 
cd /app 
unzip /tmp/user.zip
VALIDATE $? "Downloading and unzipping the content"

cd /app 
npm install 
VALIDATE $? "Downloading the dependencies"

cp $SCRIPT_DIR/user.service  /etc/systemd/system/user.service
VALIDATE $? "Copied the user service script"

systemctl daemon-reload
VALIDATE $? "Reload the daemon"

systemctl enable user 
systemctl start user
VALIDATE $? "Enabling and starting the user service"