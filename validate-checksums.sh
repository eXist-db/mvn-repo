#!/bin/bash

###
# Finds all .sha1 files and validates the checksum
# found in those files against the source files.
#
# Any non-matching checksums are reported.
#
# Returns a non-zero exit status if any checksum
# does not validate
###

set -e

# uncomment the line below for debugging this script!
#set -x

EXIT_STATUS=0

function validate {
	SHA1_FILE="${1}"
        SHA1=`cat "${SHA1_FILE}"`

	SRC_FILE=${SHA1_FILE%.sha1}
	CHKSUM=`openssl sha1 -r "${SRC_FILE}" | sed 's/\([a-f0-9]*\).*/\1/'`

	if [ "$SHA1" != "$CHKSUM" ]
	then
		echo "Checkum for ${SRC_FILE} is invalid, found '${SHA1}' but expected '${CHKSUM}'."
		EXIT_STATUS=1
	fi
}

for f in `find . -name \*.sha1`
do
	validate $f
done

exit $EXIT_STATUS
