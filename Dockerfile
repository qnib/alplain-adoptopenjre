ARG DOCKER_REGISTRY=docker.io
ARG DOCKER_IMG_TAG=":2022-03-24.0"
ARG DOCKER_IMG_HASH=""
FROM ${DOCKER_REGISTRY}/qnib/alplain-init${DOCKER_IMG_TAG}${DOCKER_IMG_HASH}

# force encoding
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"

RUN apk add --no-cache cyrus-sasl \
 && apk --no-cache upgrade \
 && apk add --no-cache nss git mercurial subversion openssh-client bash curl procps xz
RUN \
  # install glibc and zlib for adoptopenjdk && \
  # See https://github.com/AdoptOpenJDK/openjdk-docker/blob/ce8b120411b131e283106ab89ea5921ebb1d1759/8/jdk/alpine/Dockerfile.hotspot.releases.slim#L24-L54 && \
    apk add --no-cache --virtual .build-deps curl binutils && \
    GLIBC_VER="2.29-r0" && \
    ALPINE_GLIBC_REPO="https://github.com/sgerrand/alpine-pkg-glibc/releases/download" && \
    GCC_LIBS_URL="https://archive.archlinux.org/packages/g/gcc-libs/gcc-libs-9.1.0-2-x86_64.pkg.tar.xz" && \
    GCC_LIBS_SHA256=91dba90f3c20d32fcf7f1dbe91523653018aa0b8d2230b00f822f6722804cf08 && \
    ZLIB_URL="https://archive.archlinux.org/packages/z/zlib/zlib-1%3A1.2.11-3-x86_64.pkg.tar.xz" && \
    ZLIB_SHA256=17aede0b9f8baa789c5aa3f358fbf8c68a5f1228c5e6cba1a5dd34102ef4d4e5 && \
    curl -LfsS https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub && \
    SGERRAND_RSA_SHA256="823b54589c93b02497f1ba4dc622eaef9c813e6b0f0ebbb2f771e32adf9f4ef2" && \
    echo "${SGERRAND_RSA_SHA256} */etc/apk/keys/sgerrand.rsa.pub" | sha256sum -c - && \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-${GLIBC_VER}.apk > /tmp/glibc-${GLIBC_VER}.apk && \
    apk add /tmp/glibc-${GLIBC_VER}.apk && \
    curl -LfsS ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk > /tmp/glibc-bin-${GLIBC_VER}.apk && \
    apk add /tmp/glibc-bin-${GLIBC_VER}.apk && \
    curl -Ls ${ALPINE_GLIBC_REPO}/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk > /tmp/glibc-i18n-${GLIBC_VER}.apk && \
    apk add /tmp/glibc-i18n-${GLIBC_VER}.apk && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true && \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh && \
    curl -LfsS ${GCC_LIBS_URL} -o /tmp/gcc-libs.tar.xz && \
    echo "${GCC_LIBS_SHA256} */tmp/gcc-libs.tar.xz" | sha256sum -c - && \
    mkdir /tmp/gcc && \
    tar -xf /tmp/gcc-libs.tar.xz -C /tmp/gcc && \
    mv /tmp/gcc/usr/lib/libgcc* /tmp/gcc/usr/lib/libstdc++* /usr/glibc-compat/lib && \
    strip /usr/glibc-compat/lib/libgcc_s.so.* /usr/glibc-compat/lib/libstdc++.so* && \
    curl -LfsS ${ZLIB_URL} -o /tmp/libz.tar.xz && \
    echo "${ZLIB_SHA256} */tmp/libz.tar.xz" | sha256sum -c - && \
    mkdir /tmp/libz && \
    tar -xf /tmp/libz.tar.xz -C /tmp/libz && \
    mv /tmp/libz/usr/lib/libz.so* /usr/glibc-compat/lib && \
    apk del --purge .build-deps glibc-i18n && \
    rm -rf /tmp/*.apk /tmp/gcc /tmp/gcc-libs.tar.xz /tmp/libz /tmp/libz.tar.xz /var/cache/apk/* && \
  # end installing adoptopenjre  && \
  curl --fail --location --silent --show-error 'https://github.com/AdoptOpenJDK/openjdk13-binaries/releases/download/jdk-13.0.2%2B8/OpenJDK13U-jre_x64_linux_hotspot_13.0.2_8.tar.gz' --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/gocd-jre/bin