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
# Below is the default server block file for nginx
srv_blk_file="default"
srv_blk_dir="/etc/nginx/sites-available"
srv_blk_fullpath="${srv_blk_dir}/${srv_blk_file}"

# Create a backup of the server block configuratuion file
if [[ ! -f $srv_blk_fullpath.bak ]]; then
	cp $srv_blk_fullpath $srv_blk_fullpath.bak 
fi


