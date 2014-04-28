#!/bin/bash

M_LANG="en"

./clean.sh
./get_lang.sh

grep '<%:' ../* -r | grep -v svn | grep -v template.lua | sed "s/.*<%:\(.*\)%>.*/\1/g" | tr '%' " "| cut -d" " -f1 | sort | uniq > .all_tags
grep translate\(\" ../* -r | grep -v svn | grep -v template.lua | sed "s/.*translate(\"\(.*\)\".*/\1/g" | tr \" " " | cut -d " " -f1 | sort | uniq >>.all_tags
cat .all_tags | sort | uniq >all_tags

rm .all_tags

echo total tags : `wc -l all_tags`

rm -f missing_tags

for a in `cat all_tags`; do
	A=`grep $a *.${M_LANG}.lua`
	[ -z "$A" ] && echo $a >> missing_tags
done

echo missing tags : `wc -l missing_tags`

for a in `cat missing_tags`; do echo -n "$a = \""; egrep "(<%:$a|translate\(\"$a\")" ../*  -r| grep -v svn | grep -v lang | grep -v i18n | sed "s/.*$a\(.*\).*/\1/g" | sed "s/\", \"//g"| sed "s/\"))//g";echo "";done > merge

echo tags ready for merging : `wc -l merge`
for a in `cat default.${M_LANG}.lua | cut -d= -f1`; do [ -z "$(grep ^$a all_tags)" ] && echo $a ; done > toomuch
echo tags too much `wc -l toomuch`

