#!/bin/bash

# image
sudo docker image pull networkop/cx:4.4.0

# alias
cat <<-eof >> /home/cloudos/.bashrc

alias cumulus='sudo docker exec -it cumulus'
eof
