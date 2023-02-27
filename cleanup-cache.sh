#!/bin/sh
set -eu

for stamp in $(find /mnt/nfs/mbi-cache/distgit/ -name bleed-stamp); do
    rm -rf $(dirname $stamp)
done

