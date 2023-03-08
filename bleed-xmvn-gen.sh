#!/bin/sh
set -eu
exec 3>&1 >&2

name=xmvn-generator
version=5.0.0
#upstream_git_repo=https://github.com/fedora-java/javapackages.git
#upstream_ref=master
#downstream_git_repo=https://src.fedoraproject.org/rpms/${name}.git
#downstream_ref=origin/rawhide
upstream_git_repo=/home/kojan/git/xmvn-generator
upstream_ref=HEAD
downstream_git_repo=/home/kojan/tmp/fp/xmvn-generator
downstream_ref=HEAD

rm -rf upstream.git downstream
git clone --bare $upstream_git_repo upstream.git
git clone $downstream_git_repo downstream

upstream_commit_full=$(git -C upstream.git rev-parse "${upstream_ref}")
if [[ -d /mnt/nfs/mbi-cache/distgit/${upstream_commit_full} ]]; then
    echo ${upstream_commit_full} >&3
    echo === ${upstream_commit_full} ===
    echo /mnt/nfs/mbi-cache/distgit/${upstream_commit_full}
    exit 0
fi

upstream_commit=$(echo "${upstream_commit_full}" | sed 's/\(.......\).*/\1/')
upstream_commit_date=$(git log -1 --format=%cs | sed s/-//g)

git -C downstream reset --hard ${downstream_ref}
touch downstream/bleed-stamp

rpm_version="${version}~bleed.${upstream_commit_date}.git.${upstream_commit}"

archive_prefix=xmvn-generator-${rpm_version}
git -C upstream.git archive --format tar --prefix ${archive_prefix}/ ${upstream_commit} | gzip -9nc >${name}-${rpm_version}.tar.gz
sha512sum --tag ${name}-${rpm_version}.tar.gz >downstream/sources
mv ${name}-${rpm_version}.tar.gz downstream/

sed -i "/^Source0:/s/ [^ ].*/ ${name}-${rpm_version}.tar.gz/" downstream/${name}.spec
sed -i /^Patch/d downstream/${name}.spec
sed -i /^%patch/d downstream/${name}.spec

rpmdev-bumpspec -n "${rpm_version}" -c "Automated snapshot packaging" downstream/${name}.spec

git -C downstream add bleed-stamp ${name}.spec sources ${name}-${rpm_version}.tar.gz
git -C downstream commit -m "Automated snapshot packaging"

mkdir /mnt/nfs/mbi-cache/distgit/${upstream_commit_full}
git --git-dir downstream/.git --work-tree /mnt/nfs/mbi-cache/distgit/${upstream_commit_full} reset --hard

echo ${upstream_commit_full} >&3
echo === ${upstream_commit_full} ===
echo /mnt/nfs/mbi-cache/distgit/${upstream_commit_full}
