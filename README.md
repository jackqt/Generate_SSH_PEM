# Generate_SSH_PEM
One Click to generate ssh pem file for login ssh with identity file like Amazon EC2 instance did.

That make system administrators to run it by specify user name, and then it will generate ssh private/public key automaticlly. 

After generate, the python SimpleHTTPServer will start up at default port (port: 8000). This allow admin to download the ssh private key at any client.

Finally, admin could login the server by the **identity file** of ssh command


## Prerequisite
Script was developped under CentOS, and *should* work under all the *NX system.

* To execute this script, the **root** user is needed

* This script will add the specify username into sudoer file of **/etc** path, so maybe failed if the OS has not the `/etc/sudoers.d` directory

* Script dependence `getent` to get entries from administrative database.


## Install & Usage
Please user below command to download and execute the script in your *NX system:

```
wget -O - https://raw.githubusercontent.com/jackqt/Generate_SSH_PEM/master/ssh_private.sh | bash
```

Script support command line options:

```
$ /path/to/ssh_private.sh -h
Usage: args [-h] [-u username]
-h means help
-u means specify username

```

It could be executed directly, and receive `username` argument to create system user and generate the ssh key

Finally you will see the below message to inform to download the pem file

```
$ /path/to/ssh_private.sh -u testuser
Copy & Past the below URL into browser to download the private key

	http://192.168.0.2:8000/testuser.pem
	
	http://127.0.0.1:8000/testuser.pem
	
Press Ctrl-c to terminate the web server
Serving HTTP on 0.0.0.0 port 8000 ...
```

For login remote server on client, please run the command with downloaded ssh private key:

```
ssh -i /path/to/testuser.pem testuser@remote-host
```