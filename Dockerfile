FROM ubuntu:22.04

RUN apt-get update && \
    apt-get install -y unzip procps && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /opt

COPY downloads/ /tmp/downloads/

# Install SAP JVM
RUN JVM_FILE=$(find /tmp/downloads -name "sapjvm-*.zip" | head -1) && \
    unzip -q "$JVM_FILE" -d /opt

# Normalize JVM path
RUN JVM_DIR=$(find /opt -maxdepth 1 -type d -name "sapjvm*" | head -1) && \
    mv "$JVM_DIR" /opt/sapjvm

ENV JAVA_HOME=/opt/sapjvm
ENV PATH=$JAVA_HOME/bin:$PATH

# Install SCC Portable
RUN mkdir -p /opt/scc && \
    SCC_FILE=$(find /tmp/downloads -name "sapcc-*.tar.gz" | head -1) && \
    tar -xzf "$SCC_FILE" -C /opt/scc

# Cleanup build artifacts
RUN rm -rf /tmp/downloads

WORKDIR /opt/scc

EXPOSE 8443

CMD ["./go.sh"]