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

dnf install maven -y
VALIDATE $? "installing maven"

id roboshop
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "Creating the roboshop user"
else 
echo "The roboshop user is already created.. "
fi

mkdir -p /app 
VALIDATE $? " creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip 
cd /app 
unzip /tmp/shipping.zip
VALIDATE $? "Downloading and unzipping content to app directory"

cd /app 
mvn clean package 
mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Downloading dependencies and building the app"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying shipping service file"

systemctl daemon-reload
VALIDATE $? "Reloading the daemon"

systemctl enable shipping 
systemctl start shipping
VALIDATE $? " Enabling and starting the shipping service"

dnf install mysql -y 
VALIDATE $? "installing mysql"

mysql -h mysql.rk1214.in -uroot -pRoboShop@1 < /app/db/schema.sql
VALIDATE $? " Loading Schema, Schema in database is the structure to it like what tables to be created and their necessary application layouts."

mysql -h mysql.rk1214.in -uroot -pRoboShop@1 < /app/db/app-user.sql 
VALIDATE $? " creating app user"


mysql -h mysql.rk1214.in  -uroot -pRoboShop@1 < /app/db/app-user.sql 
VALIDATE $? "loading master data"

systemctl restart shipping
VALIDATE $? "restarting shipping service"
