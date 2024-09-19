#!/bin/bash
# @description      this bash script, just read the env file (seee -f),
#                   and from it is getting the variable with concrete suffix
#                   search pattern <prefix^^><suffix^^>
# @param -p         prefix name
# @param -v         verion type (major / feature / bug)
# @param -s         suffix name default _IMAGE_VERSION
# @param -f         filepath of env where to read default is ./.env
# @return string    echo of incremental dotted string number by version type

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
cd ${SCRIPT_DIR}/..

imagesuffix="_IMAGE_VERSION"
fileEnv=".env"

while getopts ":f:p:v:s:" opt; do
    case $opt in
    f)
        fileEnv=${OPTARG}
        ;;
    p)
        imageprefix="${OPTARG}"
        ;;
    v)
        version_type="${OPTARG}"
        ;;
    s)
        imagesuffix="${OPTARG}"
        ;;
    \?)
        echo "Invalid option -${OPTARG}" >&2
        exit
        ;;
    esac
done

if [[ -f "${fileEnv}" ]]; then
    source ${fileEnv}
fi

image_key="${imageprefix^^}${imagesuffix^^}"

version=${!image_key}

if [[ -z $version_type ]]; then
    version_type="bug"
fi

major=0
minor=0
build=0

regex="([0-9]+).([0-9]+).([0-9]+)"
if [[ $version =~ $regex ]]; then
    major="${BASH_REMATCH[1]}"
    minor="${BASH_REMATCH[2]}"
    build="${BASH_REMATCH[3]}"
fi

if [[ "$version_type" == "feature" ]]; then
    minor=$(echo $minor + 1 | bc)
elif [[ "$version_type" == "bug" ]]; then
    build=$(echo $build + 1 | bc)
elif [[ "$version_type" == "major" ]]; then
    major=$(echo $major+1 | bc)
else
    echo "usage: ./version.sh version_number [major/feature/bug]"
    exit -1
fi
image_version="${major}.${minor}.${build}"
echo $image_version
