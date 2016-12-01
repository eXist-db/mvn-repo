#!/bin/bash

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
# Note - It will not generate the POM files for you!
###

set -e

# uncomment the line below for debugging this script!
#set -x

# Configiguration options
EXIST_HOME=/Users/aretter/code/exist-git
EXIST_TAG=`date +%Y%m%d`
MVN_REPO_HOME=/Users/aretter/code/mvn-repo
TMP_DIR=/tmp

for i in "$@"
do
case $i in
    -s|--snapshot)
    SNAPSHOT=YES
    shift # past argument with no value
    ;;
    -t|--tag)
    EXIST_TAG="$2"
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
done


# Is this a snapshot version?
if [ -n "${SNAPSHOT}" ]
then
	echo -e "\nWARN: Generating a SNAPSHOT version...\n\n"
	EXIST_TAG="${EXIST_TAG}-SNAPSHOT"
else
	# Does the non-snapshot tag already exist?
	if [ -d "${MVN_REPO_HOME}/org/exist-db/exist-core/${EXIST_TAG}" ];
	then
        	EXIST_TAG=`date +%Y%m%d%H%M`
	fi
fi

function mavenise {
	OUT_DIR="${MVN_REPO_HOME}/org/exist-db/${2}/${EXIST_TAG}"
	mkdir -p $OUT_DIR

	OUT_FILE="${OUT_DIR}/${2}-${EXIST_TAG}.jar"
	cp -v $1 $OUT_FILE
	openssl sha1 -r "${OUT_FILE}" | sed 's/\([a-f0-9]*\).*/\1/' > "${OUT_FILE}.sha1"
}

cd $EXIST_HOME

# build a current version
./build.sh clean
./build.sh

# Mavenise the root jar files
mavenise exist.jar exist-core
mavenise start.jar exist-start
mavenise exist-optional.jar exist-optional

# Mavenise each of the extension modules
for f in lib/extensions/exist-*.jar
do
	FILE_NAME=$(basename $f)
	ARTIFACT_NAME="${FILE_NAME%.jar}"
	mavenise $f "${ARTIFACT_NAME}"
done

# Correct the naming of the EXPath module
EXPATH_VER=20130805
mv "${MVN_REPO_HOME}/org/exist-db/exist-expath-${EXPATH_VER}/${EXIST_TAG}" "${MVN_REPO_HOME}/org/exist-db/exist-expath"
rm -r "${MVN_REPO_HOME}/org/exist-db/exist-expath-${EXPATH_VER}"
mv "${MVN_REPO_HOME}/org/exist-db/exist-expath/${EXIST_TAG}/exist-expath-${EXPATH_VER}-${EXIST_TAG}.jar" "${MVN_REPO_HOME}/org/exist-db/exist-expath/${EXIST_TAG}/exist-expath-${EXIST_TAG}.jar"
mv "${MVN_REPO_HOME}/org/exist-db/exist-expath/${EXIST_TAG}/exist-expath-${EXPATH_VER}-${EXIST_TAG}.jar.sha1" "${MVN_REPO_HOME}/org/exist-db/exist-expath/${EXIST_TAG}/exist-expath-${EXIST_TAG}.jar.sha1"

# Remove various eXist modules that are not production ready
ARTIFACT_DIR="${MVN_REPO_HOME}/org/exist-db"
cd $ARTIFACT_DIR
rm -rfv exist-debugger exist-metadata-* exist-netedit exist-security-o* exist-svn exist-tomcat-realm exist-xUnit exist-xqdoc exist-xslt
cd $NVN_REPO_HOME

