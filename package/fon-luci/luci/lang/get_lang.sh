#!/bin/sh

for a in `find .. -name '*.en.lua' | grep applications`; do cp `dirname $a`/*.lua .; done
for a in `find .. -name 'cbi.*.lua'  | grep i18n`; do cp $a . ; done
for a in `find .. -name 'default.*.lua'  | grep i18n`; do cp $a . ; done

rm -rf fon_livestats.* ftp.* samba.*
