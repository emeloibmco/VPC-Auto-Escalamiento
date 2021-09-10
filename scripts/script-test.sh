#!/bin/bash
sudo apt update
git clone https://github.com/CristianR11/load-test-app.git
cd load-test-app
sudo apt install -y nodejs npm
sudo npm install pm2@latest -g
npm i
pm2 start index.js
