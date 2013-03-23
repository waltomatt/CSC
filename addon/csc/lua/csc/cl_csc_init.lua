csc = {}
csc.config = {}

include("cl_csc_config.lua")

net.Receive("csc.newMessage", function()
	local id = net.ReadString()
	local name = net.ReadString()
	local text = net.ReadString()

	chat.AddText(Color(25, 25, 220), "["..id.."] ", Color(25, 220, 25), name..": ", Color(235, 235, 235), text)
end)