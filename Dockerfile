FROM centos:8

LABEL summary="Image to run oc rsync" 
LABEL description="A simple container to rsync pvc between clusters"

ENV \
    RSYNC_DEST=/mnt/pvc-data \
    USER=transfer \
    UID=1001 \
    OC_CLIENT=openshift-client-linux.tar.gz

ADD https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/$OC_CLIENT /tmp

RUN \
  useradd -m -u $UID $USER && \
  mkdir -p $RSYNC_DEST && \
  chown 1001:0 $RSYNC_DEST && \
  chmod g=u $RSYNC_DEST && \
  yum install rsync -y && \
  yum clean all && \
  tar -C /usr/bin -xzf /tmp/$OC_CLIENT oc kubectl && \
  rm /tmp/$OC_CLIENT

COPY entrypoint.sh /usr/local/bin

VOLUME $RSYNC_DEST

USER $UID

ENTRYPOINT ["entrypoint.sh"]

#CMD [ "/bin/sh", "-c" , "while true; do sleep 10; done" ]
