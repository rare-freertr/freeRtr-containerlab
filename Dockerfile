FROM debian:sid
LABEL org.opencontainers.image.authors="frederic.loui@renater.fr"

WORKDIR /root

COPY ./install-deps.sh /root
COPY ./install-rtr.sh /root
COPY ./install-clean.sh /root

ENV DEBUG=false
ENV INIT_VRF=false
# Set default dataplane type (pcapInt or p4emu)
ENV DATAPLANE_TYPE=pcapInt

RUN ./install-deps.sh
RUN ./install-rtr.sh
RUN ./install-clean.sh

COPY ./functions.sh /rtr
COPY ./hwdet-init.sh /rtr
COPY ./hwdet-mgmt.sh /rtr
COPY ./hwdet-dataplane.sh /rtr
COPY ./start-rtr.sh /rtr
COPY ./default.cfg /rtr/rtr-sw.txt

CMD /rtr/start-rtr.sh
