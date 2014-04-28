#!/bin/sh
for a in `ls *`; do
	B=`echo $a | cut -d. -f2`
	[ "$B" == "sh" ] || rm $a
done
