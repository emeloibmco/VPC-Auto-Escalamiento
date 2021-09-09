#!/bin/sh
git clone https://github.com/CristianR11/load-test-app.git
cd load-test-app
sudo apt update
sudo apt install -y nodejs npm
sudo npm install pm2@latest -g
npm i
pm2 start index.js