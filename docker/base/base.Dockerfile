FROM debian:bullseye-slim

ARG name=gg/discourse

ENV PG_MAJOR 13
ENV RUBY_ALLOCATOR /usr/lib/libjemalloc.so.1
ENV RAILS_ENV production

#LABEL maintainer="Sam Saffron \"https://twitter.com/samsaffron\""

RUN echo 2.0.`date +%Y%m%d` > /VERSION

RUN echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/bullseye-backports.list
RUN echo "debconf debconf/frontend select Teletype" | debconf-set-selections
RUN apt update && apt -y install gnupg sudo curl fping
RUN sh -c "fping proxy && echo 'Acquire { Retries \"0\"; HTTP { Proxy \"http://proxy:3128\";}; };' > /etc/apt/apt.conf.d/40proxy && apt update || true"
RUN apt-mark hold initscripts
RUN apt -y upgrade

RUN apt install -y locales locales-all
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

RUN curl --silent --location https://deb.nodesource.com/setup_16.x | sudo bash -
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list
RUN apt -y update

RUN apt -y install --no-install-recommends git rsyslog logrotate cron ssh-client less
RUN apt -y install autoconf build-essential ca-certificates rsync \
                       libxslt-dev libcurl4-openssl-dev \
                       libssl-dev libyaml-dev libtool \
                       libpcre3 libpcre3-dev zlib1g zlib1g-dev \
                       libxml2-dev gawk parallel \
                       libpq-dev libreadline-dev \
                       anacron wget \
                       psmisc whois brotli libunwind-dev \
                       libtcmalloc-minimal4 cmake \
                       pngcrush pngquant

RUN sed -i -e 's/start -q anacron/anacron -s/' /etc/cron.d/anacron
RUN sed -i.bak 's/$ModLoad imklog/#$ModLoad imklog/' /etc/rsyslog.conf
RUN sed -i.bak 's/module(load="imklog")/#module(load="imklog")/' /etc/rsyslog.conf
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN sh -c "test -f /sbin/initctl || ln -s /bin/true /sbin/initctl"
RUN cd / &&\
    apt -y install runit socat &&\
    mkdir -p /etc/runit/1.d &&\
    apt clean &&\
    rm -f /etc/apt/apt.conf.d/40proxy &&\
    locale-gen en_US &&\
    apt install -y nodejs yarn &&\
    npm install -g terser &&\
    npm install -g uglify-js

# Adiciona os scripts de instalação da pasta ./scripts
ADD ./scripts /tmp/scripts

# Altera as permissões da pasta /tmp
RUN chmod +x -R /tmp

RUN /tmp/scripts/install-imagemagick.sh
RUN /tmp/scripts/install-jemalloc.sh
RUN /tmp/scripts/install-nginx.sh
RUN /tmp/scripts/install-oxipng.sh
RUN /tmp/scripts/install-redis.sh
RUN /tmp/scripts/install-ruby.sh

RUN echo 'gem: --no-document' >> /usr/local/etc/gemrc &&\
    gem update --system

RUN gem install bundler pups --force &&\
    mkdir -p /pups/bin/ &&\
    ln -s /usr/local/bin/pups /pups/bin/pups

# ADD thpoff.c /src/thpoff.c
# RUN gcc -o /usr/local/sbin/thpoff /src/thpoff.c && rm /src/thpoff.c

# clean up for docker squash
# RUN rm -fr /usr/share/man &&\
#     rm -fr /usr/share/doc &&\
#     rm -fr /usr/share/vim/vim74/doc &&\
#     rm -fr /usr/share/vim/vim74/lang &&\
#     rm -fr /usr/share/vim/vim74/spell/en* &&\
#     rm -fr /usr/share/vim/vim74/tutor &&\
#     rm -fr /usr/local/share/doc &&\
#     rm -fr /usr/local/share/ri &&\
#     rm -fr /usr/local/share/ruby-build &&\
#     rm -fr /var/lib/apt/lists/* &&\
#     rm -fr /root/.gem &&\
#     rm -fr /root/.npm &&\
#     rm -fr /tmp/*

# RUN rm -f /etc/service

# COPY etc/ /etc
# COPY sbin/ /sbin