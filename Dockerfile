############################################################
# Dockerfile to build Epictreasure container
# Based on Ubuntu
############################################################

FROM ubuntu:20.04
MAINTAINER Maintainer Cory Duplantis

COPY et_setup.sh /tmp/
RUN /bin/bash -c /tmp/et_setup.sh

ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8     
