FROM archlinux
RUN groupadd junior && \
    useradd -m -g junior -s /bin/bash junior && \
    usermod -aG wheel junior && \
    echo "junior:123mudar" | chpasswd
RUN pacman -Sy && \
    pacman -S --noconfirm reflector rsync && \
    reflector -c brazil --sort rate --save /etc/pacman.d/mirrorlist
RUN pacman -S --noconfirm nushell sudo
RUN echo 'junior ALL=(ALL) ALL' > /etc/sudoers.d/00_junior
RUN echo 'echo pacboy' > /usr/bin/pacboy
RUN chmod +x /usr/bin/pacboy
