#!/bin/bash

set -e

FROM="${1}"
TO="${2}"

echo "Migrating ${FROM} to ${TO}..."

# Make sure a folder for the parent POM exists
mkdir -p "org/exist-db/exist-parent/${TO}"

# POMS 
for f in `find . -name "*-${FROM}.pom" -type f`
do
	DEST=${f//$FROM/$TO}
	cp -v $f $DEST
	sed -i -e "s/${FROM}/${TO}/g" $DEST
	openssl sha1 -r "${DEST}" | sed 's/\([a-f0-9]*\).*/\1/' > "${DEST}.sha1"
done

# cleanup -e files
find . -name \*.pom-e -exec rm {} \;
