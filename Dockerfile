FROM archlinux
run pacman -Syyu --needed --noconfirm base-devel asp bc kmod libelf pahole cpio perl tar xz \
                         xmlto python-sphinx python-sphinx_rtd_theme graphviz imagemagick git \
                         neovim squashfs-tools unzip wget rsync
ADD buildscript.sh /root/
ENV UNAME=5.10.1-Unraid
ENV UNRAID_V=6.9.0
ENV BETA_BUILD=rc2
ENV VENDOR_RESET=true
VOLUME ["/root/kernel"]
RUN chmod +x /root/buildscript.sh
ENTRYPOINT ["/root/buildscript.sh"]
