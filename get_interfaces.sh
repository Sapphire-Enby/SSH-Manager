#!/usr/bin/env bash

whoami
ip addr show | awk '
/^[0-9]+: / {
    iface = $2
    sub(":", "", iface)
}
/inet / && iface != "lo" {
    split($2, a, "/")
    print iface, a[1]
}'
