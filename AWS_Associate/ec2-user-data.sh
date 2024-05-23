#!/bin/bash
# Use this for you user data (script to run at EC2 instance bootstrap - only first time)
# this will install httpd  (Linux)
# This will run as root
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1> Hello World from $(hostname) in AZ $EC2_AVAIL_ZONE</h1>" > /var/www/html/index.html

