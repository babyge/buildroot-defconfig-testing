#!/usr/bin/env bash

BUILDROOT_GIT=git://git.busybox.net/buildroot

tmpdir=$(mktemp -d)
git clone ${BUILDROOT_GIT}  ${tmpdir} || \
    { rm -rf ${tmpdir}; exit 1; }

# Get the latest commit
commit=$(git --git-dir ${tmpdir}/.git show -s --format=%H) || \
    { rm -rf ${tmpdir}; exit 1; }

# Adjust .travis.yml to use the latest commit
sed -i "s%^- git checkout.*%- git checkout ${commit}%" .travis.yml || \
    { rm -rf ${tmpdir}; exit 1; }

# Re-generate the list of defconfigs. Unfortunately, awk doesn't do in
# place modification, so we generate to a temporary file and then
# rename.
awk -v gitrepo=${tmpdir} '
/^  matrix:/ {
  print;
  system("for i in $(ls -1 " gitrepo "/configs); do echo \"   - DEFCONFIG_NAME=$i\" ; done");
  inmatrix=1; }
/^script:/ {
  inmatrix=0;
}
// {
  if (inmatrix) {
    next;
  }
  print;
}' .travis.yml > .travis.yml.tmp || \
    { rm -rf ${tmpdir}; exit 1; }

mv .travis.yml.tmp .travis.yml || \
    { rm -rf ${tmpdir}; exit 1; }

# Commit
git add .travis.yml
git commit -s -m "Update to Buildroot ${commit}" || \
    { rm -rf ${tmpdir}; exit 1; }

git push || \
    { rm -rf ${tmpdir}; exit 1; }

rm -rf ${tmpdir}
