--[[
nixio - Linux I/O library for lua

Copyright 2009 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

$Id$
]]--

local nx = require "nixio", require "nixio.util"

module "nixio.io"

open			= nx.open
pipe			= nx.pipe
dup				= nx.dup
poll 			= nx.poll
poll_flags 		= nx.poll_flags
sendfile		= nx.sendfile
splice			= nx.splice
splice_flags	= nx.splice_flags