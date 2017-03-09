-- -- load credentials, 'SSID' and 'PASSWORD' declared and initialize in there
dofile("wificonf.lua")
selhalaNTP = false
function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        file.close("init.lua")
        -- the actual application is stored in 'application.lua'
        dofile("zvonek.lua")
    end
end

print("Probiha pripojovani k siti WiFi...")
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, HESLO)
wifi.sta.connect() --not necessary because config() uses auto-connect=true by default
tmr.alarm(2, 1000, 1, function()
    if wifi.sta.getip() == nil then
        print("Cekani na odpoved serveru...")
    else
        tmr.stop(2)
        print("Spojeni navazano, IP adresa: " .. wifi.sta.getip())
		print("Probiha pripojovani k NTP serveru a synchronizace casu...")
		sntp.sync({"tik.cesnet.cz","tak.cesnet.cz"},
		function(sec, usec, server, info)
			print("Uspesna synchronizace, cas od UNIX epochy:", sec, usec,", pouzity server:", server,", dalsi informace:", info)
		end,
		function()
			print("Selhala synchronizace s NTP!")
			selhalaNTP = true
		end
		)
		tmr.alarm(1, 1000, 1, function()
			if rtctime.get() ~= 0 or selhalaNTP == true then
				tmr.stop(1)
				print("Pro preruseni zavadeni systemu stisknete libovolnou klavesu...")
				tmr.alarm(0, 3000, 0, startup)
			else
				print("Cekani na odpoved NTP serveru...")
			end
		end)
    end
end)