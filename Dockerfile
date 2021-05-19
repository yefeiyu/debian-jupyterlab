# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# https://hub.docker.com/_/debian
ARG BASE_CONTAINER=debian:latest
FROM $BASE_CONTAINER

LABEL maintainer="xxmm <yefeiyu@gmail.com>"
ARG NB_UID="1000"
ARG NB_GID="100"
ARG NB_USER="xx"
ARG NB_PASSWD="password"

####ROOT#########################################
USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
# without this builds on docker hub get stuck with interactive keyboard selection prompt
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    build-essential \
    emacs \
    vim-gtk \
    git \
    inkscape \
    jed \
    libsm6 \
    libxext-dev \
    libxrender1 \
    lmodern \
    netcat \
    pandoc \
    python-dev \
#   texlive-fonts-extra \
    texlive-fonts-recommended \
    texlive-generic-recommended \
    texlive-latex-base \
    texlive-latex-extra \
    texlive-xetex \
    tzdata \
    unzip \
    nano \
    ffmpeg \
    curl \
    fonts-ipafont-gothic \
    fonts-ipafont-mincho \
    w3m \
    openssh-server \
    redis-server \
    tree \
    autoconf \
    automake \
    autotools-dev \
    dpkg-dev \
    gnupg \
    imagemagick \
    ispell \
    libacl1-dev \
    libasound2-dev \
    libcanberra-gtk3-module \
    liblcms2-dev \
    libdbus-1-dev \
    libgif-dev \
    libgnutls28-dev \
    libgpm-dev \
    libgtk-3-dev \
    libjansson-dev \
    libjpeg-dev \
    liblockfile-dev \
    libm17n-dev \
    libmagick++-6.q16-dev \
    libncurses5-dev \
    libotf-dev \
    libpng-dev \
    librsvg2-dev \
    libselinux1-dev \
    libtiff-dev \
    libxaw7-dev \
    libxml2-dev \
    openssh-client \
    texinfo \
    xaw3dg-dev \
    zlib1g-dev \
    xfce4 \
    xfce4-goodies \
    tightvncserver \
    procps \
    bash \
    coreutils \
    openssl \
    x11vnc \
    xvfb \
    xterm \
    fluxbox \
    xorg \
    openbox \
    vnc4server \
    autocutsel \
    lynx \
    net-tools \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
 
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    NB_USER=$NB_USER \
    NB_PASSWD=$NB_PASSWD

####USER###########################################
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Copy a script that we will use to correct permissions after running certain commands
COPY fix-permissions /usr/local/bin/fix-permissions
RUN chmod a+rx /usr/local/bin/fix-permissions

# Enable prompt color in the skeleton .bashrc before creating the default NB_USER
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc

# Create NB_USER wtih name xx user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME && \
    fix-permissions "$(dirname $CONDA_DIR)"

# Create SSH remote connection by openssh-server
# Use this line define $PASSWD.
RUN echo "${NB_USER}:${NB_PASSWD}" | chpasswd && \
    echo "${NB_USER}    ALL=(ALL:ALL) ALL" >> /etc/sudoers && \
    echo 'PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/opt/conda/bin:/opt/conda/sbin"' >> /home/${NB_USER}/.profile

RUN mkdir /var/run/sshd && \ 
    sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    # SSH login fix. Otherwise user is kicked off after login
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile
EXPOSE 22
# CMD ["/usr/sbin/sshd", "-D"]

####USER###############################################
USER $NB_USER
WORKDIR $HOME
ARG PYTHON_VERSION=default

# Install conda as xx and check the md5 sum provided on the download site
ENV MINICONDA_VERSION=4.7.12.1 \
    MINICONDA_MD5=81c773ff87af5cfac79ab862942ab6b3 \
    CONDA_VERSION=4.7.12

RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "${MINICONDA_MD5} *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "conda ${CONDA_VERSION}" >> $CONDA_DIR/conda-meta/pinned && \
    conda config --system --prepend channels conda-forge && \
    conda config --system --set auto_update_conda false && \
    conda config --system --set show_channel_urls true && \
    if [ ! $PYTHON_VERSION = 'default' ]; then conda install --yes python=$PYTHON_VERSION; fi && \
    conda list python | grep '^python ' | tr -s ' ' | cut -d '.' -f 1,2 | sed 's/$/.*/' >> $CONDA_DIR/conda-meta/pinned && \
    conda install --quiet --yes conda && \
    conda install --quiet --yes pip && \
    conda update --all --quiet --yes && \
    conda clean --all -f -y && \
    rm -rf /home/$NB_USER/.cache/yarn

# Install Tini
RUN conda install --quiet --yes 'tini=0.18.0' && \
    conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned && \
    conda clean --all -f -y && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
