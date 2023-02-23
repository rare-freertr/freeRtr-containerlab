FROM debian:sid
MAINTAINER Frederic LOUI <frederic.loui@@renater.fr>

WORKDIR /root

COPY ./install-deps.sh /root
COPY ./install-rtr.sh /root
COPY ./install-clab.sh /root
COPY ./install-clean.sh /root


RUN ./install-deps.sh
RUN ./install-rtr.sh
RUN ./install-clab.sh /rtr
RUN ./install-clean.sh

COPY ./hwdet-init.sh /rtr
COPY ./start-rtr.sh /rtr
COPY ./default.cfg /rtr/rtr-sw.txt

CMD /rtr/start-rtr.sh
