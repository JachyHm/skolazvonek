-- load credentials, 'SSID' and 'PASSWORD' declared in wificonf and initialize in there
SSID = "EMtest"
HESLO = "13znakudlouhe"
dofile("wificonf.lua")
gpio.mode(1,gpio.OUTPUT) -- inicializace halvního programu a následně pokud svítí, tak je aktivované ztišení
gpio.mode(5,gpio.OUTPUT) -- připojení k WiFi síti a následně pokud svítí, tak už se nebude zvonit
gpio.write(1, gpio.HIGH)
gpio.write(5, gpio.HIGH)
pendingRequestOnTimeSync = false
blikej = false
tz = require('tz')
tz.setzone('Bratislava')
-- print(tz.getzones())
emModeFile = file.open("emergencyMode.stav","r")
if emModeFile then
	emergencyMode = emModeFile:readline()
	if emergencyMode == "true" then
		emergencyMode = true
	else
		emergencyMode = false
	end
	emModeFile:close(); emModeFile = nil
else
	emergencyMode = false
	emModeFile = file.open("emergencyMode.stav","w")
	emModeFile:writeline("false")
	emModeFile:close(); emModeFile = nil
end
chybaWiFi = false
uzJeNTP = false
function startup()
	-- the actual application is stored in 'zvonek.lua'
	gpio.mode(2,gpio.OUTPUT)
	gpio.write(2, gpio.HIGH)
	dofile("zvonek.lua")
end
print("Probiha pripojovani k siti WiFi...")
wifi.sta.clearconfig()
wifi.nullmodesleep(false)
wifi.sta.sleeptype(wifi.NONE_SLEEP)
wifi.setmode(wifi.STATIONAP,true)
wifi.setphymode(wifi.PHYMODE_G,true)
print("SSID: "..SSID.." HESLO: "..HESLO)
station_cfg={}
station_cfg.ssid=SSID
station_cfg.pwd=HESLO
station_cfg.auto=false
wifi.sta.config(station_cfg)
wifi.sta.connect()
poleAP = {}
poleAP.ssid = "ZvonekNahraj"
poleAP.pwd = "asdfasdf"
poleAP.auth = wifi.WPA2_PSK
wifi.ap.config(poleAP)
collectgarbage()
wifi.ap.setip({ip="10.10.10.0",netmask="255.255.255.0",gateway="10.10.10.10"})
dhcp_config ={}
dhcp_config.start = "10.10.10.1"
wifi.ap.dhcp.config(dhcp_config)
wifi.ap.dhcp.start()
print(wifi.ap.getip())
print("\nAktualni konfigurace:")
for k,v in pairs(wifi.ap.getconfig(true)) do
	print(k.." :",v)
end
tmr.alarm(0,500,1,function() -- az pokud Hostname == Zvonek
	if wifi.sta.gethostname() ~= "Zvonek" then
		wifi.sta.sethostname("Zvonek")
		print(wifi.sta.gethostname())
	else
		tmr.unregister(0)
		wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T) 
			if not chybaWiFi then
				if T.reason == 202 or T.reason == 201 or T.reason == 2 then
					tmr.alarm(6, 500, 1, function()
						if wifi.sta.getip() == nil then
							chybaWiFi = true
							blikej = true
							emergencyMode = true
						else
							chybaWiFi = false
							tmr.unregister(6)
							blikej = false
							emergencyMode = false
						end
					end)
					tmr.unregister(2)
					dofile("zvonek.lua")
				end
			end
		end)
		tmr.alarm(2, 1000, 1, function()
			if wifi.sta.getip() == nil then
				print("Cekani na odpoved serveru... ("..wifi.sta.status()..")")
				wifi.eventmon.register(wifi.eventmon.STA_DISCONNECTED, function(T) print(T.reason) end)
			else
				gpio.write(5, gpio.LOW)
				tmr.unregister(2)
				print("Spojeni navazano, IP adresa: " .. wifi.sta.getip())
				print("Probiha pripojovani k NTP serveru a synchronizace casu...")
				tmr.alarm(4,1000,1,function()
					sntp.sync({"tik.cesnet.cz","tak.cesnet.cz"},
						function(now)
							print(now)
							local tm = rtctime.epoch2cal(now + tz.getoffset(now))
							-- print("Uspesna synchronizace, cas od UNIX epochy:", sec, usec,", pouzity server:", server,", dalsi informace:", info)
							tmr.unregister(4)
							tmr.unregister(6)
							gpio.write(5, gpio.LOW)
							gpio.write(1, gpio.HIGH)
							uzJeNTP = true
						end,
						function()
							print("Selhala synchronizace s NTP!")
							tmr.alarm(6, 200, 1, function()
								if citac ~= 1 then
									gpio.write(5, gpio.HIGH)
									gpio.write(1, gpio.LOW)
									citac = 1
								else
									gpio.write(5, gpio.LOW)
									gpio.write(1, gpio.HIGH)
									citac = 0
								end
							end)
						end
					)
				end)
				tmr.alarm(1, 1000, 1, function()
					if rtctime.get() ~= 0 and uzJeNTP then
						tmr.unregister(1)
						print("Pro preruseni zavadeni systemu stisknete libovolnou klavesu...")
						tmr.alarm(0, 3000, 0, startup)
					else
						print("Cekani na odpoved NTP serveru...")
					end
				end)
			end
		end)
	end
end)