RUN conda install --quiet --yes \
    'notebook=6.0.3' \
    'jupyterhub=1.1.0' \
    'jupyterlab=1.2.5' \
    'beautifulsoup4=4.8.*' \
    'conda-forge::blas=*=openblas' \
    'bokeh=1.4.*' \
    'cloudpickle=1.2.*' \
    'cython=0.29.*' \
    'dask=2.9.*' \
    'dill=0.3.*' \
    'h5py=2.10.*' \
    'hdf5=1.10.*' \
    'ipywidgets=7.5.*' \
    'matplotlib-base=3.1.*' \
    'numba=0.48.*' \
    'numexpr=2.7.*' \
    'pandas=0.25.*' \
    'patsy=0.5.*' \
    'protobuf=3.11.*' \
    'scikit-image=0.16.*' \
    'scikit-learn=0.22.*' \
    'scipy=1.4.*' \
    'seaborn=0.9.*' \
    'sqlalchemy=1.3.*' \
    'statsmodels=0.11.*' \
    'sympy=1.5.*' \
    'vincent=0.4.*' \
    'xlrd' \
    'cmake' \
    'notedown' \
    'virtualenv' \
    'openpyxl' \
    'tabulate' \
    && conda update -n base conda --quiet --yes \
    && \
    conda clean --all -f -y && \
    # Activate ipywidgets extension in the environment that runs the notebook server
    jupyter nbextension enable --py widgetsnbextension --sys-prefix && \
    # Also activate ipywidgets extension for JupyterLab
    # Check this URL for most recent compatibilities
    # https://github.com/jupyter-widgets/ipywidgets/tree/master/packages/jupyterlab-manager
    jupyter labextension install @jupyter-widgets/jupyterlab-manager@^1.0.1 --no-build && \
    jupyter labextension install jupyterlab_bokeh@1.0.0 --no-build && \
    jupyter lab build && \
    npm cache clean --force && \
    jupyter notebook --generate-config && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn && \
    rm -rf /home/$NB_USER/.node-gyp && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

EXPOSE 8888

# Configure container startup
#ENTRYPOINT ["tini", "-g", "--"]
#CMD ["start-notebook.sh"]

# Install facets which does not have a pip or conda package at the moment
RUN cd /tmp && \
    git clone https://github.com/PAIR-code/facets.git && \
    cd facets && \
    jupyter nbextension install facets-dist/ --sys-prefix && \
    cd && \
    rm -rf /tmp/facets && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
RUN MPLBACKEND=Agg python -c "import matplotlib.pyplot" && \
    fix-permissions /home/$NB_USER

# Setup work directory for backward-compatibility and jn for notebook
RUN mkdir /home/$NB_USER/work && \
    mkdir /home/$NB_USER/jn && \
    fix-permissions /home/$NB_USER/work && \
    fix-permissions /home/$NB_USER/jn && \
    echo "c.NotebookApp.notebook_dir = '/home/$NB_USER/jn'">>/home/$NB_USER/.jupyter/jupyter_notebook_config.py

RUN cd /home/$NB_USER \
    && sed -i 's/#alias/alias/' .bashrc  \
    && echo "alias lla='ls -al'" 		>> .bashrc \
    && echo "alias llt='ls -ltr'"  		>> .bashrc \
    && echo "alias llta='ls -altr'" 	>> .bashrc \
    && echo "alias llh='ls -lh'" 		>> .bashrc \
    && echo "alias lld='ls -l|grep ^d'" >> .bashrc \
    && echo "alias hh=history" 			>> .bashrc \
    && echo "alias hhg='history|grep -i" '"$@"' "'" >> .bashrc

# Copy local files as late as possible to avoid cache busting
####root############################################
USER root
COPY start.sh /usr/local/bin/
COPY start-notebook.sh /usr/local/bin/
COPY start-singleuser.sh /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/
COPY set_root_pw.sh /usr/local/bin/
COPY run.sh /usr/local/bin/
RUN chmod a+rx /usr/local/bin/* && \
    fix-permissions /usr/local/bin  && \
    fix-permissions /etc/jupyter/

####root############################################
# Create and configure the VNC user
ARG VNCPASS
ENV VNCPASS ${VNCPASS:-secret}
#NV VNCPASSWD="password"

#XPOSE 80
EXPOSE 5900

COPY main.sh /usr/local/bin

####USER############################################
USER $NB_USER
VOLUME $HOME
# Configure container startup
#ENTRYPOINT ["tini", "-g", "--"]
#CMD ["start-notebook.sh"]
# ENTRYPOINT /usr/bin/vncserver && while true; do sleep 30; done
#ENTRYPOINT /usr/local/bin/run.bash

