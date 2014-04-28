#!/bin/sh
MLANG="en"
LANG="de es fr it en eu hu nl zh ca pl pt ja zh-cn"
FILES="backup cbi default torrent youtube browser ddns firewall dlmanager picasa flickr facebook wizard_fonera2"

#LANG="de"

for f in $FILES; do
	for l in $LANG; do
		touch ${f}.${l}.lua
	done
	echo "checking $f"
	grep "=" "${f}.${MLANG}.lua" | cut -d " " -f1 > $f

	for l in $LANG; do
		for tag in `cat $f`; do
			grep "^${tag} " ${f}.${l}.lua > /dev/null
			if [ $? -ne 0 ]; then
				echo ${tag} missing from ${f}.${l}.lua
				A=`grep "${tag} \=" ${f}.en.lua`
				if [ -z "$A" ]; then
					echo ${tag} = >> ${f}.${l}.lua.missing
				else
					echo $A >> ${f}.${l}.lua.missing	
				fi
			fi
		done
	done
done
