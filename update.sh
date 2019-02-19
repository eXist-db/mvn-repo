#!/usr/bin/env bash

###
# After doing a build of an eXist code base
# for a sepecific tag this script does some
# very simple copying and renaming of JAR files
# from an into a Maven like repository structure.
#
# If you want extension modules you must enable
# these in $EXIST_HOME/extensions/build.properties
# before running this script
#
# NOTE - It will not generate the POM files for you!
###

# determine the directory that this script is in
pushd `dirname $0` > /dev/null
SCRIPT_DIR=`pwd -P`
popd > /dev/null

## Default paths. Can be overriden by command line
## args --build-dir, --output-dir, and/or --exist-build-dir
TMP_ROOT_DIR="/tmp/exist-nightly-build"
BUILD_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${TMP_ROOT_DIR}/mvn/target"
EXIST_BUILD_DIR="${TMP_ROOT_DIR}/dist/source"
EXIST_TAG=`date +%Y%m%d`


## stop on first error!
set -e

## uncomment the line below for debugging this script!
#set -x

for i in "$@"
do
case $i in
    -s|--snapshot)
    SNAPSHOT="TRUE"
    shift
    ;;
    -t|--tag)
    EXIST_TAG="$2"
    shift
    ;;
    -f|--force)
    FORCE=YES
    shift
    ;;
    -d|--build-dir)
    BUILD_DIR="$2"
    shift
    ;;
    -o|--output-dir)
    OUTPUT_DIR="$2"
    shift
    ;;
    -i|--output-in-place)
    OUTPUT_DIR="${SCRIPT_DIR}"
    shift
    ;;
    -e|--exist-build-dir)
    EXIST_BUILD_DIR="$2"
    shift
    ;;
    *)  # unknown option
    shift
    ;;
esac
done

GROUP_DIR="${OUTPUT_DIR}/org/exist-db"

## sanity checks

# Locate JAVA_HOME (if not set in env)
if [ -z "${JAVA_HOME}" ]; then
  echo -e "\nNo JAVA_HOME environment variable found!"
  echo "Attempting to determine JAVA_HOME (if this fails you must manually set it)..."
  if [ "$(uname -s)" == "Darwin" ]; then
      java_bin=$(readlink `which java`)
  else
      java_bin=$(readlink -f `which java`)
  fi
  java_bin_dir=$(dirname "${java_bin}")
  JAVA_HOME=$(dirname "${java_bin_dir}")
  echo -e "Derived JAVA_HOME=${JAVA_HOME}\n"
fi

if [ ! -d "${JAVA_HOME}" ]; then
  echo -e "Error: JAVA_HOME directory does not exist!\n"
  echo -e "JAVA_HOME=${JAVA_HOME}\n"
  exit 2;
fi

REQUIRED_JAVA_VERSION=18
JAVA_VERSION="$($JAVA_HOME/bin/java -version 2>&1 | sed -n ';s/.* version "\(.*\)\.\(.*\)\..*"/\1\2/p;')"
if [ ! "$JAVA_VERSION" -eq $REQUIRED_JAVA_VERSION ]; then
  echo -e "Error: Building requires Java 1.8\n"
  echo -e "Found $($JAVA_HOME/bin/java -version)\n";
  exit 2;
fi


# check there is either no local.build.properties in the
# EXIST_BUILD_DIR, or that if present it does not contain
# keystore settings
if [ -f "${EXIST_BUILD_DIR}/local.build.properties" ]; then
  if grep -Eq "^keystore.file=.+$" "${EXIST_BUILD_DIR}/local.build.properties"; then
    echo -e "Error: Found a local.build.properties file with keystore in the $EXIST_BUILD_DIR\n"
    echo -e "Maven artifacts should be built without signing\n"
    exit 3;
  fi
fi

