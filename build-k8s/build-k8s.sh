#!/usr/bin/env sh

function usage() {
    echo "usage:"
    echo "$0 <BRANCH> <VERSION>  [<REGISTRY> <ORGANIZATION>]"
    echo -ne "WHERE\n\tBRANCH: syphus|p10|c10f1|c10f2\nVERSION: n.n[.n]\n"
}

if [ "$#" -lt 2 -o  "$#" -gt 4 ]; then
    usage
    exit 1
fi

BRANCH=$1
VERSION=$2
REGISTRY=${3:-"gitea.basealt.ru"}

ORGANIZATION="k8s-$BRANCH"

case $ARCH in
  amd64|386|arm64|arm|ppc64le)
    :;;
  *) usage; exit 1
esac

case $BRANCH in
  sisyphus|p10|c10f1|c10f2)
    :;;
  *) usage; exit 1
esac

ifs=$IFS
IFS=.
set -- $VERSION
IFS=$ifs
case $# in
  2)
    if [ "$1" -gt 0 -a "$2" -gt 0 ] 2>/dev/null; then :;
    else
      usage; exit 1;
    fi
    MINORVERSION=$VERSION
    ;;
  3)
     if [ "$1" -gt 0 -a "$2" -gt 0 -a "$3" -gt 0 ] 2>/dev/null; then :;
    else
      usage; exit 1;
    fi
    MINORVERSION="$1.$2"
    ;;
  *)
    usage; exit 1;
esac


imageName="k8s/$BRANCH:$MINORVERSION"

if podman inspect $imageName 2>/dev/null >/dev/null
then
  :;
else
 podman build\
  --no-cache\
  -f Dockerfile_k8s\
  --build-arg="BRANCH=$BRANCH"\
  --build-arg="REGISTRY=$REGISTRY"\
  --build-arg="MINORVERSION=$MINORVERSION"\
  -t $imageName .
fi

images=$(podman run --rm -i $imageName $VERSION)
echo "IMAGES=$images"

exit

tagsFile="${BRANCH}-${MINORVERSION}-tags.toml"

> $tagsFile
ifs=$IFS
Images=''
for image in $images
do
  echo "IMAGE=$image"
  IFS=:
  set -- ${image:15}
  IFS=$ifs
  image=$1 tag=$2
  Images+=" k8s/$image"
  echo "image=$image tag=$2"
  echo -ne "[\"k8s/$image\"]\n$BRANCH = [\"$tag\"]\n\n" >> $tagsFile
done

./build.py\
  --branches $BRANCH\
  --latest $BRANCH\
  --registry gitea.basealt.ru\
  --overwrite-organization $ORGANIZATION\
  --tags $tagsFile\
  --skip-stages push\
  --images $Images

#   --sign kaf@altlinux.org\
#  --registry gitea.basealt.ru\
#   -a amd64,arm64\

