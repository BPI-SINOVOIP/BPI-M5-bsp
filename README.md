## **BPI-M5-bsp**
Banana Pi M5 board bsp (u-boot 2015.1 & Kernel 4.9.236)

----------
**Prepare**

[Install Docker Engine](https://docs.docker.com/engine/install/) on your platform.

Get the docker image from [Sinovoip Docker Hub](https://hub.docker.com/r/sinovoip/bpi-build-linux-4.4/) , Build the source code with this docker environment.

Download source code

    $ git clone https://github.com/BPI-SINOVOIP/BPI-M5-bsp
    $ git submodule update --init --recursive

 **Build**

Build all bsp packages, please run

`#./build.sh 1`

Target download packages in SD/bpi-m5 after build. Please check the build.sh and Makefile for detail

**Install**

Get the image from [bpi](http://wiki.banana-pi.org/Banana_Pi_BPI-M5#Image_Release) and download it to the SD card. After finish, insert the SD card to PC

    # ./build.sh 6

Choose the type, enter the SD dev, and confirm yes, all the build packages will be installed to target SD card.
