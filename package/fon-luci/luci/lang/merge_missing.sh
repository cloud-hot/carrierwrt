#!/bin/bash

LANGS=( `ls default.*.lua|cut -d. -f2` )

for lang in ${LANGS[*]}
do
	for name in `ls *.${lang}.lua`
	do
		REF=`echo $name|sed s/${lang}.lua/en.lua/`
		[ -e ${name}.missing ] && if [  $(wc -l $REF |cut -d\  -f1) -eq $(expr $(wc -l $name|cut -d\   -f1) + $(wc -l ${name}.missing|cut -d\   -f1) ) ]
		then
			cat ${name}.missing ${name}| sort > ${name}.tmp; mv ${name}.tmp $name
		else
			echo "Please merge manually ${name}.missing"
		fi
	done
done
