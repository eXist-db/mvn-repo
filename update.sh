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
EXIST_HOME=/Users/aretter/NetBeansProjects/exist-git
EXIST_TAG=3.0.RC1
MVN_REPO_HOME=/Users/aretter/NetBeansProjects/mvn-repo
TMP_DIR=/tmp



function mavenise {
	OUT_DIR="${MVN_REPO_HOME}/org/exist-db/${2}/${EXIST_TAG}"
	mkdir -p $OUT_DIR

	OUT_FILE="${OUT_DIR}/${2}-${EXIST_TAG}.jar"
	cp -v $1 $OUT_FILE
	openssl sha1 -r "${OUT_FILE}" | sed 's/\([a-f0-9]*\).*/\1/' > "${OUT_FILE}.sha1"
}

cd $EXIST_HOME

# Checkout and build the tag for the release version
git checkout "tags/eXist-${EXIST_TAG}"
./build.sh clean
./build.sh

# Mavenise the root jar files
mavenise exist.jar existdb-core
mavenise start.jar existdb-start
mavenise exist-optional.jar existdb-optional

# Mavenise each of the extension modules
for f in lib/extensions/exist-*.jar
do
	FILE_NAME=$(basename $f)
	TMP_NAME="existdb-${FILE_NAME#exist-}"
	TMP_DEST="${TMP_DIR}/${TMP_NAME}"
	ARTIFACT_NAME="${TMP_NAME%.jar}"
	cp -v $f "${TMP_DEST}"
	mavenise $TMP_DEST "${ARTIFACT_NAME}"
	rm -v "${TMP_DEST}" 
done
