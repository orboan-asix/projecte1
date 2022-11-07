#!/bin/bash

if [ -z "${USER}" ]
then
user=alumne
else
user=$USER
fi

if [ -z "${PASSWORD}" ]
then
pwd=alumne
else
pwd=$PASSWORD
fi

# Creating the new user only if it does not exist
ret=false
getent passwd $user >/dev/null 2>&1 && ret=true

if $ret; then
echo "user already exists";
else

adduser $user --home /home/$user --shell /bin/bash --uid 1000 --gid 100 --quiet
\cp -r /resources/config/.bash_profile /home/$user
\cp -r /resources/config/.bashrc /home/$user
chown 1000:100 -R /home/$user
# Comments supose $user is user
# Setting password for the 'user' user
echo "${user}:${pwd}" | chpasswd
# Add 'user' user to sudoers
mkdir -p /etc/sudoers.d
echo "${user}  ALL=(ALL)  NOPASSWD: ALL" > /etc/sudoers.d/$user
echo "user created"
fi
