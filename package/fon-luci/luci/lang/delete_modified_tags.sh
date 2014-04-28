#!/bin/bash

for file in `ls *en.lua_changes`
do
	root_name=`echo $file|sed s/.en.lua_changes//`
	cat $file | while read tag
	do
	        for file in `ls ${root_name}.*.lua|grep -v en.lua`
        	do
                	cat $file|grep -v "^$tag =" > tmp.lua && mv tmp.lua $file
        	done
	done
done
