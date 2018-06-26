#!/bin/bash
  
set -e

REPOSITORY_ID="exist-db"
SNAPSHOTS_REPOSITORY_ID="exist-db-snapshots"

# Nexus 2 URL
#REPOSITORY_URL="http://repo.evolvedbinary.com/content/repositories/exist-db/"

# Nexus 3 URL
REPOSITORY_URL="http://repo.evolvedbinary.com/repository/exist-db/"
SNAPSHOTS_REPOSITORY_URL="http://repo.evolvedbinary.com/repository/exist-db-snapshots/"

GROUP_ID="${1}"
ARTIFACT_ID="${2}"
VERSION="${3}"

for i in "$@"
do
case $i in
    -l|--local)
    LOCAL=YES
    shift # past argument with no value
    ;;
    *)
            # unknown option
    ;;
esac
done

# Install to local repo or upload to remote
MAVEN_CMD=""
if [ -n "${LOCAL}" ]
then
        MAVEN_CMD="mvn install:install-file"
else
        MAVEN_CMD="mvn deploy:deploy-file -DrepositoryId=${REPOSITORY_ID} -Durl=${REPOSITORY_URL}"
fi

DIR="${GROUP_ID//\.//\/}/${ARTIFACT_ID}/${VERSION}"
POM_FILE="${DIR}/${ARTIFACT_ID}-${VERSION}.pom"
JAR_FILE="${DIR}/${ARTIFACT_ID}-${VERSION}.jar"

CMD="${MAVEN_CMD} -DpomFile=${POM_FILE} -Dfile=${JAR_FILE}"
eval $CMD
