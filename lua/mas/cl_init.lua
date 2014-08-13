local gc 			= collectgarbage;
local memoryatstart	= gc("count");
local short_src 	= "mas/cl_init.lua";
-- need to add sensitivity changing

local ac = {
	hack	= {};
	crc 	= {};
	scrc	= {};
	newg	= {};
	InOrder	= {};
};

--[[------------------------------
	You can modify things here.
--------------------------------]]

ac.InitTime					= 0.1;
ac.StreamBytesPerSecond		= 1024*55; 			-- 55 kb/s
ac.TimerTime				= 5;				-- every 5 seconds the timer will run!
ac.IncomingMessageName		= "bobwasanalien";	-- the debug name for the net messages
													-- be sure to change this in mas.lua!
ac.EnableIndexCrcs			= true;				-- enable this if you want more protection (but this can indeed cause errors)

--[[------------------------------
	End modifications.
--------------------------------]]

--[[----------------
	Credits...
------------------]]
--		MeepDarknessMeep 	76561198050165746		Creating the whole thing from scratch
--		ShinyCow			76561198018779970		Helping with the binary flag with files


local rhook;		-- forward definition

local next 		= next;
local pairs 	= pairs;
local type 		= type;
local tostring	= tostring;
local tonumber	= tonumber;
local print 	= print;
local MsgC		= MsgC;
local crc		= util.CRC;
local funcinfo	= jit.util.funcinfo;
local getinfo	= debug.getinfo;
ac.check		= {
	"print", "Msg", "MsgC", "MsgN", "tostring", "type", "next", "pairs",
	"getmetatable", "setmetatable", "garbagecollect";
	debug		= {
		"getinfo", "getupvalue", "setupvalue", "getmetatable", "setmetatable"; 
	};
	util		= {
		"CRC";
	};
	jit			= {
		util		= {
			"funcinfo";
		};
	};
};

function ac.ToCrc(x)
	return tonumber(crc(x));
end

local Color = function(r,g,b,a)
	return {
		r = r or 255;
		g = g or 255;
		b = b or 255;
		a = a or 255;
	};
end
local function IsValid(x)
	return x and x.IsValid and x:IsValid();
end
_G.IsValid = IsValid;

ac.Color 		= Color(22, 160, 133);
ac.ColorWhite	= Color(255,255,255,255);

local function DebugPrint()
	if(false) then
		print(debug.traceback());
	end
end
local function print(...)
	ac.oldg.MsgC(ac.Color, "+KYAC+\t",...,"\n");
end

function ac.CopyTableN_l(tbl)
	DebugPrint();
	local ret = {};
	for k,v in next, tbl, nil do
		ret[k] = v;
	end
	return ret;
end

function ac.CopyTableP_l(tbl)
	DebugPrint();
	local ret = {};
	for k,v in pairs(tbl) do
		ret[k] = v;
	end
	return ret;
end

function ac.CopyTableP(tbl, dun)
	DebugPrint();
	if(not tbl) then return tbl; end
	local ret = {};
	local dun = dun or {};
	if(dun[tbl]) then return dun[tbl]; end
	dun[tbl] = ret;
	for k,v in pairs(tbl) do
		if(type(v) == "table") then
			ret[k] = ac.CopyTableN(v, dun);
			continue;
		end
		ret[k] = v;
	end
	return ret;
end

function ac.CopyTableN(tbl, dun)
	DebugPrint();
	if(not tbl) then return tbl; end
	local ret = {};
	local dun = dun or {};
	if(dun[tbl]) then return dun[tbl]; end
	dun[tbl] = ret;
	for k,v in pairs(tbl) do
		if(type(v) == "table") then
			ret[k] = ac.CopyTableP(v, dun);
			continue;
		end
		ret[k] = v;
	end
	return ret;
end

ac.newg = ac.CopyTableP(_G);
ac.oldg = ac.CopyTableP(_G);

print("Starting...");

function ac.IsEqual(f1, f2)
	DebugPrint();
	return f1 == f2 and tostring(f1) == tostring(f2) and _G.tostring(f1) == _G.tostring(f2) and _G.tostring(f1) == tostring(f2) and _G.tostring(f2) == tostring(f1);
