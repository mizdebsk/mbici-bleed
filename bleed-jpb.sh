#!/bin/sh
set -eu

name=javapackages-bootstrap
version=2.0.0
#upstream_git_repo=https://github.com/fedora-java/javapackages.git
#upstream_ref=master
#downstream_git_repo=https://src.fedoraproject.org/rpms/${name}.git
#downstream_ref=origin/rawhide
upstream_git_repo=/home/kojan/git/javapackages-bootstrap
upstream_ref=HEAD
downstream_git_repo=/home/kojan/tmp/fp/javapackages-bootstrap
downstream_ref=HEAD

rm -rf upstream.git downstream
git clone --bare $upstream_git_repo upstream.git
git clone $downstream_git_repo downstream

upstream_commit=$(git -C upstream.git rev-parse "${upstream_ref}" | sed 's/\(.......\).*/\1/')
upstream_commit_date=$(git log -1 --format=%cs | sed s/-//g)

git -C downstream reset --hard ${downstream_ref}
touch downstream/bleed-stamp

rpm_version="${version}~bleed.${upstream_commit_date}.git.${upstream_commit}"

archive_prefix=javapackages-bootstrap-${rpm_version}
git -C upstream.git archive --format tar --prefix ${archive_prefix}/ ${upstream_commit} | gzip -9nc >${name}-${rpm_version}.tar.gz
sha512sum --tag ${name}-${rpm_version}.tar.gz >downstream/sources
mv ${name}-${rpm_version}.tar.gz downstream/

sed -i "/^Source0:/s/ [^ ].*/ ${name}-${rpm_version}.tar.gz/" downstream/${name}.spec
sed -i /^Patch/d downstream/${name}.spec
sed -i /^%patch/d downstream/${name}.spec

(
    set -eu
    cd ./downstream
    tar xf ${name}-${rpm_version}.tar.gz

    sed '/^Source1001:/,$d' javapackages-bootstrap.spec >prefix.txt
    sed '1,/^BuildRequires:/d' javapackages-bootstrap.spec >suffix.txt

    cat prefix.txt >javapackages-bootstrap.spec
    ./generate-sources-list.sh >>javapackages-bootstrap.spec

    echo >>javapackages-bootstrap.spec
    ./generate-bundled-provides.sh >>javapackages-bootstrap.spec

    echo >>javapackages-bootstrap.spec
    echo "BuildRequires:  byaccj" >>javapackages-bootstrap.spec
    cat suffix.txt >>javapackages-bootstrap.spec

    sources=$(ls /home/kojan/git/javapackages-bootstrap/archive/)
    cp /home/kojan/git/javapackages-bootstrap/archive/* .
    git add -f ${sources}
    sha512sum --tag ${sources} >>sources
)

rpmdev-bumpspec -n "${rpm_version}" -c "Automated snapshot packaging" downstream/${name}.spec

git -C downstream add bleed-stamp ${name}.spec sources ${name}-${rpm_version}.tar.gz
git -C downstream commit -m "Automated snapshot packaging"

downstream_commit=$(git -C downstream rev-parse HEAD)

mkdir /mnt/nfs/mbi-cache/distgit/${downstream_commit}
git --git-dir downstream/.git --work-tree /mnt/nfs/mbi-cache/distgit/${downstream_commit} reset --hard


echo === ${downstream_commit} ===
echo /mnt/nfs/mbi-cache/distgit/${downstream_commit}
