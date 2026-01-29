#!/bin/bash
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>Application Server Reached!</h1><p>If you see this, traffic flow worked.</p>" > /var/www/html/index.html
