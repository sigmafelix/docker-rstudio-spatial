FROM ubuntu:19.04

MAINTAINER Felix Song sigmafelix@hotmail.com

ENV DEBIAN_FRONTEND noninteractive
ENV CRAN_URL https://cloud.r-project.org/

ADD https://s3.amazonaws.com/rstudio-server/current.ver /tmp/ver

RUN set -e \
      && ln -sf /bin/bash /bin/sh

RUN set -e \
      && sed -i 's/archive.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list \
	  && sed -i 's/security.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list \
	  && sed -i 's/extras.ubuntu.com/mirror.kakao.com/g' /etc/apt/sources.list \
      && apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        apt-transport-https apt-utils ca-certificates gnupg \
      && echo "deb https://cloud.r-project.org/bin/linux/ubuntu disco-cran35/" \
        > /etc/apt/sources.list.d/r.list \
      && apt-key adv --keyserver keyserver.ubuntu.com \
        --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 \
	  && apt-get -y update \
      && apt-get -y dist-upgrade \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        curl libapparmor1 libclang-dev libedit2 libssl-dev libssl1.1 lsb-release \
        psmisc r-base sudo \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN  set -e \
      && apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
        libgdal-dev libgeos-dev libproj-dev libudunits2-dev \
		libcairo2-dev build-essential gcc gfortran libopenblas-dev \
      && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN  set -e \
      && apt-get -y update \
      && apt-get -y install --no-install-recommends --no-install-suggests \
		 jags \
	  && apt-get -y autoremove \
      && apt-get clean \
      && rm -rf /var/lib/apt/lists/*

RUN set -e \
      && ln -s /dev/stdout /var/log/syslog \
      && curl -S -o /tmp/rstudio.deb \
        https://download2.rstudio.org/server/bionic/amd64/rstudio-server-$(cut -f 1 -d - /tmp/ver)-amd64.deb \
      && apt-get -y install /tmp/rstudio.deb \
      && rm -rf /tmp/rstudio.deb /tmp/ver

RUN set -e \
      && useradd -m -d /home/rstudio -g rstudio-server rstudio \
      && echo rstudio:rstudio | chpasswd \
      && echo "r-cran-repos=${CRAN_URL}" >> /etc/rstudio/rsession.conf

RUN set -e \
	  && Rscript -e "install.packages('pacman')" \
	  && Rscript -e "install.packages(c('sf', 'sp', 'spdep', 'raster', 'gstat', 'automap', 'tmap', 'dplyr', 'plyr', 'tidyr', 'magrittr', 'lubridate', 'xtable', 'tidyverse', 'mice', 'caret', 'caretEnsemble', 'rjags', 'spBayes'), Ncpus = 8, dependencies = TRUE, INSTALL_opts = c('--no-lock')" 

EXPOSE 8787

ENTRYPOINT ["/usr/lib/rstudio-server/bin/rserver"]
CMD ["--server-daemonize=0", "--server-app-armor-enabled=0"]