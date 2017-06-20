FROM debian:jessie

MAINTAINER Tim Robinson <tim@panubo.com>

ENV SENSU_VERSION 0.26.5
ENV SENSU_PKG_VERSION 2

# Some dependencies
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get -y install curl sudo bc python-jinja2 lvm2 btrfs-tools && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

# Setup sensu package repo & Install Sensu
RUN export DEBIAN_FRONTEND=noninteractive && \
  curl http://repositories.sensuapp.org/apt/pubkey.gpg | apt-key add - && \
  echo "deb     http://repositories.sensuapp.org/apt sensu main" | tee /etc/apt/sources.list.d/sensu.list && \
  apt-get update && \
  apt-get install sensu=${SENSU_VERSION}-${SENSU_PKG_VERSION} && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \
  echo "EMBEDDED_RUBY=true" > /etc/default/sensu

RUN curl -L https://github.com/voltgrid/voltgrid-pie/archive/v1.tar.gz | tar -C /usr/local/bin --strip-components 1 -zxf - voltgrid-pie-1/voltgrid.py

# Install lite requirements
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y curl monitoring-plugins-basic jq python && \
    apt-get -y autoremove && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY lite /lite/

# Install some plugins/checks
RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get install -y build-essential && \
  /opt/sensu/embedded/bin/gem install \
  sensu-plugins-disk-checks \
  sensu-plugins-memory-checks \
  sensu-plugins-load-checks \
  sensu-plugins-kubernetes \
  sensu-plugins-ssl \
  sensu-plugins-aws \
  sensu-plugins-http \
  filesize \
  --no-rdoc --no-ri && \
  apt-get remove -y build-essential && apt-get -y autoremove && apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH=/opt/sensu/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin TMPDIR=/var/tmp HOME=/opt/sensu
ENV LOGLEVEL=info SENSU_CLIENT_SUBSCRIPTIONS=test

# Add custom checks and scripts
ADD register-result /register-result
ADD check-lvmthin.rb /opt/sensu/embedded/bin/check-lvmthin.rb
ADD check-btrfs.rb /opt/sensu/embedded/bin/check-btrfs.rb

# Add config files
ADD voltgrid.conf /usr/local/etc/voltgrid.conf
ADD config.json /etc/sensu/config.json
ADD client.json /etc/sensu/conf.d/client.json
ADD sudoers /etc/sudoers.d/sensu

ADD entry.sh /
ENTRYPOINT ["/entry.sh", "/usr/local/bin/voltgrid.py"]
CMD ["/opt/sensu/bin/sensu-client", "-c", "/etc/sensu/config.json", "-d", "/etc/sensu/conf.d", "-e", "/etc/sensu/extensions", "-L", "warn"]

ENV BUILD_VERSION 0.26.5-6
