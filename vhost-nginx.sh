
#!/bin/bash
### Set Language
TEXTDOMAIN=virtualhost
## kudos to  https://github.com/RoverWire/virtualhost/blob/master/virtualhost-nginx.sh for the neat headstart 
### Set default parameters
### Version 1.5
action=$1
domain=$2
rootDir=$3
owner='nginx'
sitesEnable='/etc/nginx/sites-enabled/'
sitesAvailable='/etc/nginx/sites-available/'
userDir='/var/www/WebProduction/'

if [ "$(whoami)" != 'root' ]; then
	echo $"You have no permission to run $0 as non-root user. Use sudo"
		exit 1;
fi

if [ "$action" != 'create' ] && [ "$action" != 'delete' ] && [ "$action" != 'makecert' ]
	then
		echo $"You need to prompt for action (create delete or makecert) -- Lower-case only"
		exit 1;
fi

while [ "$domain" == "" ]
do
	echo -e $"Please provide domain. e.g.dev,staging"
	read domain
done

if [ "$rootDir" == "" ]; then
	rootDir=/var/www/WebProduction/$domain
fi

### if root dir starts with '/', don't use /var/www as default starting point
if [[ "$rootDir" =~ ^/ ]]; then
	userDir=''
fi

rootDir=$rootDir

