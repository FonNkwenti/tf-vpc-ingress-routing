#!/bin/bash
# Simple Web Server for Connectivity Testing (Port 80)
set -e
# Redirect output for logging
exec > >(tee /var/log/webserver-setup.log|logger -t webserver-setup -s 2>/dev/console) 2>&1
echo "--- STARTING WEB SERVER SETUP ---"

# 1. Update and install Apache (Amazon Linux 2023 uses dnf/yum)
yum update -y
yum install -y httpd wget curl

# 2. Configure Apache to listen on 80 (default HTTP port)
echo "Configuring Apache to listen on port 80..."
# Amazon Linux default httpd.conf already listens on 80, but we can verify/ensure.
sed -i 's/^Listen 8080/Listen 80/' /etc/httpd/conf/httpd.conf || true

# 3. Get instance metadata using IMDSv2
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
PUBLIC_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/public-ipv4)
INSTANCE_ID=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-id)

# 4. Create index.html
cat <<EOF > /var/www/html/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Connectivity Test</title>
    <style>
        body { font-family: sans-serif; background: #2c3e50; color: white; display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; }
        .box { background: #34495e; padding: 2rem; border-radius: 10px; box-shadow: 0 10px 30px rgba(0,0,0,0.5); }
        h1 { color: #3498db; margin-top: 0; }
        .meta { color: #bdc3c7; font-family: monospace; }
    </style>
</head>
<body>
    <div class="box">
        <h1>Server Reachable</h1>
        <p>This instance is ready for manual EVE-NG configuration.</p>
        <div class="meta">
            <p>Instance ID: $INSTANCE_ID</p>
            <p>Public IP: $PUBLIC_IP</p>
            <p>Web Port: 80</p>
        </div>
    </div>
</body>
</html>
EOF

# 5. Start and enable service
systemctl start httpd
systemctl enable httpd
echo "--- WEB SERVER SETUP COMPLETE ---"