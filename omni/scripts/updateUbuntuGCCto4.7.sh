#!/bin/bash

sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
sudo apt-get install gcc-4.7 g++-4.7

sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.7 60 \
                         --slave /usr/bin/g++ g++ /usr/bin/g++-4.7
g++ --version
