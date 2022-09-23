# written 2022-09-20


# taking the latest image

# Sep. 20 2022
FROM jupyter/r-notebook:r-4.1.3


LABEL maintainer="AIfA Jupyter Project <ocordes@astro.uni-bonn.de>"

# Do here all steps as root
USER root

# necessary for apt-key
RUN apt update
RUN apt-get install -y gnupg2

# add ownloud
RUN sh -c "echo 'deb http://download.opensuse.org/repositories/isv:/ownCloud:/desktop/Ubuntu_20.04/ /' > /etc/apt/sources.list.d/isv:ownCloud:desktop.list"
RUN wget -nv https://download.opensuse.org/repositories/isv:ownCloud:desktop/Ubuntu_20.04/Release.key -O Release.key

RUN apt-key add - < Release.key

# add sciebo
RUN wget -nv https://www.sciebo.de/install/linux/Ubuntu_22.04/Release.key -O - | apt-key add -
RUN echo 'deb https://www.sciebo.de/install/linux/Ubuntu_22.04/ /' | tee -a /etc/apt/sources.list.d/sciebo.list


# Run assemble scripts! These will actually build the specification
# in the repository into the image.
RUN apt-get -qq update && \
  apt-get install --yes --no-install-recommends openssh-client \
        less \
        inotify-tools \
        owncloud-client \
        sciebo-client \
        sextractor \
        scamp \
        swarp \
        zip \
        iputils-ping \
        texlive-latex-base \
        texlive-latex-recommended \
        texlive-science \
        texlive-latex-extra \
        texlive-fonts-recommended \
        texlive-lang-german \
        texlive-bibtex-extra \
        texlive-extra-utils \
        texlive-fonts-extra \
        texlive-fonts-extra-links \
        texlive-fonts-recommended \
        texlive-formats-extra \
        texlive-humanities \
        texlive-luatex \
        texlive-metapost \
        texlive-pictures \
        texlive-pstricks \
        texlive-publishers \
        cm-super \
        biber \
        lmodern \
        dvipng \
        ghostscript \
        latexmk \
        ffmpeg \
        imagemagick && \
  apt-get install --yes --no-install-recommends manpages man-db coreutils lsb-release lsb-core nano vim emacs tree  && \
  apt-get -qq purge && \
  apt-get -qq clean && \
  rm -rf /var/lib/apt/lists/*

COPY policy.xml /etc/ImageMagick-6/


# use this for debugging in the case of UID/GID problems
COPY start.sh /usr/local/bin/start.sh
RUN chmod 755 /usr/local/bin/start.sh

# switch back to jovyan to install conda packages

USER $NB_UID


# The conda-forge channel is already present in the system .condarc file, so there is no need to
# add a channel invocation in any of the next commands.

# install jupyterlab
RUN conda install jupyterlab=3.3.2  --yes && \
        # Add nbgrader 0.6.1 to the image
        # More info at https://nbgrader.readthedocs.io/en/stable/
        # conda install nbgrader=0.6.1 --yes &6 \
        # Add the notebook extensions
        conda install jupyter_contrib_nbextensions --yes && \

	# add extensions by conda
        conda install ipywidgets ipyevents ipympl jupyterlab_latex --yes && \
        conda install version_information jupyter-archive>=3.3.0 jupyterlab-git --yes && \

        # jupyterlab extensions

        # topbar / logout button
        pip install jupyterlab-topbar jupyterlab-logout && \

        # memory display in bottom line
        conda install nbresuse && \

	# theme toggling extension
        # interactive widgets
        # matplotlib extension
        # jupyter classic extensions

        jupyter labextension install jupyterlab-theme-toggle @jupyter-widgets/jupyterlab-manager jupyter-matplotlib@ --no-build && \
        jupyter nbextension enable --py widgetsnbextension && \


	# compile all extensions
        jupyter lab build --debug && \


	# install the spellchecker and latex extension
        conda install jupyterlab-spellchecker jupyterlab-latex && \

	# apply the latex configuration

        echo "" >> /etc/jupyter/jupyter_notebook_config.py && \
        echo "c.LatexConfig.latex_command = 'pdflatex'" >> /etc/jupyter/jupyter_notebook_config.py && \
        echo "c.LatexConfig.bib_command = 'biber'" >> /etc/jupyter/jupyter_notebook_config.py && \
        echo "c.LatexConfig.run_times = 2" >> /etc/jupyter/jupyter_notebook_config.py && \

	# remove all unwanted stuff
        conda clean -a -y


# install additional kernel based packages
# RUN conda install package1 package2

RUN conda install r-lme4 r-venndiagram r-gridextra && \
#    conda install -c bioconda r-car && \
    conda install r-car && \
	conda clean -a -y

# add the jupyter XFCE desktop
USER root

RUN apt-get -y update \
 && apt-get install -y dbus-x11 \
   firefox epiphany-browser \
   xfce4 xfce4-panel xfce4-session xfce4-settings xfce4-terminal \
   xorg \
   fuse lftp rsync unrar unzip \
   xubuntu-icon-theme \
   libreoffice libreoffice-l10n-de texstudio gnumeric gnupg2 kile  \
   xterm \
   emacs kate vim-gtk3 dia gedit geany gnuplot-x11 gnuplot info \
   gnome-terminal \
   evince atril  \
   codeblocks \
   gcc g++ gfortran binutils bison flex patch clang ffmpeg gdb m4 mailutils mc  \
 && apt-get -qq purge \
 && apt-get -qq clean \
 && rm -rf /var/lib/apt/lists/*

# Remove light-locker to prevent screen lock
ARG TURBOVNC_VERSION=2.2.6
RUN wget -q "https://sourceforge.net/projects/turbovnc/files/${TURBOVNC_VERSION}/turbovnc_${TURBOVNC_VERSION}_amd64.deb/download" -O turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   apt-get install -y -q ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   apt-get remove -y -q light-locker && \
   rm ./turbovnc_${TURBOVNC_VERSION}_amd64.deb && \
   ln -s /opt/TurboVNC/bin/* /usr/local/bin/

# apt-get may result in root-owned directories/files under $HOME
RUN chown -R $NB_UID:$NB_GID $HOME

USER $NB_UID

RUN conda install jupyter-server-proxy>=1.4 websockify

# install jupyter-remote-desktop (fork with all patches and merges)
#RUN pip install https://github.com/jupyterhub/jupyter-remote-desktop-proxy/archive/refs/heads/main.zip
# install the fork from ocordes with clipboard patch and deactivated CtrlAltDelete-Button
RUN pip install https://github.com/ocordes/jupyter-remote-desktop-proxy/archive/refs/heads/main.zip

# overwrite the startup script
COPY vnc/xstartup /opt/conda/lib/python3.9/site-packages/jupyter_desktop/share/


# add vscode to the repo

USER root

RUN wget "https://packages.microsoft.com/repos/code/pool/main/c/code/code_1.71.2-1663191218_amd64.deb" && \
    apt install ./code_1.71.2-1663191218_amd64.deb  && \
    rm -f ./code_1.71.2-1663191218_amd64.deb

USER $NB_UID

# Done.
