if SERVER then
	include("csc/sv_csc_init.lua")
	AddCSLuaFile("csc/cl_csc_init.lua")
	AddCSLuaFile("csc/cl_csc_config.lua")
else
	include("csc/cl_csc_init.lua")
end