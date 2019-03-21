FROM node:8-stretch as builder

# Python
RUN apt-get update \
    && apt-get install -y python \ 
    && apt-get clean && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/* 

# Prepare project dirs and add a user account
RUN adduser --disabled-password --gecos '' theia && \
  adduser theia sudo && \
  echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers;

#Theia
##Needed for node-gyp, nsfw build
RUN apt-get update && apt-get install -y python build-essential

#RUN chmod g+rw /home && \
  # Workspace folder
#  mkdir -p /home/project && \
  # System folder
#  mkdir -p /home/theia && \
#  chown -R theia:theia /home/theia && \
#  chown -R theia:theia /home/project;

# Build theia
#USER theia
WORKDIR /home/theia
ADD package.json ./package.json
RUN yarn --cache-folder ./ycache && rm -rf ./ycache
RUN NODE_OPTIONS="--max_old_space_size=4096" yarn theia build

FROM node:8-stretch
WORKDIR /home/theia

COPY --from=builder /home/theia .

# Install python language server
RUN apt-get update \
    && apt-get install -y python3 python3-dev python3-pip \ 
    && apt-get clean && rm -rf /var/cache/apt/* && rm -rf /var/lib/apt/lists/* && rm -rf /tmp/*
RUN rm /usr/bin/python && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    ln -s /usr/bin/pip3 /usr/bin/pip
RUN pip install \
    python-language-server \
    flake8 \
    autopep8 \
    futures \
    configparser

VOLUME /workspace

EXPOSE 3000
ENV SHELL /bin/bash
ENTRYPOINT [ "yarn", "theia", "start", "/workspace", "--hostname=0.0.0.0" ]
