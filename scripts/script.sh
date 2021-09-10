#!bin/bash
cd $HOME
wget https://raw.githubusercontent.com/emeloibmco/VPC-Auto-Escalamiento/main/scripts/script-test.sh
chmod +x script-test.sh
./script-test.sh >> ./script.log 2>&1
