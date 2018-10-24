#!/usr/bin/env bash

## Default paths. Can be overriden by command line
## args --build-dir and/or --output-dir
TMP_DIR="/tmp/exist-nightly-build/mvn"
BUILD_DIR="${TMP_DIR}/source"
OUTPUT_DIR="${TMP_DIR}/target"

## stop on first error!
set -e

## uncomment the line below for debugging this script!
#set -x

# determine the directory that this script is in
pushd `dirname $0` > /dev/null
SCRIPT_DIR=`pwd -P`
popd > /dev/null

# parse command line args
for i in "$@"
do
case $i in
    -d|--build-dir)
    BUILD_DIR="$2"
    shift
    ;;
    --build-in-place)
    BUILD_DIR="${SCRIPT_DIR}"
    shift
    ;;
    -o|--ouput-dir)
    OUTPUT_DIR="$2"
    shift
    ;;
    -i|--output-in-place)
    OUTPUT_DIR="${SCRIPT_DIR}"
    shift
    ;;
    -f|--from-version)
    FROM_VERSION="$2"
    shift
    ;;
    -t|--to-version)
    TO_VERSION="$2"
    shift
    ;;
    *)  # unknown option
    shift
    ;;
esac
done

FROM_GROUP_DIR="${BUILD_DIR}/org/exist-db"
TO_GROUP_DIR="${OUTPUT_DIR}/org/exist-db"

echo -e "Migrating ${FROM_VERSION} to ${TO_VERSION}...\n"

# Make sure a folder for the parent POM exists
mkdir -p "${TO_GROUP_DIR}/exist-parent/${TO_VERSION}"

# POMS 
for f in `find $FROM_GROUP_DIR -name "*-${FROM_VERSION}.pom" -type f`
do
	if [[ ${f} != *"avalon"* ]];then
		DEST=${f//$FROM_VERSION/$TO_VERSION}
                DEST=${DEST//$FROM_GROUP_DIR/$TO_GROUP_DIR}
		cp -v $f $DEST
                sed -i -e "s#<version>${FROM_VERSION}</version>#<version>${TO_VERSION}</version>#g" $DEST
		openssl sha1 -r "${DEST}" | sed 's/\([a-f0-9]*\).*/\1/' > "${DEST}.sha1"
	fi
done

# cleanup -e files
find . -name \*.pom-e -exec rm {} \;
