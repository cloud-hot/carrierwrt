module("luci.fon.pkg.verify", package.seeall)
fonrsa = require "fonrsa"
posix = require "posix"


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

function verify_and_extract_file(in_tgz_path, signature_path, key_used)
	out_tgz_path = in_tgz_path
	directory = os.tmpname()
	os.execute("rm " .. directory)
	if os.execute("mkdir " .. directory) ~= 0 then
		cleanpath(signature_path, tgz_path, nil)
		return nil, "error creating directory to extract to" .. path
	end

	if key_used ~= nil then
		out_tgz_path = directory .. "/firmware.tgz"
		-- check signature file using fonrsa.so
		veredict = fonrsa.verify(in_tgz_path, signature_path, out_tgz_path)
		if veredict == nil then
			cleanpath(signature_path, tgz_path, nil)
			return nil, nil
		end
		if veredict == false then
			cleanpath(signature_path, tgz_path, nil)
			return nil, "Signature verification failed"
		end
	end

	if os.execute("tar -xzf" .. out_tgz_path .. " -C " .. directory) ~= 0 then
		return nil, "error extracting tgz"
	end
	-- Check that the upgrade script exists and is executable
	local mode=posix.stat(directory .. "/upgrade", "mode")
	if mode == nil or mode:sub(3, 3) ~= "x" then
		return nil, "no upgrade script found"
	end

	cleanpath(signature_path, tgz_path, out_tgz_path)
	return directory, nil
end

function verify_and_extract_tgz(tgzfile, key_directory)
	signature_path = key_directory .. "public_fon_firmware_update.pem"
	return verify_and_extract_file(tgzfile, signature_path, true)
end

function extract_unsigned_tgz(tgzfile)
	return verify_and_extract_file(tgzfile, nil, nil)
end

-- Verifies the signature in the .fon/.tgz file, extracts
-- the contents to a temporal directory, checks if
-- the restrictions contained in the file are met,
-- and executes the installation script if they are.
function fonverify(tgzfile, key_directory, filetype)
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
	dir, str = fonverify("firmware.fon", "./", "signed")
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
	dir, str = fonverify("firmware.fon", "./", "unsigned")
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

function doposixtest()
	posix.chdir("/etc")
end

