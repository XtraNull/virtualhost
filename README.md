Virtualhost Manage Script
===========

Bash Script to allow create or delete apache/nginx virtual hosts on Ubuntu on a quick way.

## Installation ##
git clone https://github.com/XtraNull/virtualhost.git
1. Download the script
2. move to the shell script to the /root folder 
3. Apply permission to execute (you can only execute as root):

```
$ chmod +x /path/to/virtualhost.sh
```

## Usage ##

Basic command line syntax:

```bash
$ sudo sh /path/to/virtualhost.sh [create | delete | makecert] [domain] [optional host_dir]
```

With script installed on /usr/local/bin

```bash
$ sudo virtualhost [create | delete | makecert] [domain] [optional host_dir]
```
