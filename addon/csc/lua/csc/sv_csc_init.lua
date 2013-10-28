/*
	Made by Matt Walton
	matt-walton.net
*/

/* Do not edit below this line unless you know what you're doing */
// Sorry I really suck at commenting :(

util.AddNetworkString("csc.newMessage")

csc = {} // Keep everything organized in a nice table
csc.config = {}
csc.config.servers = {}
csc.bannedips = {}
csc.bipl = {}

csc.playerCooldowns = {} // neatening up the player variables
csc.storedMessages = {};

local CSC_ACTION_MESSAGE    = 0;
local CSC_ACTION_GET        = 1;

function csc.addServer(host, port)
	table.insert(csc.config.servers, {host = host, port= port})
end

include("sv_csc_config.lua") // include the configuration file

require("glsock2")

if !GLSock then
	MsgC(Color(255, 20, 20), "[CSC]: GLSOCK NOT FOUND, CSC CAN NOT RUN.\n")
	return
end

function csc.print(text, err)
	if err then
		MsgC(Color(255, 20, 20), "[CSC]: "..text.."\n")
	else
		MsgC(Color(20, 255, 20), "[CSC]: "..text.."\n")
	end
end

function csc.receive(sock, client, err)
	if (err == GLSOCK_ERROR_SUCCESS) then
		local ip = client:RemoteAddress() // Get client IP
		local res = GLSockBuffer() // Setup the response buffer

		if (table.HasValue(csc.bannedips, ip)) then // Check if the IP is on our ban list
			res:WriteString("banned")
			client:Send(res, function()  // If so, close their connection
				client:Close()
			end)
		else

			client:Read(1024, function(_, buff, err)  // Read the clients request
				if (err == GLSOCK_ERROR_SUCCESS) then

					local _, resp = buff:Read(buff:Size())
					resp = string.Explode("\n", resp)
                    local pass, ty, id = resp[1], tonumber(resp[2]), resp[3];

					if (pass == csc.config.password) then // Check password

						if (ty == CSC_ACTION_MESSAGE) then
                            local name,  text = resp[4], resp[5]

                            if (name and text) then

                                csc.print("Received message from "..id.." ("..ip.."): "..text)
    					        res:WriteString("success")
    						    csc.doMessage(id, name, text) // Send message to clients

                                table.insert(csc.storedMessages, {
                                    name = name,
                                    server = csc.config.id,
                                    time = os.date(),
                                    message = text
                                });

                            end

                        elseif (ty == CSC_ACTION_GET) then
                            local max = tonumber(resp[4]);

                            csc.print("Sending recent messages");

                            local ordered = {};
                            local max = #csc.storedMessages;

                            for k, __ in pairs(csc.storedMessages) do
                                if (k <= max) then
                                    table.insert(ordered, csc.storedMessages[max-k]);
                                else
                                    break;
                                end
                            end

                            res:WriteString(util.TableToJSON(ordered));
                        end

					else
						csc.print("Invalid remote password from "..ip) // Decline due to invalid password
						res:WriteString("invalid-password")
						csc.bipl[ip] = csc.bipl[ip] or 0
						csc.bipl[ip] = csc.bipl[ip] + 1

						if (csc.bipl[ip] >= csc.config.faillimit) then
							csc.addBan(ip)
						end
					end

					client:Send(res, function() // Send the client our response
						client:Close()
					end)
				end
			end)
		end

		if (err ~= GLSOCK_ERROR_OPERATIONABORTED) then // Continue with our operations
			sock:Accept(csc.receive)
		end
	end
end

function csc.onListen(sock, err)
	if err == GLSOCK_ERROR_SUCCESS then
		sock:Accept(csc.receive) // Start accepting requests
		csc.print("Listening on port "..csc.config.port)
	else
		csc.print("Failed to listen on port "..csc.config.port, true)
	end
end

function csc.init()
	csc.sock = GLSock(GLSOCK_TYPE_ACCEPTOR)
	csc.sock:Bind("", csc.config.port, function(sock, err)
		if (err == GLSOCK_ERROR_SUCCESS) then
			csc.print("Successfully bound to port "..csc.config.port)
			sock:Listen(0, csc.onListen) // Start listening on our port
		else
			csc.print("Failed to bind to port "..csc.config.port, true)
		end
	end)

	csc.loadBans()
end

function csc.encodeMessage(msg)
    return string.Implode("\n", msg)
end

function csc.sendMessage(text, ply)
	local buff = GLSockBuffer()
	local nick = ply:Nick()
    local steamid = ply:SteamID()

	local msg = csc.encodeMessage({csc.config.password, CSC_ACTION_MESSAGE, csc.config.id, nick, steamid, text});

	buff:WriteString(msg) // Prepare buffer

	for k,v in pairs(csc.config.servers) do	// Loop through our servers
		local sock = GLSock(GLSOCK_TYPE_TCP)
		sock:Connect(v.host, v.port, function(sock, err) // Connect to the remote server
			if (err == GLSOCK_ERROR_SUCCESS) then
				sock:Send(buff, function(_, _, err) // Send buffer to a remote server
					if err ~= GLSOCK_ERROR_SUCCESS then
						csc.print("Failed sending data to remote server")
					end
					sock:Close()
				end)
			end
		end)
	end
end

function csc.loadBans()
	if file.Exists("csc_bannedips.txt", "DATA") then
		local str = file.Read("csc_bannedips.txt", "DATA")
		csc.bannedips = string.Explode("\n", str)
		csc.print("Loaded banned IPs")
	end
end

function csc.addBan(ip)
	table.insert(csc.bannedips, ip)
	file.Write("csc_bannedips.txt", string.Implode("\n", csc.bannedips))
	csc.print("Banned IP: "..ip)
end

function csc.doMessage(id, name, text, force)
	if (id == csc.config.id and !force) then return end

	net.Start("csc.newMessage")
		net.WriteString(id)
		net.WriteString(name)
		net.WriteString(text)
	net.Broadcast()
end

hook.Add("PlayerSay", "csc.playerSay", function(ply, text)
	if (csc.config.alltext) then
		csc.sendMessage(text, ply) // All messages are global, continue
	else
		local _ttab = string.Explode(" ", text) // Explode the string so we can grab the first word
		if (_ttab[1]:lower() == csc.config.chatcmd) then // If the first word is our designated cmd
			table.remove(_ttab, 1)
			local text = string.Trim(string.Implode(" ", _ttab))

			if (text != "") then
				csc.playerCooldowns[ply] = csc.playerCooldowns[ply] or 0

				if (csc.playerCooldowns[ply] > CurTime()) then // Check cooldown
					ply:ChatPrint("You cannot use global chat for another "..math.ceil(csc.playerCooldowns[ply] - CurTime()).." seconds!")
					return ""
				end

				if (csc.config.customcheck and !csc.config.customcheck(ply)) then // Check custom checks
					ply:ChatPrint("You cannot use global chat!")
					return ""
				end

				csc.sendMessage(text, ply) // send the message to the servers
				if (csc.config.showonsent) then
					csc.doMessage(csc.config.id, ply:Nick(), text, true)
				end

                table.insert(csc.storedMessages, {
                    name = ply:Nick(),
                    server = csc.config.id,
                    time = os.date(),
                    message = text
                });

				csc.playerCooldowns[ply] = CurTime() + csc.config.cooldown // Add the cooldown timer
			end
			return ""
		end
	end
end)

csc.init() // Initialize the whole script
