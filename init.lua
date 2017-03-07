dofile("wificonf.lua")
function startup()
    if file.open("init.lua") == nil then
        print("init.lua deleted or renamed")
    else
        file.close("init.lua")
        dofile("zvonek.lua")
    end
end
print("Probiha pripojovani k siti WiFi...")
wifi.setmode(wifi.STATION)
wifi.sta.config(SSID, HESLO)
tmr.alarm(2, 1000, 1, function()
    if wifi.sta.getip() == nil then
        print("Cekani na odpoved serveru...")
    else
        tmr.stop(2)
        print("Spojeni navazano, IP adresa: " .. wifi.sta.getip())
		print("Probiha pripojovani k NTP serveru a synchronizace casu...")
		sntp.sync({"0.cz.pool.ntp.org","1.cz.pool.ntp.org","2.cz.pool.ntp.org","3.cz.pool.ntp.org"},
		function(sec, usec, server, info)
			print("Uspesna synchronizace, cas od UNIX epochy:", sec, usec,", pouzity server:", server,", dalsi informace:", info)
		end,
		function()
			print("Selhala synchronizace s NTP!")
		end
		)
		tmr.alarm(1, 1000, 1, function()
			if rtctime.get() == 0 then
				print("Cekani na odpoved NTP serveru...")
			else
				tmr.stop(1)
				print("Pro preruseni zavadeni systemu stisknete libovolnou klavesu...")
				tmr.alarm(0, 3000, 0, startup)
			end
		end)
    end
end)
