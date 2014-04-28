for a in `ls *.lua `; do A=`find ../ -name $a | grep -v lang | grep -v \.svn`; [ -z "$A" ] && echo $a; [ -z "$A" ] || cp $a $A;  done
