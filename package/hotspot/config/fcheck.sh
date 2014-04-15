#!/bin/sh
#
#  fcheck - Check whether the hotspot daemon components are still running.
#
#  Copyright (C) 2011 Bart Van Der Meerssche <bart.vandermeerssche@hotspot.net>
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

STATUS=0

[ -z "$(ps | grep 'hotspot[d]')" ] && STATUS=2

[ -z "$(ps | grep 'sup[d]')" ] && STATUS=4

[ $STATUS -ne 0 ] && /etc/init.d/hotspot restart
