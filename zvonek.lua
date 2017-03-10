zvoneni=0
buff=""
pismenko=""
nejblizsizvoncas=0
nejblizsizvondelka=0
aktualnicas=0
casraw = 0
cas = 0
i = 0
zvstart = ""
wifistart = ""
zvoneniobsah = ""
wifiobsah = ""
gpio2stare=0
gpio.mode(1,gpio.OUTPUT)
gpio.mode(2,gpio.INPUT)
gpio.mode(3,gpio.INPUT)
gpio.mode(7,gpio.INPUT)
gpio.write(6, gpio.HIGH)
gpio.write(1, gpio.LOW)
byloposlednizvoneni = false
print("Overuji integritu souboru")
print("Ukoncuji procesy z minule relace")
print("Zavadim system")
casraw = rtctime.epoch2cal(rtctime.get())
aktualnicas = tonumber(string.format("%02d%02d%02d", casraw["hour"], casraw["min"], casraw["sec"]))+10000
poslednicheck=aktualnicas
--tady zapíšu aktualnicas do RTC modulu
--porovnám soubor zvoneni.txt se serverem
-- if chcksum(souborserver) != chcksum(souborlokalni) then
	--stáhni soubor se zvoněním ze serveru
-- end
wifi.sta.sethostname("Zvonek")
nodeSRV=net.createServer(net.TCP)
nodeSRV:listen(59460, function(conn)
    conn:on("receive", function(conn, receivedData)
		zvstart = string.find(receivedData, "z:")
		wifistart = string.find(receivedData, "w:")
		zvoneniobsah = string.sub(receivedData, zvstart+2, wifistart-1)
		wifiobsah = string.sub(receivedData, wifistart+2, string.len(receivedData))
		file.open("zvoneni.txt","w+")
		file.write(zvoneniobsah)
		file.close("zvoneni.txt")
		file.open("wificonf.lua","w+")
		file.write(wifiobsah)
		file.close("wificonf.lua")
		node.restart()
    end) 
    conn:on("sent", function(conn) 
      collectgarbage()
    end)
end)
print("Aktualni cas je:"..aktualnicas)
function nejblizsizvon()
	byloposlednizvoneni = false
	zvonenisoubor = file.open("zvoneni.txt","r")
	while true do
		while true do
			pismenko = zvonenisoubor:read(1)
			if pismenko == " " then
				zvoneni = tonumber(buff)
				buff = ""
			elseif pismenko == "\n" or pismenko == nil then
				delkazvoneni = tonumber(buff)
				buff = ""
				break
			else
				buff = buff..pismenko
			end
		end
		print("Cas zvoneni "..tostring(zvoneni))
		print("Delka zvoneni "..tostring(delkazvoneni))
		print("Aktualni cas "..tostring(aktualnicas))
		if zvoneni > aktualnicas or pismenko == nil then
			zvonenisoubor:close()
			if zvoneni < aktualnicas then	
				zvonenisoubor:close()
				byloposlednizvoneni = true
				buff = ""
				zvonenisoubor = file.open("zvoneni.txt","r")
			end
			print("Dosahl jsi konce seznamu "..tostring(byloposlednizvoneni))
			return zvoneni,delkazvoneni
		end
	end
end
nejblizsizvoncas,nejblizsizvondelka = nejblizsizvon()
poslednicheck = aktualnicas
tmr.alarm(3,1000,1,function()
	casraw = rtctime.epoch2cal(rtctime.get())
	if i >= 10 then
		i = 0
		print(string.format("%04d/%02d/%02d %02d:%02d:%02d", casraw["year"], casraw["mon"], casraw["day"], casraw["hour"], casraw["min"], casraw["sec"]))
		print(nejblizsizvoncas)
		print(aktualnicas)
		print(nejblizsizvondelka)
	end
	i = i + 1
	aktualnicas = tonumber(string.format("%02d%02d%02d", casraw["hour"], casraw["min"], casraw["sec"]))+10000
	if aktualnicas ~= "" or aktualnicas ~= nil then
		if nejblizsizvoncas <= aktualnicas then
			if nejblizsizvoncas + nejblizsizvondelka > aktualnicas then
				if gpio.read(3) == 0 then
					gpio.write(1, gpio.HIGH)
					print("Cingilingi")
				end
			else
				if gpio.read(2) ~= 1 then
					gpio.write(1, gpio.LOW)
				end
				if byloposlednizvoneni ~= true then
					nejblizsizvoncas,nejblizsizvondelka = nejblizsizvon()
				end
			end
		end
		if math.abs(tonumber(aktualnicas) - tonumber(poslednicheck)) > 120000 then
			sntp.sync({"tik.cesnet.cz","tak.cesnet.cz"},
				function(sec, usec, server, info)
					print("Uspesna synchronizace, cas od UNIX epochy:", sec, usec,", pouzity server:", server,", dalsi informace:", info)
					poslednicheck = aktualnicas
					gpio.write(5, gpio.LOW)
				end,
				function()
					print("Selhala synchronizace s NTP!")
					gpio.write(5, gpio.HIGH)
				end
			)
		end
	end
	if gpio.read(2) == 1 then
		gpio.write(1, gpio.HIGH)
	elseif gpio2stare ~= gpio.read(2) then
		gpio.write(1, gpio.LOW)
	end
	if aktualnicas == 0 then
		byloposlednizvoneni = false
	end
	if byloposlednizvoneni == true then
		gpio.write(5, gpio.HIGH)
	else
		gpio.write(5, gpio.LOW)
	end
	if gpio.read(7) == 1 then
		gpio.write(8, gpio.LOW)
	else
		gpio.write(8, gpio.HIGH)
	end
	gpio2stare = gpio.read(2)
end)