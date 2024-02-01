#!/bin/bash

sudo apt update && sudo apt install -y nginx openssl apache2-utils



# Check if the /etc/nginx dir exists, 
# if it does, build out a directory structure for the sake of organization
if [[ -d /etc/nginx ]]; then
	if [[ ! -d /etc/nginx/ssl ]]; then
		sudo mkdir /etc/nginx/ssl
	fi
	if [[ ! -d $HOME/secure_html ]]; then
		mkdir $HOME/secure_html
	fi
fi

ssl_dir="/etc/nginx/ssl"
config_dir="/etc/nginx"
# Below: the default server block file for nginx
srv_blk_file="default"
srv_blk_dir="/etc/nginx/sites-available"
srv_blk_fullpath="${srv_blk_dir}/${srv_blk_file}"
# Below: The directory to contain our .kdbx files for later serving
secure_html="$HOME/secure_html"

# Create a backup of the OG server block configuratuion file
if [[ ! -f $srv_blk_fullpath.bak ]]; then
	sudo cp $srv_blk_fullpath $srv_blk_fullpath.bak 
fi

# Make a super boring ssl self-signed cert
nginx_key="$ssl_dir/nginx.key"
nginx_crt="$ssl_dir/nginx.crt"
if [[ ! -f $nginx_key && ! -f $nginx ]]; then
	sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $nginx_key -out $nginx_crt
fi

# Create a new password protected authentication file for the server
# this can be done using the htpasswd binary from the apache2-utils package
htpasswd_file="$config_dir/htpasswd"
if [[ ! -f $htpasswd_file ]]; then
	sudo htpasswd -c $htpasswd_file $USER
fi

# Create an empty .kdbx file
kdbx_file="$secure_html/password_database.kdbx"
sudo touch $kdbx_file
sudo chown www-data:www-data $secure_html && sudo chmod 2770 $secure_html

sudo tee "$srv_blk_fullpath" > /dev/null <<EOF
server {

	listen 443 ssl default_server;
	server_name wired.net;
	
	access_log /var/log/nginx/access.log;
	root $secure_html;

	ssl_certificate $nginx_crt;
	ssl_certificate_key $nginx_key;

	location / {
		auth_basic "Restricted";
		auth_basic_user_file "$htpasswd_file";

		dav_methods PUT DELETE MOVE COPY;
		dav_access group:rw all:r;
	}
}
EOF

sudo systemctl restart nginx.service
