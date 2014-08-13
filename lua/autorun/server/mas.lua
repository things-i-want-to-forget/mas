ac 				= {
	crcs 	= {};
	rcrcs	= {};
};
ac.AddHook 		= hook.Add; -- backwards compat



--[[------------------------------
	You can modify things here.
--------------------------------]]

ac.RestrictQuickMovements	= true;						-- sometimes a bit buggy, change to false if your aim jitters everywhere
ac.IncomingMessageName		= "bobwasanalien";			-- remember to change this on the client!
ac.BaseOffSteamID			= "STEAM_0:0:000000000000000"; 	-- SET THIS TO YOURS! used to make the crc table to check for cheats
ac.Timeout					= 30;
ac.BetaMode					= true;
ac.CmdsMissed					= 20;

function ac.Destroy(ply, message)
	if(not ac.Enabled) then return; end
	if(ac.BetaMode) then
		file.Append("mas/beta_log.txt", ply:Nick().." <"..ply:SteamID().."> has triggered ac.Destroy! Reason: "..message.."\r\n");
	else
		ply:Kick(message);									-- change this to whatever you want to do to punish them
	end
end


--[[------------------------------
	End modifications.
--------------------------------]]
util.AddNetworkString(ac.IncomingMessageName);


concommand.Add("set_crc", function(ply, cmd, args, str)
	if(IsValid(ply) and ply:SteamID() == ac.BaseOffSteamID) then
		ac.WriteCrcs(ply.InOrder);
		ac.Enabled = true;
		ply:ChatPrint("done.");
	end
end);

concommand.Add("disable_mas", function(ply, cmd, args, str)
	if(not IsValid(ply) or IsValid(ply) and ply:SteamID() == ac.BaseOffSteamID) then
		ac.Enabled = false;
	end
end);


ac.AddHook("PlayerInitialSpawn", "CheckReceive", function(ply)
	timer.Simple(ac.Timeout, function()
		if(IsValid(ply) and not ply:IsBot() and (not ply.Crcs or not ply.Crcs[0x00000002] or not ply.Crcs[0x00000003])) then
			ac.Destroy(ply, "MAS - Something went wrong! ERROR_2");
		end
	end);
end);

net.Receive(ac.IncomingMessageName, function(len, clnt)
	clnt.Crcs = clnt.Crcs or {};
	clnt.InOrder = clnt.InOrder or {};
	local len = len / 32;
	for i = 1, len do
		local crc = net.ReadUInt(32);
		print(crc)
		if(#clnt.InOrder == 0 and crc ~= 3) then
			--print(i, clnt.InOrder[1], ac.crcs[i]);
			ac.Destroy(clnt, "MAS - Something went wrong! - ERROR_1_"..crc);
			return;
		end
		if(crc == 2) then
			for b = 1, #ac.crcs do
				if(ac.crcs[b] == 2) then break; end
				if(clnt.InOrder[b] ~= ac.crcs[b]) then
					ac.Destroy(clnt, "MAS - Something went wrong! - ERROR_"..tostring(b).."_"..tostring(clnt.InOrder[b]));
				end
			end
		end
		table.insert(clnt.InOrder, crc);
		clnt.Crcs[crc] = crc;
		if(not ac.rcrcs[crc] and ac.Enabled) then
			print(#clnt.Crcs, ac.rcrcs[crc], crc);
			ac.Destroy(clnt, "MAS - Something went wrong! - ERROR_3_"..crc);
		end
	end
end);

FindMetaTable("Angle").Difference = function(x,y)
	return math.abs(math.AngleDifference(x.y, y.y)) + math.abs(math.AngleDifference(x.p, y.p));
end

local retn = false

local function Log(x)
	if(false) then return; end
	file.Append("mas/test_log.txt", x.."\r\n");
end

ac.AddHook("Move", "RestrictHacks", function(ply, mv)
	if(ply:IsBot()) then return; end
	if(retn) then retn = false; return true; end
	if(CurTime() - (ply.LastMove or -111) < engine.TickInterval()- 0.004) then
		return true;
	end
	ply.LastMove = CurTime();
	if(ply == LOG_PLY and LOG_NUM and LOG_NUM > 1) then Log(mv:GetMoveAngles()); LOG_NUM = LOG_NUM - 1; end
	if(ac.RestrictQuickMovements and mv:GetMoveAngles():Difference((ply.LastAngles or Angle(0,0,0))) > 80 and Angle(0,0,0) ~= mv:GetMoveAngles()) then
		mv:SetMoveAngles(ply.LastAngles or Angle(0,0,0));
		ply.LastAngles = ply.LastAngles;
		ply:SetEyeAngles(ply.LastAngles or Angle(0,0,0));
		return true;
	end
	ply.LastAngles = mv:GetMoveAngles();
end);

local cur = 0;
local max = 30;

ac.AddHook("SetupMove", "RestrictHacks", function(ply, mv, cmd)
	if(ply:IsBot()) then return; end
	ply.CmdsMissed = ply.CmdsMissed or -1;
	cur = (cur + 1) % max;
	if(cur == 0) then ply.CmdsMissed = math.max(-1, ply.CmdsMissed - 1); end
	if(cmd:CommandNumber() ~= ply.PredictedCmd) then
		--print("Missed");
		ply.CmdsMissed = ply.CmdsMissed + 1;
		if(ply.CmdsMissed > ac.CmdsMissed) then
			ac.Destroy(ply, "MAS - Something went wrong! ERROR_2");
		end
		retn = true;
	end
	ply.PredictedCmd = cmd:CommandNumber() + 1;
end);

function ac.WriteCrcs(crcs)
	file.CreateDir("mas")
	local f = file.Open("mas/crc_list.txt", "wb", "DATA");
	for i = 1, #crcs do
		f:WriteLong(crcs[i])
	end
	f:Close();
end

function ac.ReloadCrcs()
	local crcs = {}
	local rcrcs = {};
	if(not file.IsDir("mas", "DATA")) then
		file.CreateDir("mas");
	end
	local f = file.Open("mas/crc_list.txt", "rb", "DATA");
	if(not f) then return crcs, rcrcs; end
	for i = 4, f:Size() + 3, 4 do
		crcs[i / 4] = f:ReadLong();
		if(not crcs[i/4]) then continue; end
		rcrcs[crcs[i / 4]] = crcs[i/4];
	end
	timer.Simple(0.05, function()
		f:Close();
	end);
	return crcs,rcrcs;
end

if(not file.Exists("mas/crc_list.txt", "DATA")) then
	ac.Enabled = false;
else
	ac.crcs, ac.rcrcs = ac.ReloadCrcs();
	ac.Enabled = true;
end