# Is this a snapshot version?
if [ -n "${SNAPSHOT}" ]
then
	echo -e "\nWARN: Generating a SNAPSHOT version...\n\n"
	EXIST_TAG="${EXIST_TAG}-SNAPSHOT"

	# Does snapshot tag already exist?
        if [ -d "${GROUP_DIR}/exist-core/${EXIST_TAG}" ];
        then
		if [ -n "${FORCE}" ]
                then
                    echo -e "\nWARN: SNAPSHOT version already exists, files will be overwritten!!!\n\n"
                else
                    EXIST_TAG="$(date +%Y%m%d%H%M)-SNAPSHOT"
                    echo -e "\nWARN: SNAPSHOT version already exists, will create a new SNAPSHOT: ${EXIST_TAG}...\n\n"
                fi
        fi

        echo "${EXIST_TAG}" > ${BUILD_DIR}/SNAPSHOT
        echo -e "\nRecorded SNAPSHOT version in file ${BUILD_DIR}/SNAPSHOT"

else
	# Does the non-snapshot tag already exist?
	if [ -d "${GROUP_DIR}/exist-core/${EXIST_TAG}" ];
	then
                if [ -n "${FORCE}" ]
                then
                    echo -e "\nWARN: TAG version already exists, files will be overwritten!!!\n\n"
                else
                    EXIST_TAG=`date +%Y%m%d%H%M`
                    echo -e "\nWARN: TAG version already exists, will create a new TAG: ${EXIST_TAG}...\n\n"
                fi
	fi
fi

function mavenise {
	OUT_DIR="${GROUP_DIR}/${2}/${EXIST_TAG}"
	mkdir -p $OUT_DIR

	OUT_FILE="${OUT_DIR}/${2}-${EXIST_TAG}.jar"
	cp -v $1 $OUT_FILE
	openssl sha1 -r "${OUT_FILE}" | sed 's/\([a-f0-9]*\).*/\1/' > "${OUT_FILE}.sha1"
}

# build a current version
echo -e "\nBuilding for version tag: ${EXIST_TAG}\n"

pushd $EXIST_BUILD_DIR
./build.sh clean-all
./build.sh

# Mavenise the root jar files
mavenise exist.jar exist-core
mavenise start.jar exist-start
mavenise exist-optional.jar exist-optional
mavenise exist-testkit.jar exist-testkit

# Mavenise each of the extension modules
for f in lib/extensions/exist-*.jar
do
	FILE_NAME=$(basename $f)
	ARTIFACT_NAME="${FILE_NAME%.jar}"
        ARTIFACT_NAME="${ARTIFACT_NAME/-$EXIST_TAG/}"
	mavenise $f "${ARTIFACT_NAME}"
done

# Correct the naming of the EXPath module
EXPATH_VER=20130805
mkdir -p "${GROUP_DIR}/exist-expath"
mv -v "${GROUP_DIR}/exist-expath-${EXPATH_VER}/${EXIST_TAG}" "${GROUP_DIR}/exist-expath"
rm -rv "${GROUP_DIR}/exist-expath-${EXPATH_VER}"
mv -v "${GROUP_DIR}/exist-expath/${EXIST_TAG}/exist-expath-${EXPATH_VER}-${EXIST_TAG}.jar" "${GROUP_DIR}/exist-expath/${EXIST_TAG}/exist-expath-${EXIST_TAG}.jar"
mv -v "${GROUP_DIR}/exist-expath/${EXIST_TAG}/exist-expath-${EXPATH_VER}-${EXIST_TAG}.jar.sha1" "${GROUP_DIR}/exist-expath/${EXIST_TAG}/exist-expath-${EXIST_TAG}.jar.sha1"

# Remove various eXist modules that are not production ready
REMOVE_ARTIFACTS=(
        "exist-debugger"
        "exist-metadata-*"
        "exist-netedit"
        "exist-security-o*"
        "exist-svn"
        "exist-tomcat-realm"
        "exist-xUnit"
        "exist-xqdoc"
        "exist-xslt"
)
for a in ${REMOVE_ARTIFACTS[@]}; do
	rm -rfv "${GROUP_DIR}/${a}"
done

# restore the cwd
popd
