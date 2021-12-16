#!/usr/bin/env bash

# determine the directory that this script is in
pushd `dirname $0` > /dev/null
SCRIPT_DIR=`pwd -P`
popd > /dev/null

## Default paths. Can be overriden by command line
## arg --output-dir
TMP_DIR="/tmp/exist-nightly-build/mvn"
OUTPUT_DIR="${TMP_DIR}/target"

## stop on first error!
set -e

## uncomment the line below for debugging this script!
#set -x

RELEASES_REPOSITORY_ID="exist-db"
RELEASES_REPOSITORY_URL="https://repo.evolvedbinary.com/repository/exist-db/"
SNAPSHOTS_REPOSITORY_ID="exist-db-snapshots"
SNAPSHOTS_REPOSITORY_URL="https://repo.evolvedbinary.com/repository/exist-db-snapshots/"

REPOSITORY_ID="${RELEASES_REPOSITORY_ID}"
REPOSITORY_URL="${RELEASES_REPOSITORY_URL}"

for i in "$@"
do
case $i in
    -l|--local)
    LOCAL=YES
    shift # past argument with no value
    ;;
    -3|--third-party)
    THIRD_PARTY=YES
    shift # past argument with no value
    ;;
    -a|--artifact-version)
    ARTIFACT_VERSION="$2"
    shift
    ;;
    -s|--snapshot)
    SNAPSHOT="TRUE"
    REPOSITORY_ID="${SNAPSHOTS_REPOSITORY_ID}"
    REPOSITORY_URL="${SNAPSHOTS_REPOSITORY_URL}"
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
    *)  # unknown option
    shift
    ;;
esac
done


## sanity checks

if [ -z "${ARTIFACT_VERSION}" ]
then
        echo "upload.sh [-l|--local -3|--third-party] -a|--artifact-version <version>"
        exit 1
fi

# check that Maven 3.5.4 or later is available
if ! [ -x "$(command -v mvn)" ]; then
   echo -e "Error: Maven mvn binary not found on the PATH\n"
   exit 2
fi

REQUIRED_MVN_VERSION=354
MVN_VERSION="$(mvn --version | head -n 1 | sed 's|Apache Maven \([0-9]*\)\.\([0-9]*\)\.\([0-9]*\).*|\1\2\3|')"
if [ ! "$MVN_VERSION" -ge $REQUIRED_MVN_VERSION ]; then
  echo -e "Error: Building requires Maven 3.5.4 or newer\n"
  echo -e "Found $(mvn --version | head -n 1)\n"
  exit 2
fi


# Install to local repo or upload to remote
MAVEN_CMD=""
if [ -n "${LOCAL}" ]
then
	MAVEN_CMD="mvn install:install-file"
else
	MAVEN_CMD="mvn deploy:deploy-file -DrepositoryId=${REPOSITORY_ID} -Durl=${REPOSITORY_URL}"
fi


# Upload the Artifacts
for f in `find ${OUTPUT_DIR} -name "*${ARTIFACT_VERSION}.jar" -type f` 
do
	POM=${f/.jar/.pom}
	CMD="${MAVEN_CMD} -DpomFile=${POM} -Dfile=${f}"
	eval $CMD
done

# Upload the 3rd-party Artifacts
if [ -n "${THIRD_PARTY}" ]
then
	for f in `find $OUTPUT_DIR/org/exist-db/thirdparty -name "*.jar" -type f`
	do
		POM=${f/.jar/.pom}
		CMD="${MAVEN_CMD} -DpomFile=${POM} -Dfile=${f}"
		eval $CMD
	done
fi

# Upload the parent POM file
PARENT_POM="${OUTPUT_DIR}/org/exist-db/exist-parent/${ARTIFACT_VERSION}/exist-parent-${ARTIFACT_VERSION}.pom"
CMD="${MAVEN_CMD} -DpomFile=${PARENT_POM} -Dfile=${PARENT_POM}"
eval $CMD