if [ "$action" == 'create' ]
	then
		### check if domain already exists
		if [ -e $sitesAvailable$domain ]; then
			echo -e $"This domain already exists.\nPlease try another one"
			exit;
		fi

		### check if directory exists or not
		if ! [ -d $rootDir ]; then
			### create the directory
			mkdir $rootDir
			### give permission to root dir
			chmod 755 $rootDir
			### write test file in the new domain dir
			if ! echo "<?php echo phpinfo(); ?>" > $rootDir/phpinfo.php
				then
					echo $"ERROR: Not able to write in file $userDir/$rootDir/phpinfo.php. Please check permissions."
					exit;
			else
					echo $"phpinfo file added to $rootDir/phpinfo.php."
			fi
		fi
				###Create Self-Signed Certificate
				openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/pki/tls/private/$domain.key -out /etc/ssl/certs/$domain.crt
		### create virtual host rules file
		if ! echo "server {

    # listen to port 80
    listen 80;
    listen    [::]:80;
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    ssl_certificate /etc/ssl/certs/$domain.crt;
    ssl_certificate_key /etc/pki/tls/private/$domain.key;
    
	ssl_session_timeout 5m;
    
    # server name or names
    server_name $domain;
    # the location of webroot
    # Root dir is modified to match the Apache structure
    # Nginx by default uses another structure
    root  $rootDir;
    # in root location
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
expires 7d;
}
    location / {
        # look for index.php/index.html/index.htm as index file
        index index.php index.html index.htm;

        # this is specifically for wordpress
        # makes it possible to have url rewrites
        try_files $uri $uri/ /index.php?$args;
    }
    # default error pages
    # note that wp already catches most
    error_page 404 /404.html;
    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html/;
    }
    # here we have to let nginx know what to do with these php files
    # as html files are just send directly to the client
    location ~ \.php$ {
        # if the file is not there show a error : mynonexistingpage.php -> 404
        try_files \$uri =404;

        # pass to the php-fpm server
        fastcgi_pass 127.0.0.1:9000;
        # also for fastcgi try index.php
        fastcgi_index index.php;
        # some tweaking
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param SCRIPT_NAME \$fastcgi_script_name;
        fastcgi_buffer_size 128k;
        fastcgi_buffers 256 16k;
        fastcgi_busy_buffers_size 256k;
        fastcgi_temp_file_write_size 256k;
        include fastcgi_params;
		client_max_body_size 500M;
    }
}
" > $sitesAvailable$domain
		then
			echo -e $"There is an ERROR create $domain file"
			exit;
		else
			echo -e $"\nNew Virtual Host Created\n"
		fi

		### Add domain in /etc/hosts
		if ! echo "127.0.0.1	$domain" >> /etc/hosts
			then
				echo $"ERROR: Not able write to /etc/hosts"
				exit;
		else
				echo -e $"Host added to /etc/hosts file \n"
		fi

        ### Add domain in /mnt/c/Windows/System32/drivers/etc/hosts (Windows Subsytem for Linux)
		if [ -e /mnt/c/Windows/System32/drivers/etc/hosts ]
		then
			if ! echo -e "\r127.0.0.1       $domain" >> /mnt/c/Windows/System32/drivers/etc/hosts
			then
				echo $"ERROR: Not able to write in /mnt/c/Windows/System32/drivers/etc/hosts (Hint: Try running Bash as administrator)"
			else
				echo -e $"Host added to /mnt/c/Windows/System32/drivers/etc/hosts file \n"
			fi
		fi

		if [ "$owner" == "" ]; then
			chown -R $(whoami):nginx $rootDir
		else
			chown -R $owner:nginx $rootDir
		fi

		### enable website
		ln -s $sitesAvailable$domain $sitesEnable$domain

		### restart Nginx
		service nginx restart

		### show the finished message
		echo -e $"Complete! \nYou now have a new Virtual Host \nYour new host is: http://$domain \nAnd its located at $rootDir"
		exit;
	
		### check whether domain already exists
		if ! [ -e $sitesAvailable$domain ]; then
			echo -e $"This domain doesn't exist.\nPlease Try Another one"
			exit;
		elif [ "$action" == 'delete' ];
			### Delete domain in /etc/hosts
		then	newhost=${domain//./\\.}
			sed -i "/$newhost/d" /etc/hosts

			### Delete domain in /mnt/c/Windows/System32/drivers/etc/hosts (Windows Subsytem for Linux)
			if [ -e /mnt/c/Windows/System32/drivers/etc/hosts ]
			then
				newhost=${domain//./\\.}
				sed -i "/$newhost/d" /mnt/c/Windows/System32/drivers/etc/hosts
			fi

			### disable website
			rm $sitesEnable$domain

			### restart Nginx
			service nginx restart

			### Delete virtual host rules files
			#rm $sitesAvailable$domain
			
			### Delete SSL Certificate
			rm /etc/ssl/certs/$domain.crt
			rm /etc/pki/tls/private/$domain.key
			exit 0;
		fi

		### check if directory exists or not
		if [ -d $rootDir ] && [ "$action" != 'makecert' ]; then
			echo -e $"Delete host root directory at /var/www/WebProduction/$domain ? (y/n)"
			read deldir

			if [ "$deldir" == 'y' -o "$deldir" == 'Y' ] && [ "$action" != 'makecert' ]; then
				### Delete the directory
				rm -rf $rootDir
				echo -e $"Directory deleted"
			else
				echo -e $"Host directory remains"
			fi
		else
			echo -e $"Host directory not found. Ignored"
		fi

		### show the finished message
		echo -e $"Complete!\nYou just removed Virtual Host $domain"
		exit 0;
fi	
{
		### Replacing self-signed certificate
	if [ "$action" == 'makecert' ] && [ "$action" != 'delete' ]
			
						##### Begin Interrogation, You do not have the right to remain silent ###
						
									then while [ "$action" != 'delete' ]; do
													read -p "Have you placed your SSL certificate in /home/centos/newcerts while making sure it has a .crt file extension?" yn
											case $yn in
												[Yy]* ) break;;
												[Nn]* ) echo "Gosh dangit dale.." && exit 1;;
													* ) echo "Please answer yes or no.";;
																esac
													done;
													while [ "$action" != 'delete' ]; do
													read -p "Have you placed your SSL certificate CA in /home/centos/newcerts while making sure it has a .ca-bundle file extension? (Rename the file if it is .crt, .cert, etc)" yn
											case $yn in
												[Yy]* ) skipbundle=true && break;;
												[Nn]* ) echo "Oh.. So I either look like a Certificate Authority to you or.." && break;;
													* ) echo "Please answer yes or no.";;
																esac
													done;
													while [ "$skipbundle" != "true" ] && [ "$action" != 'delete' ]; do
													read -p "Did your SSL Certificate come with a CA Bundle or Intermediate Certificate File?" yn 
											case $yn in
												[Yy]* ) echo "FAIL, You were supposed to upload it. Try again." && exit 1;;
												[Nn]* ) echo "Ok, good. There's hope for you yet."&& CA_needed=false && break;;
													* ) echo "Please answer yes or no.";;
																esac
													 done;
													while [ "$action" != 'delete' ]; do
													read -p "Have you placed your SSL Private Key in /home/centos/newkeys while making sure it has a .key file extension?" yn
											case $yn in
												[Yy]* ) break 2;;
												[Nn]* ) echo "Is your name Morty by chance?" && exit 1;;
													* ) echo "Please answer yes or no.";;
																esac
													done;
		
		
			### If there is a CA Bundle 
		elif [ "$action" != 'delete' ];
	    then cp -Rfv /home/centos/newcerts/* /root/newcerts/ && chown -Rfv root.root /root/newcerts/ && cp -Rfv /home/centos/newkeys/* /root/newkeys/ && chown -Rfv root.root /root/newkeys/
			echo "Certificates and Keys have been moved into their staging directories at /root/newcerts and /root/newkeys"
			
		fi
}
	{
	if [ "$action" != 'delete' ];
				then echo "Please note, you have 3 seconds to stop the script at each of these 3 steps before action is taken."
	sleep 3
				find ~/newcerts -type f -name "*.crt" -not -name "$domain.crt" \
           -execdir mv -v {} $domain.crt \;
#			mv *.crt $domain.crt
			
				echo "SSL Certificates Processed"
				fi
	sleep 3		
			if [ "$CA_needed" = false ] && [ "$action" != 'delete' ]; 
				then mv $domain.crt /etc/ssl/certs && echo "SSL Certificate installed successfully without CA Bundle"
			
		elif [ "$CA_needed" != false ] && [ "$action" == 'makecert' ] && [ "$action" != 'delete' ];
			then echo "Preparing to Combine Certificate And CA Bundle"
					elif  [ "$CA_needed" != false ] && [ "$action" == 'makecert' ] && [ "$action" != 'delete' ];
						then find /root/newcerts -type f -name "*.ca-bundle" -not -name "$domain.ca-bundle" \
           -execdir mv -v {} $domain.ca-bundle \;
			elif [ "$action" != 'delete'  ];
					cat /root/newcerts/$domain.ca-bundle >> /root/newcerts/$domain.crt

		then
			echo "Certificates merged successfully"
				elif [ "$action" == 'makecert' ] && [ "$action" != 'delete' ];
					then mv /root/newcerts/$domain.crt /etc/ssl/certs
						elif [ "$action" == 'makecert' ] && [ "$action" != 'delete' ];
							then echo "Certificate and CA Bundle Installed Successfully"
				
				else echo "Make sure you've uploaded your certificate(s) and private key in the previously instructed formats"
				 
				 exit 1;
				 fi
#			mv *.crt $domain.crt
				 
					#mv *.ca.crt $domain.ca.crt && cat $domain.ca.crt >> $domain.crt && echo "Certificates merged successfully" && mv $domain.crt /etc/ssl/certs && echo "Certificate and CA Bundle Installed Successfully"
	
}	
	#fi
	sleep 2		
			echo "Placing Private Key"
	sleep 3	
	
	
{	
	if [ "$action" != 'delete' ] && [ "$action" == 'makecert' ];
	find ~/newkeys -type f -name "*.key" -not -name "$domain.key" \
           -execdir mv -v {} $domain.key \; && mv /root/newkeys/$domain.key /etc/pki/tls/private
#	mv *.key $domain.key && mv $domain.key /etc/pki/tls/private
	then echo "Private key installed successfully, check to see if the cert is working over HTTPS.. Or did you think I was going to handle that part too?" 			 
	         else 
			 
		echo "Something went wrong. Review this script to ensure it is current with your OS version or distribution and get your sh!t together."
	 exit 1;
       fi       
}
