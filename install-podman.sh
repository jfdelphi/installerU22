#!/bin/bash

install_podman() {
    echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/unstable/xUbuntu_22.04/ /' | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:unstable.list
    curl -fsSL https://download.opensuse.org/repositories/devel:kubic:libcontainers:unstable/xUbuntu_22.04/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/devel_kubic_libcontainers_unstable.gpg >/dev/null
    sudo apt update
    sudo apt install podman -y
}

configure_registries() {
    sed -i 's/unqualified-search-registries.*/unqualified-search-registries = ["docker.io"]/' /etc/containers/registries.conf
}

install_podman &&
    configure_registries &&
    podman version
