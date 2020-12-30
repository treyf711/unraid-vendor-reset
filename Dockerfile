FROM archlinux
run pacman -Syyu --needed --noconfirm base-devel asp bc kmod libelf pahole cpio perl tar xz \
                         xmlto python-sphinx python-sphinx_rtd_theme graphviz imagemagick git \
                         neovim squashfs-tools unzip wget rsync
ADD buildscript.sh /root/
