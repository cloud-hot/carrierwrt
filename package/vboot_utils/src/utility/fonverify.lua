module("luci.fon.pkg.verify", package.seeall)
fonrsa = require "fonrsa"
posix = require "posix"

-- check signature file using fonrsa.so
function foncheckrsa(key, signature, file)
	if fonrsa.open(key) == false then
		return nil, "error opening public key file"
	end
	ret = fonrsa.verify(file, signature)
	fonrsa.close()
	return ret, nil
end

function cleanpath(file_1, file_2, file_3)
	if file_1 ~= nil then os.execute("rm " .. file_1) end
	if file_2 ~= nil then os.execute("rm " .. file_2) end
	if file_3 ~= nil then os.execute("rm " .. file_3) end
end

function extract_file(tgz_path)
	directory = os.tmpname()
	os.execute("rm " .. directory)
	if os.execute("mkdir " .. directory) ~= 0 then
		cleanpath(tgz_path, nil, nil)
		return nil, "error creating directory to extract to" .. path
	end
	if os.execute("tar -xzf" .. tgz_path .. " -C " .. directory) ~= 0 then
		return nil, "error extracting tgz"
	end
	cleanpath(tgz_path, nil, nil)
	return directory, nil
end

function verify_and_extract_file(tgz_path, signature_path, key_used)
	if key_used ~= nil then
		veredict, str = foncheckrsa(key_used, signature_path, tgz_path)
		if veredict == nil then
			cleanpath(signature_path, tgz_path, fonfile)
			return nil, str
		end
		if veredict == false then
			cleanpath(signature_path, tgz_path, fonfile)
			return nil, "Signature verification failed"
		end
	end
	directory = os.tmpname()
	os.execute("rm " .. directory)
	if os.execute("mkdir " .. directory) ~= 0 then
		cleanpath(signature_path, tgz_path, nil)
		return nil, "error creating directory to extract to" .. path
	end
	if os.execute("tar -xzf" .. tgz_path .. " -C " .. directory) ~= 0 then
		return nil, "error extracting tgz"
	end
	-- Check that the upgrade script exists and is executable
	local mode=posix.stat(directory .. "/upgrade", "mode")
	if mode == nil or mode:sub(3, 3) ~= "x" then
		return nil, "no upgrade script found"
	end

	cleanpath(signature_path, tgz_path, nil)
	return directory, nil
end

function verify_and_extract_tgz(tgzfile, key_directory)
	signature_path =  os.tmpname ()
	ret, key, flags = fonrsa.extract(tgzfile, signature_path)
	if (ret == false) then
		return nil, "error extracting signature from tgz"
	end
	key_used = key_directory .. "public_fon_rsa_key_" .. key .. ".pem"
	return verify_and_extract_file(tgzfile, signature_path, key_used)
end

function extract_unsigned_tgz(tgzfile)
	return verify_and_extract_file(tgzfile, nil, nil)
end

--
-- fonidentify returns filetype, key_number, error_string
--
-- being filetype:
--  nil in case of error (and error_string != nil)
--  one of:
--   reflash
--   hotfix
--   plugin
--   unsigned
-- and key_number one of
--  0..65536
--  or nil if filetype is unsigned
--
function fonidentify(tgzfile)
	return fonrsa.flags(tgzfile);
end

-- Verifies the signature in the .fon/.tgz file, extracts
-- the contents to a temporal directory, checks if
-- the restrictions contained in the file are met,
-- and executes the installation script if they are.
function fonverify(tgzfile, key_directory, allow_unsigned)
	filetype, key_number, error_string = fonidentify(tgzfile)
	if filetype == nil then
		return nil, error_string
	else 
		if filetype == "unsigned" and allow_unsigned == false then
			return nil, "unsigned tgz files not allowed"
		end
	end
	if filetype == "unsigned" then
		directory, str = extract_unsigned_tgz(tgzfile)
	else
		directory, str = verify_and_extract_tgz(tgzfile, key_directory)
	end
	if directory == nil then
		return nil, str
	end
	return directory, nil
end

function fonupgrade(directory)
	ret = os.execute("cd " .. directory .." && ./upgrade > /dev/null 2>&1")
	os.execute("rm -R " .. directory)
	return ret, nil
end

function dotest()
	dir, str = fonverify("example_plugin.tgz", "./", false)
	-- dir, str = fonverify("example.fon", "/home/pablo/fon/keys/")
	if dir == nil then
		print(str)
		return 1
	end
	print("Extracted dir is " .. dir)
	res, str = fonupgrade(dir)
	if res == 0 then
		print("OK")
	else
		print("something went wrong " .. res .. "")
	end
end

function doanothertest()
	filetype, key_number, error_string = fonidentify("example_plugin.tgz")
	if (error_string ~= nil) then
		print("Error " .. err)
	else
		if filetype == "unsigned" then
			print "unsigned"
		else
			print(filetype, " ", key_number)
		end
	end
end

function doposixtest()
	posix.chdir("/etc")
end

