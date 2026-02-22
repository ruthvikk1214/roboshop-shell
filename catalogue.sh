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
dnf module disable nodejs -y &>> $LOGS_FILE
VALIDATE $? " Disabling the default nodejs version"

dnf module enable nodejs:20 -y &>> $LOGS_FILE
VALIDATE $? " Enabling the required nodejs version"

dnf install nodejs -y &>> $LOGS_FILE
VALIDATE $? " Installing the Nodejs"

id roboshop
if [ $? -ne 0 ]; then

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating app user"
else 
echo "The roboshop user is already created.. "
fi


mkdir -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
VALIDATE $? " Downloading the code"

cd /app 
VALIDATE $? "Moving to app directory"

rm -rf /app/*
VALIDATE $? "Removing existing content"

unzip /tmp/catalogue.zip
VALIDATE $? "Unzipping the app files in app directory"

cd /app 

npm install 
VALIDATE $? " Downloading the dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Creating catalogue service"

systemctl daemon-reload
VALIDATE $? "Reloading the daemon"

systemctl enable catalogue 
VALIDATE $? " Enabling the catalogue service"

systemctl start catalogue
VALIDATE $? "Starting the catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongosh -y
VALIDATE $? "Installing mongo db"

mongosh --host $MONGODB_HOST --quiet 'db.getMongo().getDBNames().indexOf("mydb")'
mongosh --host $MONGODB_HOST </app/db/master-data.js