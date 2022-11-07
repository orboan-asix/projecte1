#!/bin/bash

if [ -z "${USER}" ]
then
echo "Supervisor user is default (alumne)"
else
sed -ri "s/alumne/${USER}/g" /etc/supervisor/supervisord.conf
fi


if [ -z "${PASSWORD}" ]
then
echo "Supervisor password is default (alumne)"
else
sed -ri "s/alumne/${PASSWORD}/g" /etc/supervisor/supervisord.conf
fi

