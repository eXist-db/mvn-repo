#!/bin/bash

set -e

REPOSITORY_ID="exist-db"

# Nexus 2 URL
#REPOSITORY_URL="http://repo.evolvedbinary.com/content/repositories/exist-db/"

# Nexus 3 URL
REPOSITORY_URL="http://repo.evolvedbinary.com/repository/exist-db/"

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
    *)
            # unknown option
    ;;
esac
done

VERSION="${1}"

if [ -z "${VERSION}" ]
then
        echo "upload.sh [-l|--local] <version>"
        exit 1
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
for f in `find . -name "*${VERSION}.jar" -type f` 
do
	POM=${f/.jar/.pom}
	CMD="${MAVEN_CMD} -DpomFile=${POM} -Dfile=${f}"
	eval $CMD
done

# Upload the 3rd-party Artifacts
if [ -n "${THIRD_PARTY}" ]
then
	for f in `find org/exist-db/thirdparty -name "*.jar" -type f`
	do
		POM=${f/.jar/.pom}
		CMD="${MAVEN_CMD} -DpomFile=${POM} -Dfile=${f}"
		eval $CMD
	done
fi

# Upload the parent POM file
PARENT_POM="org/exist-db/exist-parent/${VERSION}/exist-parent-${VERSION}.pom"
CMD="${MAVEN_CMD} -DpomFile=${PARENT_POM} -Dfile=${PARENT_POM}"
eval $CMD
