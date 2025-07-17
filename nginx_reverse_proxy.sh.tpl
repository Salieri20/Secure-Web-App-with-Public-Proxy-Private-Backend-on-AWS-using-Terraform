#!/bin/bash
yum update -y
amazon-linux-extras install nginx1 -y

cat > /etc/nginx/nginx.conf <<EOC
events {}
http {
    server {
        listen 80;
        location / {
            proxy_pass http://${alb_dns};
        }
    }
}
EOC

systemctl enable nginx
systemctl start nginx