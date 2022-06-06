FROM gg/discourse:0.1

ADD thpoff.c /src/thpoff.c
RUN gcc -o /usr/local/sbin/thpoff /src/thpoff.c && rm /src/thpoff.c

# clean up for docker squash
RUN rm -fr /usr/share/man &&\
    rm -fr /usr/share/doc &&\
    rm -fr /usr/share/vim/vim74/doc &&\
    rm -fr /usr/share/vim/vim74/lang &&\
    rm -fr /usr/share/vim/vim74/spell/en* &&\
    rm -fr /usr/share/vim/vim74/tutor &&\
    rm -fr /usr/local/share/doc &&\
    rm -fr /usr/local/share/ri &&\
    rm -fr /usr/local/share/ruby-build &&\
    rm -fr /var/lib/apt/lists/* &&\
    rm -fr /root/.gem &&\
    rm -fr /root/.npm &&\
    rm -fr /tmp/*

RUN rm -f /etc/service

COPY etc/ /etc
COPY sbin/ /sbin

RUN useradd discourse -s /bin/bash -m -U &&\
    install -dm 0755 -o discourse -g discourse /var/www/discourse &&\
    sudo -u discourse git clone --depth 1 https://github.com/discourse/discourse.git /var/www/discourse &&\
    sudo -u discourse git -C /var/www/discourse remote set-branches --add origin tests-passed
