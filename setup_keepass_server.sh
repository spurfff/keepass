#!/bin/bash

sudo apt update
# Update the apt cache and install necessary files
applications=( "nginx" "openssl" "apache2-utils" )
for item in "${applications[@]}"; do
	if ! dpkg -l | grep -q "^ii\s*$item\s";  then
		sudo apt-get install -y $item
	fi
done



# Check if the /etc/nginx dir exists, 
# if it does, build out a directory structure for the sake of organization
if [[ -d /etc/nginx ]]; then
	if [[ ! -d /etc/nginx/ssl ]]; then
		sudo mkdir /etc/nginx/ssl
	fi
fi

ssl_dir="/etc/nginx/ssl"
config_dir="/etc/nginx"
root_dir="/var/www/keepass"
# Below: the default server block file for nginx
srv_blk_fileName="default"
srv_blk_dir="/etc/nginx/sites-available"
srv_blk_file="${srv_blk_dir}/${srv_blk_fileName}"
# Below: The directory to contain our .kdbx files for later serving
database_dir="$root_dir/database_files"

# Create the root directory if it does not already exist
if [[ ! -d $root_dir ]]; then
	sudo mkdir $root_dir
fi

# Create a backup of the OG server block configuratuion file
if [[ ! -f $srv_blk_file.bak ]]; then
	sudo cp $srv_blk_file $srv_blk_file.bak 
fi

# Make a super boring ssl self-signed cert
nginx_key="$ssl_dir/nginx.key"
nginx_crt="$ssl_dir/nginx.crt"
if [[ ! -f $nginx_key && ! -f $nginx_crt ]]; then
	sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $nginx_key -out $nginx_crt
fi

# Create a new password protected authentication file for the server
# this can be done using the htpasswd binary from the apache2-utils package
htpasswd_file="$config_dir/htpasswd"
if [[ ! -f $htpasswd_file ]]; then
	sudo htpasswd -c $htpasswd_file $USER
fi

# move the sample .kdbx file to the database directory 
kdbx_file="sample.kdbx"
if [[ -f ./$kdbx_file && ! -f $database_dir/$kdbx_file ]]; then
	sudo mv ./$kdbx_file $database_dir
else
	echo -e "The sample database file cannot be located...\n"
	sleep 1
fi
sudo chown -R www-data:www-data $database_dir && sudo chmod 2770 $database_dir

server_port=443
server_name="keepass"
access_log="/var/log/nginx/keepass.access.log"
auth_basic="keepass"


# Modify the nginx config file to get started
sudo tee "$srv_blk_file" > /dev/null <<EOF
server {
	listen 80;
	server_name $server_name;
	access_log off;

	# Redirects http to https
	return 302 https://$http_host$request_uri;
}

server {
	listen $server_port ssl;
	server_name $server_name;
	access_log $access_log;
	root $root_dir;

	ssl_certificate_key $nginx_key;
	ssl_certificate $nginx_crt;

	location / {
		auth_basic $auth_basic;
		auth_basic_user_file $htpasswd_file;
		
		dav_methods PUT DELETE MOVE;
		dav_access group:rw all:r;
	}
}
EOF

# Restart the server for changes to take effect
sudo systemctl restart nginx.service
