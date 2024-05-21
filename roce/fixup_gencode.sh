#!/bin/bash
# Fixup generated code output
#
# Usage: $0 <p4name> i.e. no file extension; e.g. $0 routing
#
# remove permissions from .template e.g.:
#       in:  keysz 32 nummasks 8 permissions 0x3da4 tentries 2048 \
#       out: keysz 32 nummasks 8 tentries 2048 \

echo "Fixing up $1.template; backup in $1.template.bak"
sed -i.bak -e 's/\(^.*\)permissions 0x[a-f0-9]* \(.*$\)/\1\2/' $1.template

# remove permissions from .json
#       in:       "permissions" : "0x3da4",
#       out:

echo "Fixing up $1.json; backup in $1.json.bak"
sed -i.bak -e'/"permissions" :/d' $1.json