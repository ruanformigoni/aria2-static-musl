#!/usr/bin/env bash

######################################################################
# @author      : Ruan E. Formigoni (ruanformigoni@gmail.com)
# @file        : build
# @created     : Sunday Dec 10, 2023 19:41:38 -03
#
# @description : 
######################################################################

set -e

mkdir -p build && cd build

# Link to latest version
read -r url < <(wget -q --header="Accept: application/vnd.github+json" \
  -O - https://api.github.com/repos/aria2/aria2/releases/latest |
  jq -e -r '.assets.[].browser_download_url | match(".*aria2-.*.tar.xz").string | select (.!=null)')

# Download
wget "$url"

# Extract
tar xf *.tar.xz
rm -- *.tar.xz
mv aria2* aria2
cd aria2

# Fetch image
if [[ ! -f ./alpine.tar.xz ]]; then
  wget "https://gitlab.com/api/v4/projects/43000137/packages/generic/fim/continuous/alpine.tar.xz"
fi
tar xf alpine.tar.xz

# Resize
./alpine.fim fim-resize 1G

# Install compile deps
./alpine.fim fim-root apk add gcc autoconf automake libtool pkgconfig openssl \
  openssl-dev gnutls gnutls-dev c-ares c-ares-dev zlib zlib-dev sqlite sqlite-dev \
  cppunit cppunit-dev libssh2 libssh2-dev libssh2-static g++ make libc-dev \
  openssl-libs-static sqlite-static lz4-static zlib-static c-ares-static

# Compile
# shellcheck disable=2155
export CC="$(readlink -f "$(command -v gcc)")"
# shellcheck disable=2155
export CXX="$(readlink -f "$(command -v g++)")"

./alpine.fim fim-root ./configure ARIA2_STATIC=yes --without-gnutls --with-openssl

./alpine.fim fim-root make -j"$(nproc)"
