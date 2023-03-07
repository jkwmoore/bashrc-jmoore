#!/bin/bash

# Clone the repository to the user's home directory first.
cd ~/bashrc-jmoore && git pull > /dev/null 2>&1 && 
echo -e "##################################\nCustom bashrc updated from Github.\n##################################" || 
echo -e "################################\nCustom bashrc git update failed.\n################################"
           
if [ $? -eq 0 ]; then

  # Check if the lines are already in the .bashrc file
  if ! grep -Fxq ". ~/bashrc-jmoore/bashrc" ~/.bashrc
  then
    # If not, add them to the .bashrc file
    echo -e "\n# Load custom bashrc\n. ~/bashrc-jmoore/bashrc" >> ~/.bashrc
  fi

  if ! grep -Fxq ". ~/bashrc-jmoore/bash_aliases" ~/.bashrc
  then
    # If not, add them to the .bashrc file
    echo -e "\n# Load custom bash aliases\n. ~/bashrc-jmoore/bash_aliases" >> ~/.bashrc
  fi

  if ! grep -Fq "~/bashrc-jmoore/bash-setup.sh" ~/.bashrc
  then
    # If not, add them to the .bashrc file
    echo -e "\n# Before enabling, check if git pull + SSH agent forwarding causes high CPU." >> ~/.bashrc
    echo -e "# Load custom bashrc setup script\n#if [[ \$- == *i* ]]; then\n#    ~/bashrc-jmoore/bash-setup.sh \n#fi" >> ~/.bashrc
  fi

else
  echo "Error: Git clone failed, setup or update aborted."
fi
