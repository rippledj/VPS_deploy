#!/bin/bash
#
#
# VPS_remote_backup.sh
# Remote Backup Script
# Ripple Software Consulting
# GitHub: https://github.com/rippledj/VPS_deploy
# Author: Joseph Lee
# Email: joseph@ripplesoftware.ca
#
# Move the payload and main script to the server, and run remotely
echo "[Pushing changes to GitHub repository...]"
if [ -s payloads/id_rsa_github ]
then
    echo "[Starting to process GitHub repository update...]"
    # Make a ssh directory and set permissions
    mkdir /root/.ssh
    # Add the ssh identity file to root to configure connection to github
    echo "[Adding identify files to root...]"
    /bin/cp payloads/ssh_identity_file /root/.ssh/
    mv /root/.ssh/ssh_identity_file /root/.ssh/config
    chmod 0400 /root/.ssh/config
    echo "[Adding GitHub as known host to root...]"
    # Add github.com to the known_hosts file
    ssh-keyscan -H github.com >> /root/.ssh/known_hosts
    # Copy the id_rsa_github and id_rsa_github.pub to /root/.ssh directory
    echo "[Moving GitHub SSH keys to root...]"
    /bin/cp payloads/id_rsa_github /root/.ssh
    /bin/cp payloads/id_rsa_github.pub /root/.ssh
    # Modify permissions
    chmod 0400 /root/.ssh/id_rsa_github
    chmod 0400 /root/.ssh/id_rsa_github.pub
    # Copy the id_rsa_github and id_rsa_github.pub to /root/.ssh directory
    echo "[Adding GitHub SSH keys to root ssh agent...]"
    eval `ssh-agent -s`
    ssh-add /root/.ssh/id_rsa_github
    # For each repository listed in githubuser file
    while read -r -a githubuser
    do
      # Eliminate comments
      if [[ ${githubuser[0]:0:1} != "#" && ! -z "${githubuser[0]}" ]]; then
        # Clone the repo for the site to be installed
        echo "[Adding changes to GitHub repository...]"
        cd /var/www/html/${githubuser[0]}
        git add -A
        echo "[Commiting changes to GitHub repository...]"
        git commit -m "Auto commit from server on \$(date +\%m_\%d_\%Y)"
        echo "[Pushing commits to GitHub repository...]"
        git push origin master
        # Remove the ssh-agent deamon
        eval `ssh-agent -k`
        echo "[ssh-agent process killed...]"
        # Set permissions files for host domain
        echo "[Re-writing ownership...]"
        chown -R apache:apache /var/www/html/${githubuser[0]}
        echo "[Finished re-writing ownership...]"
      fi
    done < payloads/github_userdata
fi
echo "[VPS_deploy has finished pushing changes to GitHub repository...]"
#
# Clean up
#
# Clear the command line history
echo "[Removing command line history...]"
history -c
> /root/.bash_history
echo "[Command line history removed...]"
echo "[Removing SSH directory...]"
rm -rf /root/.ssh
echo "[SSH directory removed...]"
# Send a success exit code
exit 0
