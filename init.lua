-- -- load credentials, 'SSID' and 'PASSWORD' declared and initialize in there
dofile("wificonf.lua")
-- function startup()
    -- if file.open("init.lua") == nil then
        -- print("init.lua deleted or renamed")
    -- else
        -- file.close("init.lua")
        -- -- the actual application is stored in 'application.lua'
		-- dofile("server.lua")
        -- dofile("zvonek.lua")
		-- server(80, function(method, path, params, client_ip)
		  -- if path == "/" then
			-- local html = interpolate_string("<h1>Your ip is ${ip}</h1>", {ip = client_ip})
			-- return 200, html, "text/html"
		  -- end
		  -- return 404
		-- end)
		-- tmr.alarm(1, 1000, tmr.ALARM_AUTO, function() 
		  -- if wifi.sta.getip() == nil then 
			-- print("Waiting for IP ...") 
		  -- else 
			-- print("IP is " .. wifi.sta.getip())
			-- tmr.stop(1)
		  -- end
		-- end)
    -- end
-- end
-- print("Probiha pripojovani k siti WiFi...")
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, HESLO)
wifi.sta.connect() --not necessary because config() uses auto-connect=true by default
-- tmr.alarm(2, 1000, 1, function()
    -- if wifi.sta.getip() == nil then
        -- print("Cekani na odpoved serveru...")
    -- else
        -- tmr.stop(2)
        -- print("Spojeni navazano, IP adresa: " .. wifi.sta.getip())
		-- print("Probiha pripojovani k NTP serveru a synchronizace casu...")
		-- sntp.sync({"0.cz.pool.ntp.org","1.cz.pool.ntp.org","2.cz.pool.ntp.org","3.cz.pool.ntp.org"},
		-- function(sec, usec, server, info)
			-- print("Uspesna synchronizace, cas od UNIX epochy:", sec, usec,", pouzity server:", server,", dalsi informace:", info)
		-- end,
		-- function()
			-- print("Selhala synchronizace s NTP!")
			-- tmr.stop(1)
		-- end
		-- )
		-- tmr.alarm(1, 1000, 1, function()
			-- if rtctime.get() == 0 then
				-- print("Cekani na odpoved NTP serveru...")
			-- else
				-- tmr.stop(1)
			-- end
		-- end)
		-- print("Pro preruseni zavadeni systemu stisknete libovolnou klavesu...")
		-- tmr.alarm(0, 3000, 0, startup)
    -- end
-- end)
tmr.register(0, 5000, tmr.ALARM_SINGLE, 
function() 
    print("System Info:  ")
    print("IP: ")
    print(wifi.sta.getip())
    majorVer, minorVer, devVer, chipid, flashid, flashsize, flashmode, flashspeed = node.info();
    print("NodeMCU "..majorVer.."."..minorVer.."."..devVer.."\nFlashsize: "..flashsize.."\nChipID: "..chipid)
    print("FlashID: "..flashid.."\n".."Flashmode: "..flashmode.."\nHeap: "..node.heap())
    -- get file system info
    remaining, used, total=file.fsinfo()
    print("\nFile system info:\nTotal : "..total.." Bytes\nUsed : "..used.." Bytes\nRemain: "..remaining.." Bytes")
    print("\nReady") 
    tmr.stop(0)
    dofile("servernode.lua") 
end)
if not tmr.start(0) then print("Timer error") end  
print("timer started") 