end

function ac.PoopOnCrc(crc, x)
	DebugPrint();
	if(not ac.crc[crc]) then
		if(ac.DevMode) then print(tostring(x).."\t"..crc); end
		ac.crc[crc] 	= crc;
		ac.scrc[crc] 	= false;
		ac.InOrder[#ac.InOrder + 1] = crc;
	end
end


function ac.FuncCrc(func, k, bInit)
	DebugPrint();
	if(not func) then return 0; end
	local c = (k and k.."," or "");
	local dbg = getinfo(func);
	local isnumber = type(func) == "number";
	c = c..dbg.linedefined;
	c = c..","..dbg.currentline;
	c = c..","..(dbg.isvararg and "1" or "0");
	c = c..","..(dbg.namewhat or "-");
	c = c..","..dbg.lastlinedefined;
	c = c..","..dbg.source;
	c = c..","..dbg.nups;
	c = c..","..dbg.what;
	c = c..","..dbg.nparams;
	c = c..","..dbg.short_src;
	if(dbg.func ~= func and type(func) ~= "number") then
		c = c..",ne";
	end
	if(not dbg.func) then
		c = c..",nil";
	end
	if(ac.oldg.string.sub(ac.oldg.tostring(dbg.func), 1, 18) == "function: builtin#") then
		c = c..","..ac.oldg.string.sub(ac.oldg.tostring(dbg.func), 19)
	end
	return ac.oldg.tonumber(crc(c));
end
ac.PoopOnCrc(0x00000003, "strt");

function ac.CheckCFuncs(tbl, rtbl)
	DebugPrint();
	local rtbl = rtbl or _G;
	local tbl = tbl or ac.check
	for k,v in pairs(tbl) do
		if(type(v) == "table") then
			ac.CheckCFuncs(v, rtbl[k]);
		else
			ac.PoopOnCrc(ac.FuncCrc(rtbl[v], "ccf"), "ccf");
		end
	end
end

ac.CheckCFuncs();

function ac.GamemodeChecks()
	DebugPrint();
	for k,v in pairs(ac.oldg.gmod.GetGamemode() or {}) do
		if(type(v) == "function") then
			ac.PoopOnCrc(ac.FuncCrc(v, "GM::"..k), "GMChk");
		end
	end
end

function ac.IsGoodTarget(target)
	DebugPrint();
	return ac.oldg.string.sub(ac.oldg.debug.getinfo(target).short_src, -ac.oldg.string.len(short_src)) ~= short_src;
end

function ac.GetCrcInfo(v, x)
	DebugPrint();
	return ac.FuncCrc(v, x);
end
local b = false;

ac._G__mt = {
	__index = function(self, k)
		DebugPrint();
		if(ac.EnableIndexCrcs) then
			ac.PoopOnCrc(ac.GetCrcInfo(2, "iG"..k), "iG."..k);
		end
		ac.PoopOnCrc(ac.GetCrcInfo(2, "iG"), "iG");
		if(k == "hook") then
			return rhook;
		end
		return ac.oldg.rawget(self, k);
	end;
	__newindex = function(self, k, v)
		DebugPrint();
		if(k == "GM") then
			ac.oldg.setmetatable(v, {
				__index = function(self, k)
					DebugPrint();
					if(k == "CreateMove") then
						return ac.CreateMove;
					end
					ac.PoopOnCrc(ac.GetCrcInfo(2, "__index_GM_"..k), "iGM."..k);
					
					return;
				end;
				__newindex = function(self, k, v)
					DebugPrint();
					if(k == "CreateMove") then
						ac.PoopOnCrc(ac.GetCrcInfo(2, "CreateMove!"), "niGMC1");
						if(not ac.CreateMove) then
							ac.CreateMove = v;
							return;
						else
							ac.PoopOnCrc(ac.GetCrcInfo(2, "niGMC"), "niGMC");
							ac.CreateMove = function()
								error("Called createmove!", 2);
							end
							return;
						end
					end
					ac.PoopOnCrc(ac.GetCrcInfo(2, "__newindex"), "upniGM");
					return ac.oldg.rawset(self, k, v);
				end;
			});
		end
		if(ac.EnableIndexCrcs) then
			ac.PoopOnCrc(ac.GetCrcInfo(2, "__newindex_G."..k), "ni_G"..k); -- don't get mad, it means newindex _G
		end
		ac.PoopOnCrc(ac.GetCrcInfo(2, "__newindex_G"), "ni_G"); -- don't get mad, it means newindex _G
		if(k == "hook") then
			for k,v in pairs(v) do
				ac.PoopOnCrc(ac.FuncCrc(v, "hook."..k), "hook."..k);
				hook[k] = v;
			end
			return;
		end
		return ac.oldg.rawset(self, k, v);
	end;
};

local function _rawset(tbl, k, v)
	DebugPrint();
	if(tbl == rhook) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawset_hook"..k), "rgH");
		return;
	end
	if(tbl == _G) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawset_G"..k), "rgG");
		if(k == "hook") then
			ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawset_G_hook"..k), "rgGH");
			return;
		end
	end
	if(tbl == GM or tbl == GAMEMODE) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawsetGM"..k), "rsGM");
	end
	ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawset"..k), "rs"..k);
	return ac.oldg.rawset(tbl,k,v);
end
_G.rawset = _rawset;

local function _rawget(tbl, k)
	DebugPrint();
	if(tbl == hook) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawget_hook_"..k), "rgHook."..k);
		return hook[k]
	end
	if(tbl == _G) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawget_G"..k), "rgG."..k);
	end
	if(tbl == GM or tbl == GAMEMODE) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawgetGM"..k), "rgGM."..k);
	end
	ac.PoopOnCrc(ac.GetCrcInfo(2, "_rawget"), "rg"..k);
	return ac.oldg.rawget(tbl,k,v);
end
_G.rawget = _rawget;

local function _setmetatable(tbl, mt)
	DebugPrint();
	if(tbl == _G) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_smt_G"));
		return tbl;
	end
	if(tbl == GAMEMODE or tbl == GM) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_smtGM"));
		return tbl;
	end
	ac.PoopOnCrc(ac.GetCrcInfo(2), "upsmt");
	return ac.oldg.setmetatable(tbl, mt);
end
setmetatable = _setmetatable;


local function _getmetatable(tbl)
	DebugPrint();
	if(tbl == _G) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_gmt_G"), "gmtG");
	end
	if(tbl == GAMEMODE or tbl == GM) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_gmtGM"), "gmtG");
	end
	ac.PoopOnCrc(ac.GetCrcInfo(2), "upgmt");
	return ac.oldg.getmetatable(tbl);
end
getmetatable = _getmetatable;

local function debug_setmetatable(tbl, mt)
	DebugPrint();
	if(tbl == _G) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_dsmt_G"), "dsmtG");
		return tbl;
	end
	if(tbl == GAMEMODE or tbl == GM) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_dsmtGM"), "dsmtG");
		return tbl;
	end
	ac.PoopOnCrc(ac.GetCrcInfo(2), "updsmt");
	return ac.oldg.debug.setmetatable(tbl, mt);
end
debug.setmetatable = debug_setmetatable;

local function debug_getmetatable(tbl)
	DebugPrint();
	if(tbl == _G) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_dgmt_G"));
	end
	if(tbl == GAMEMODE or tbl == GM) then
		ac.PoopOnCrc(ac.GetCrcInfo(2, "_dgmtGM"));
	end
	ac.PoopOnCrc(ac.GetCrcInfo(2), "updgmt");
	return ac.oldg.debug.getmetatable(tbl);
end
debug.getmetatable = debug_getmetatable;

function require(str)
	DebugPrint();
	if(str == "hook" or str == "net") then
		return;
	end
	return ac.oldg.require(str)
end

ac.oldg.require("hook")

for k,v in pairs(hook.GetTable()) do
	ac.PoopOnCrc(0xFFFFFFFE, "hgt");
end

local hook = ac.CopyTableN(hook);
local ohook = ac.CopyTableN(hook);
local Hooks = {};

local hook_MT = {
	__index = function(self, k)
		ac.PoopOnCrc(ac.GetCrcInfo(2, "hook__i"..k), "hook__i");
		return hook[k];
	end;
	__newindex = function(self, k, v)
		ac.PoopOnCrc(ac.GetCrcInfo(2, "hook__ni"..k), "hook__ni");
		hook[k] = v;
	end;
};
rhook = ac.oldg.setmetatable({}, hook_MT);
_G.hook = nil;

local function hook_Remove(name, str)
	DebugPrint();
	ac.PoopOnCrc(ac.FuncCrc(func, tostring(name)..","..(type(str) == "string" and str or type(str))), "hook_Remove1");
	ac.PoopOnCrc(ac.GetCrcInfo(2, "hook_Remove"), "hook_Remove2");
	ohook.Remove(name,str);
end
rhook.Remove = hook_Remove;

local function hook_Add(name, str, func)
	DebugPrint();
	ac.PoopOnCrc(ac.FuncCrc(func, tostring(name)..","..(type(str) == "string" and str or type(str))),"hook_Add1");
	ac.PoopOnCrc(ac.GetCrcInfo(2, "hook_Add"),"hook_Add2");
	ohook.Add(name,str,func);
end
rhook.Add = hook_Add;

local function hook_GetTable()
	DebugPrint();
	ac.PoopOnCrc(ac.GetCrcInfo(2, "hook_GetTable"));
	return ac.CopyTableN(Hooks);
end
rhook.GetTable = hook_GetTable;

ac.oldg.require("net")
local net = ac.CopyTableN(net);

local function net_Receive(name, func)
	DebugPrint();
	if(ac.oldg.string.lower(name) == ac.oldg.string.lower(ac.IncomingMessageName)) then
		ac.PoopOnCrc(0x00000001);
		return;
	end
	net.Receivers[ac.oldg.string.lower(name)] = func;
end

_G.net.Receive = net_Receive;

local function net_Incoming(len, client)
	DebugPrint();
	local i = net.ReadHeader();
	local strName = ac.oldg.util.NetworkIDToString(i);
	--print(strName);
	
	if(not strName) then return end
	
	local func = net.Receivers[ac.oldg.string.lower(strName)];
	if(not func) then return end

	len = len - 16
	
	func(len, client)
end

_G.net.Incoming = net_Incoming


local function debug_getinfo(x, ...)
	DebugPrint();
	ac.PoopOnCrc(ac.GetCrcInfo(2, "print"));
	return ac.oldg.debug.getinfo(x, ...);
end
_G.debug.getinfo = debug_getinfo;
	

local function debug_getupvalue(x, y)
	DebugPrint();
	ac.PoopOnCrc(ac.GetCrcInfo(2, "debug_getupvalue"));
	local k, v = ac.oldg.debug.getupvalue(x, y);
	if(k == "ac" or v == ac or not ac.IsGoodTarget(x)) then
		return "bob", "he was a man, then turned into an alien";
	end
	return k,v;
end
_G.debug.getupvalue = debug_getupvalue;

local function debug_setupvalue(x, y, v)
	DebugPrint();
	local k,v = debug_getupvalue(x,y);
	if(k == "ac" or v == ac or not ac.IsGoodTarget(x)) then 
		ac.PoopOnCrc(0xFFFFFFFA, "debug_setupvalue");
		return;
	end
	return ac.oldg.debug.setupvalue(x,y,v);
end

local function _print(...)
	DebugPrint();
	ac.PoopOnCrc(ac.GetCrcInfo(2, "print"), "print");
	ac.oldg.print(...);
end
_G.print = _print;


local function MsgC(...)
	DebugPrint();
	ac.PoopOnCrc(ac.GetCrcInfo(2, "MsgC"), "MsgC");
	ac.oldg.MsgC(...);
end
_G.MsgC = MsgC;

local function Msg(...)
	DebugPrint();
	ac.PoopOnCrc(ac.GetCrcInfo(2, "Msg"), "Msg");
	ac.oldg.Msg(...);
end
_G.Msg = Msg;

local function MsgN(...)
	DebugPrint();
	ac.PoopOnCrc(ac.GetCrcInfo(2, "MsgN"), "MsgN");
	ac.oldg.MsgN(...);
end
_G.MsgN = MsgN;

local cmd = FindMetaTable("CUserCmd");
local real = {};
local ocmd = ac.CopyTableN(cmd);
for k,v in next, cmd, nil do
	ocmd[k] = v;
	cmd[k] = v;
	real[k] = v;
	if(k ~= "__index" and k ~= "__newindex" and k ~= "MetaID" and k ~= "MetaName") then
		ac.PoopOnCrc(ac.FuncCrc(v, "CUserCmd::"..k), "CUserCmd::"..k);
		local function new(cmd, ...)
			ac.PoopOnCrc(ac.GetCrcInfo(2, "CUserCmd::"..k), "upCUserCmd::"..k);
			return ocmd[k](cmd, ...);
		end
		cmd[k] 	= new;
		real[k] = new;
	end
end


function ac.timer()
	DebugPrint();
	local troo = {};
	for k,v in next, _G, nil do
		troo[k] = v;
	end
	for k,v in _G.pairs(_G) do
		if(troo[k] and v ~= troo[k]) then
			ac.PoopOnCrc(0xFFFFFFFF,"_G.pairs(_G)");
		end
	end
	for k,v in pairs(_G) do
		if(troo[k] and v ~= troo[k]) then
			ac.PoopOnCrc(0xFFFFFFFF, "pairs(_G)");
		end
	end
	if(not ac.IsEqual(net_Receive, _G.net.Receive)) then
		ac.PoopOnCrc(ac.ToCrc("nR~=_G.n.R") + ac.GetCrcInfo(_G.net.Receive) % 0x100000000, "nR~=_G.n.R");
	end
	if(not ac.IsEqual(net_Incoming, _G.net.Incoming)) then
		ac.PoopOnCrc(ac.ToCrc("nI~=_G.n.I") + ac.GetCrcInfo(_G.net.Incoming) % 0x100000000, "nI~=_G.n.I");
	end
	if(not ac.IsEqual(_rawset, _G.rawset)) then
		ac.PoopOnCrc(ac.ToCrc("_rawset~=_G.rawset") + ac.GetCrcInfo(_G.rawset) % 0x100000000, "_rawset~=_G.rawset");
	end
	if(not ac.IsEqual(_rawget, _G.rawget)) then
		ac.PoopOnCrc(ac.ToCrc("_rawget~=_G.rawget") + ac.GetCrcInfo(_G.rawget) % 0x100000000, "_rawget~=_G.rawget");
	end
	if(not ac.IsEqual(Msg, _G.Msg)) then
		ac.PoopOnCrc(ac.ToCrc("Msg~=_G.Msg") + ac.GetCrcInfo(_G.Msg) % 0x100000000, "Msg~=_G.Msg");
	end
	if(not ac.IsEqual(MsgC, _G.MsgC)) then
		ac.PoopOnCrc(ac.ToCrc("MsgC~=_G.MsgC") + ac.GetCrcInfo(_G.MsgC) % 0x100000000, "MsgC~=_G.MsgC");
	end
	if(not ac.IsEqual(MsgN, _G.MsgN)) then
		ac.PoopOnCrc(ac.ToCrc("MsgN~=_G.MsgN") + ac.GetCrcInfo(_G.MsgN) % 0x100000000, "MsgN~=_G.MsgN");
	end
	if(not ac.IsEqual(_print, _G.print)) then
		ac.PoopOnCrc(ac.ToCrc("print~=_G.print") + ac.GetCrcInfo(_G.print) % 0x100000000, "print~=_G.print");
	end
	if(not ac.IsEqual(debug_getinfo, _G.debug.getinfo)) then
		ac.PoopOnCrc(ac.ToCrc("debug_getinfo~=_G.debug.getinfo") + ac.GetCrcInfo(_G.debug.getinfo) % 0x100000000, "debug_getinfo~=_G.debug.getinfo");
	end
	if(not ac.IsEqual(debug_getupvalue, _G.debug.getupvalue)) then
		ac.PoopOnCrc(ac.ToCrc("debug_getupvalue~=_G.debug.getupvalue") + ac.GetCrcInfo(_G.debug.getupvalue) % 0x100000000, "debug_getupvalue~=_G.debug.getupvalue");
	end
	if(not ac.IsEqual(debug_setupvalue, _G.debug.setupvalue)) then
		ac.PoopOnCrc(ac.ToCrc("debug_setupvalue~=_G.debug.setupvalue") + ac.GetCrcInfo(_G.debug.setupvalue) % 0x100000000, "debug_setupvalue~=_G.debug.setupvalue");
	end
	if(not ac.IsEqual(debug_getmetatable, _G.debug.getmetatable)) then
		ac.PoopOnCrc(ac.ToCrc("debug_getmetatable~=_G.debug.getmetatable") + ac.GetCrcInfo(_G.debug.getmetatable) % 0x100000000, "debug_getmetatable~=_G.debug.getmetatable");
	end
	if(not ac.IsEqual(debug_setmetatable, _G.debug.setmetatable)) then
		ac.PoopOnCrc(ac.ToCrc("debug_setmetatable~=_G.debug.setmetatable") + ac.GetCrcInfo(_G.debug.setmetatable) % 0x100000000, "debug_setmetatable~=_G.debug.setmetatable");
	end
	if(not ac.IsEqual(_getmetatable, _G.getmetatable)) then
		ac.PoopOnCrc(ac.ToCrc("_getmetatable~=_G.getmetatable") + ac.GetCrcInfo(_G.getmetatable) % 0x100000000, "_getmetatable~=_G.getmetatable");
	end
	if(not ac.IsEqual(_setmetatable, _G.setmetatable)) then
		ac.PoopOnCrc(ac.ToCrc("_setmetatable~=_G.setmetatable") + ac.GetCrcInfo(_G.setmetatable) % 0x100000000, "_setmetatable~=_G.setmetatable");
	end
	if(not ac.IsEqual(hook_Add, _G.hook.Add)) then
		ac.PoopOnCrc(ac.ToCrc("hook_Add~=_G.hook.Add") + ac.GetCrcInfo(_G.hook.Add) % 0x100000000, "hook_Add~=_G.hook.Add");
	end
	if(not ac.IsEqual(hook_Remove, _G.hook.Remove)) then
		ac.PoopOnCrc(ac.ToCrc("hook_Remove~=_G.hook.Remove") + ac.GetCrcInfo(_G.hook.Remove) % 0x100000000, "hook_Remove~=_G.hook.Remove");
	end
	if(not ac.IsEqual(hook_GetTable, _G.hook.GetTable)) then
		ac.PoopOnCrc(ac.ToCrc("hook_GetTable=_G.hook.GetTable") + ac.GetCrcInfo(_G.hook.GetTable) % 0x100000000, "hook_GetTable=_G.hook.GetTable");
	end
	for k,v in pairs(real) do
		if(not cmd[k]) then
			ac.PoopOnCrc(0xFFFFFFFD, "nilcmd::"..k);
		end
		if(not ocmd[k]) then
			ac.PoopOnCrc(0xFFFFFFFC, "nilocmd::"..k);
		end
		if(cmd[k] ~= real[k]) then
			ac.PoopOnCrc(0xFFFFFFFB, "cmd~=real,"..k);
			ac.PoopOnCrc(ac.GetCrcInfo(cmd[k]), "cmdinfo::"..k);
		end
	end
	ac.oldg.timer.Simple(ac.TimerTime, ac.timer);
end

function ac.DataTimer()
	DebugPrint();
	local amt = ac.StreamBytesPerSecond / 10;
	net.Start(ac.IncomingMessageName);
	local cur = 0;
	for i, crc in ac.oldg.ipairs(ac.InOrder or {}) do
		if(ac.scrc[crc]) then continue; end
		net.WriteUInt(crc, 32);
		ac.scrc[crc] = true;
		cur = cur + 1;
		if(cur * 4 > amt) then break; end
	end
	net.SendToServer();
	ac.oldg.timer.Simple(0.1, ac.DataTimer);
end

timer.Simple(ac.InitTime, function()
	DebugPrint();
	ac.DataTimer();
	ac.timer();
end);


ac.CheckCFuncs();
ac.oldg.setmetatable(_G, ac._G__mt);

ac.PoopOnCrc(ac.ToCrc(memoryatstart));
ac.PoopOnCrc(0x00000002, "end");
