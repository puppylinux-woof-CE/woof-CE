FROM gitpod/workspace-full-vnc:latest

RUN sudo apt-get update -qq && sudo apt-get install -y --no-install-recommends qemu-system-x86 qemu-system-gui fakeroot ccache libelf-dev libssl-dev
RUN curl https://raw.githubusercontent.com/puppylinux-woof-CE/initrd_progs/master/pkg/w_apps_static/w_apps/vercmp.c | sudo gcc -x c -o /usr/local/bin/vercmp -
RUN sudo mkdir -p /usr/local/petget && curl https://raw.githubusercontent.com/puppylinux-woof-CE/initrd_progs/66f9c9d6cefe318f2b9181a6a53c99b54651416a/pkg/w_apps_static/w_apps/debdb2pupdb.c | sudo gcc -x c -o /usr/local/petget/debdb2pupdb -
RUN curl https://raw.githubusercontent.com/puppylinux-woof-CE/woof-CE/testing/woof-code/rootfs-skeleton/usr/local/petget/categories.dat | sudo tee /usr/local/petget/categories.dat
RUN echo "dash dash/sh boolean false" | sudo debconf-set-selections && sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash