FROM archlinux
run pacman -Syyu --needed --noconfirm base-devel asp bc kmod libelf pahole cpio perl tar xz \
                         xmlto python-sphinx python-sphinx_rtd_theme graphviz imagemagick git \
                         neovim squashfs-tools unzip wget rsync
ADD buildscript.sh /root/
ENV UNAME=4.19.107-Unraid
ENV UNRAID_V=6.8.3
ENV VENDOR_RESET=true
VOLUME ["/root/kernel"]
RUN chmod +x /root/buildscript.sh
ENTRYPOINT ["/root/buildscript.sh"]
