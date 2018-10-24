#!/usr/bin/env bash

set -e 

for f in `find . -name \*.pom -type f`
do
	openssl sha1 -r "${f}" | sed 's/\([a-f0-9]*\).*/\1/' > "${f}.sha1"
done
