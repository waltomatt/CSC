csc.config.port = 13375 // The port you want to host the CSC Server on
csc.config.password = "abc12" // Secure password so other servers cannot spam your chat remotly (These must be the same across all servers)
csc.config.id = "RP1" // Unique server ID (visible in chat) so you can recognize your servers (This must differ on each server)
csc.config.alltext = false // Do you want all chat to be global?
csc.config.chatcmd = "/g" // If not, what do you want the chatcommand / prefix to be?
csc.config.faillimit = 3 // How many password failures before an IP ban (stops password bruteforce)

csc.config.showonsent = true // Show the global chat on the same server that sent it?

// Chat command only settings
csc.config.cooldown = 5 // Cooldown for global chat (in seconds)

csc.addServer("192.168.1.76", 13375) // Setup the first server, duplicate this for each entry

/* Setting up permissions / custom checks */
/* Un-comment examples to use them */

// Admin only (gmod default admin)

/*
csc.config.customcheck = function(ply)
	return ply:IsAdmin()
end
*/

// ULX Group check

/*
csc.config.customcheck = function(ply)
	return ply:IsUserGroup("ULXGROUPNAME")
end
*/

