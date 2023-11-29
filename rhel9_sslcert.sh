#!/bin/bash
# Author:           Christo Deale                  
# Date  :           2023-11-29             
# rhel9_sslcert:    Utility to setup a self-signed certificate for SSL in RHEL 9

# Check if OpenSSL is installed
if ! command -v openssl &>/dev/null; then
    echo "OpenSSL is not installed. Installing..."
    sudo dnf install openssl -y
    echo "OpenSSL has been installed."
fi

# Prompt the user for the private key filename
read -p "Enter the private key filename (e.g., example.key): " private_key_filename

# Generate a private key
sudo openssl genpkey -algorithm RSA -out "/etc/pki/tls/private/$private_key_filename" -aes256

# Prompt the user for certificate information
read -p "Enter the Common Name (CN) for the certificate (e.g., example.com): " common_name

# Create a self-signed SSL certificate
sudo openssl req -new -key "/etc/pki/tls/private/$private_key_filename" -out "/etc/pki/tls/certs/$common_name.crt"

# Configure the web server (Apache in this example)
echo "Configuring Apache..."
sudo dnf install httpd -y
sudo systemctl enable httpd
sudo systemctl start httpd
sudo dnf install mod_ssl -y

# Create an SSL virtual host configuration file
cat <<EOF | sudo tee "/etc/httpd/conf.d/$common_name-ssl.conf" >/dev/null
<VirtualHost *:443>
    ServerName $common_name
    DocumentRoot /var/www/html
    SSLEngine on
    SSLCertificateFile /etc/pki/tls/certs/$common_name.crt
    SSLCertificateKeyFile /etc/pki/tls/private/$private_key_filename
</VirtualHost>
EOF

# Restart Apache
sudo systemctl restart httpd

# Firewall configuration (if necessary)
read -p "Do you want to allow HTTPS traffic through the firewall? (y/n): " allow_https
if [ "$allow_https" == "y" ]; then
    sudo firewall-cmd --add-service=https --permanent
    sudo firewall-cmd --reload
    echo "HTTPS traffic allowed through the firewall."
fi

echo "Self-signed SSL certificate setup completed for $common_name."
