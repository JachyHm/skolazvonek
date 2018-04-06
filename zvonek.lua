zvoneni=0
delkazvoneni = 0
dnyplatnosti = ""
buff=""
pismenko=""
nejblizsizvoncas=0
nejblizsizvondelka=0
aktualnicas=0
i = 10
staryDen = ""
zvoneniobsah = ""
wifiobsah = ""
gpio.mode(6,gpio.INPUT)
gpio.mode(7,gpio.INPUT)
gpio.write(2, gpio.LOW)
byloposlednizvoneni = false
uzBlika = false
bylCas = false
plati = false
buffZprava = ""
poslednicheck=aktualnicas
nodeSRV=net.createServer(net.TCP)
collectgarbage()
nodeSRV:listen(59460, function(conn)
	conn:on("receive", function(sck, receivedData)
		-- if string.find(receivedData, "zapnizvon") ~= nil then
		-- 	zadostZvonSW = true
		-- elseif string.find(receivedData, "vypnizvon") ~= nil then
		-- 	zadostZvonSW = false
		-- elseif string.find(receivedData, "restart") ~= nil then
		-- 	node.restart()
		buffZprava = buffZprava..receivedData
		if string.find(buffZprava, "konec") ~= nil then
			celaZprava = buffZprava
			buffZprava = ""
			if string.find(celaZprava, "dataOK") ~= nil then
				file.open("wificonf.lua","w+")
				file.write(wifiobsah)
				file.close("wificonf.lua")
				wifiobsah = nil
				SSIDstare = SSID
				HESLOstare = HESLO 
				dofile("wificonf.lua")
				file.open("zvoneni.txt","w+")
				file.write(zvoneniobsah)
				file.close("zvoneni.txt")
				zvoneniobsah = nil
				sck:send("UlozenoOK!konec")
				sck:on("sent", function()
					blikej = false
					tmr.unregister(6)
					if not emergencyMode and SSID == SSIDstare and HESLO == HESLOstare then
						nejblizsizvoncas,nejblizsizvondelka = nejblizsizvon()
					else
						node.restart()
					end
				end)
			else
				zvstart = string.find(celaZprava, "z:")
				wifistart = string.find(celaZprava, "w:")
				if zvstart ~= nil and wifistart ~= nil then
					zvoneniobsah = string.sub(celaZprava, zvstart+2, wifistart-1)
					wifiobsah = string.sub(celaZprava, wifistart+2, string.len(celaZprava)-5)
					
					response = {}
					while string.len(celaZprava) > 255 do
						response[#response + 1] = string.sub( celaZprava, 0, 255)
						celaZprava = string.sub(celaZprava, 256)
					end
					response[#response + 1] = celaZprava
					local function send(sk)
						if #response > 0 then
							sk:send(table.remove(response, 1))
						else
							response = nil
						end
					end
					sck:on("sent", send)
					send(sck)


					celaZprava = ""
				end
			end
		end
    end)
end)

function PlatiDnes(t)
	print(t)
	platnost = {}
	platnost[1] = string.sub(t,1,1)
	platnost[2] = string.sub(t,2,2)
	platnost[3] = string.sub(t,3,3)
	platnost[4] = string.sub(t,4,4)
	platnost[5] = string.sub(t,5,5)
	platnost[6] = string.sub(t,6,6)
	platnost[7] = string.sub(t,7,7)
	
	tObject = rtctime.epoch2cal(rtctime.get() + tz.getoffset(rtctime.get()))
	den = tObject["wday"] - 1
	if den == 0 then
		den = 7
	end
	if platnost[tonumber(den)] == "1" then
		return true
	else
		return false
	end
end
	
if not emergencyMode then
	casraw = rtctime.epoch2cal(rtctime.get() + tz.getoffset(rtctime.get()))
	aktualnicas = tonumber(string.format("%02d%02d%02d", casraw["hour"], casraw["min"], casraw["sec"]))
	function nejblizsizvon()
		emergencyMode = true
		emModeFile = file.open("emergencyMode.stav","w")
		emModeFile:writeline("true")
		byloposlednizvoneni = false
		zvonenisoubor = file.open("zvoneni.txt","r")
		while true do
			while true do
				pismenko = zvonenisoubor:read(1)
				if pismenko == " " then
					if not bylCas then
						zvoneni = tonumber(buff)
						bylCas = true
					else
						bylCas = false
						delkazvoneni = tonumber(buff)
					end
					buff = ""
				elseif pismenko == "\n" or pismenko == nil then
					dnyplatnosti = buff
					buff = ""
					break
				else
					buff = buff..pismenko
				end
			end
			plati = PlatiDnes(dnyplatnosti)
			print("Plati dnes "..tostring(plati))
			print("Cas zvoneni "..tostring(zvoneni))
			print("Delka zvoneni "..tostring(delkazvoneni))
			print("Aktualni cas "..tostring(aktualnicas))
			print("Emergency mod "..tostring(emergencyMode))
			if (zvoneni > aktualnicas and plati) or pismenko == nil then
				zvonenisoubor:close()
				if zvoneni < aktualnicas or not plati then
					byloposlednizvoneni = true

					-- cfg={}
					-- local casDoPulnoci = 240000 - aktualnicas
					-- casDoPulnoci = tostring(casDoPulnoci)
					-- local sekundyDoPulnoci = tonumber(string.sub(casDoPulnoci, -2))
					-- local minutyDoPulnoci = tonumber(string.sub(casDoPulnoci, -4, -3))
					-- local hodinyDoPulnoci = tonumber(string.sub(casDoPulnoci, -6, -5))
					-- cfg.duration=math.min(268435454,((sekundyDoPulnoci*1000)+(minutyDoPulnoci*60000)+(hodinyDoPulnoci*3600000)))
					-- print("Jdu spat na: "..hodinyDoPulnoci.." hodin, "..minutyDoPulnoci.." minut, "..sekundyDoPulnoci.." sekund. Papa.")
					-- node.sleep(cfg)

					buff = ""
					zvonenisoubor = file.open("zvoneni.txt","r")
				end
				print("Dosahl jsi konce seznamu "..tostring(byloposlednizvoneni))
				if zvoneni ~= nil and delkazvoneni ~= nil then
					emergencyMode = false
					emModeFile:writeline("false")
					emModeFile:close(); emModeFile = nil
					return zvoneni,delkazvoneni
				else
					blikej = true
					tmr.unregister(4)
					tmr.alarm(6, 200, 1, function()
						if citac ~= 1 then
							gpio.write(5, gpio.HIGH)
							gpio.write(1, gpio.HIGH)
							citac = 1
						else
							gpio.write(5, gpio.LOW)
							gpio.write(1, gpio.LOW)
							citac = 0
						end
					end)
					return "",""
				end
			end
		end
	end
	function stop() zastavprogram = true end
	poslednicheck = aktualnicas
	tmr.alarm(4,1000,1,function()
		if zastavprogram then tmr.stop(4) end
		casraw = rtctime.epoch2cal(rtctime.get() + tz.getoffset(rtctime.get()))
		aktualnicas = tonumber(string.format("%02d%02d%02d", casraw["hour"], casraw["min"], casraw["sec"]))
		if casraw["wday"] ~= staryDen then
			staryDen = casraw["wday"]
			byloposlednizvoneni = false
			nejblizsizvoncas,nejblizsizvondelka = nejblizsizvon()
		end
		if i >= 10 then
			i = 0
			print("Cas dle UNIX: "..string.format("%04d/%02d/%02d %02d:%02d:%02d", casraw["year"], casraw["mon"], casraw["day"], casraw["hour"], casraw["min"], casraw["sec"]))
			print("Aktualni cas (bere vpotaz daylight saving time a UTC+1): "..aktualnicas)
			print("Dosahl jsi posledniho zvoneni dne? (pak neplati nasledujici dva radky): "..tostring(byloposlednizvoneni))
			print("Cas nejblizsiho zvoneni: "..nejblizsizvoncas)
			print("Delka nejblizsiho zvoneni: "..nejblizsizvondelka)
			if gpio.read(7) == 1 then gpio7 = false else gpio7 = true end
			print("Je aktivovane permanentni zvoneni? "..tostring(gpio7))
			if gpio.read(6) == 1 then gpio1 = false else gpio1 = true end
			print("Je aktivovane vynucene vypnuti zvoneni? "..tostring(gpio1))
			print("Posledni kontrola casu z NTP probehla: "..poslednicheck)
			print("Emergency mod "..tostring(emergencyMode))
			
			print("")
		end
		i = i + 1
		if aktualnicas ~= "" or aktualnicas ~= nil then
			if nejblizsizvoncas <= aktualnicas then
				if nejblizsizvoncas + nejblizsizvondelka > aktualnicas and not byloposlednizvoneni then
					if gpio.read(6) == 1 then
						gpio.write(2, gpio.HIGH)
						print("Cingilingi")
					else
						gpio.write(2, gpio.LOW)
					end
				else
					if gpio.read(7) ~= 0 then
						gpio.write(2, gpio.LOW)
					end
					if not byloposlednizvoneni then
						nejblizsizvoncas,nejblizsizvondelka = nejblizsizvon()
					end
				end
			end
			if math.abs(tonumber(aktualnicas) - tonumber(poslednicheck)) > 120000 then
				pendingRequestOnTimeSync = true
			end
		end
		if pendingRequestOnTimeSync then
			if wifi.sta.getip() ~= nil and not blokProbiha then
				blokProbiha = true
				pendingRequestOnTimeSync = false
				getDST()
				sntp.sync({"tik.cesnet.cz","tak.cesnet.cz"},
					function(sec, usec, server, info)
						print("Uspesna synchronizace, cas od UNIX epochy:", sec, usec,", pouzity server:", server,", dalsi informace:", info)
						print("")
						poslednicheck = aktualnicas
						tmr.stop(3)
						blokProbiha = false
					end,
					function()
						print("Selhala synchronizace s NTP!")
						blokProbiha = false
						pendingRequestOnTimeSync = true
						tmr.alarm(3, 200, 1, function()
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
						print("")
					end
				)
			else
				tmr.alarm(3, 200, 1, function()
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
		end
		if not blikej then
			if byloposlednizvoneni then
				gpio.write(5, gpio.HIGH)
			else
				gpio.write(5, gpio.LOW)
			end
		end
		if gpio.read(6) == 0 then
			gpio.write(2, gpio.LOW)
			if not blikej then
				gpio.write(1, gpio.HIGH)
			end
		else
			if not blikej then
				gpio.write(1, gpio.LOW)
			end
		end
		if gpio.read(7) == 0 then
			gpio.write(2, gpio.HIGH)
			gpio7stare = 0
		elseif gpio7stare == 0 then
			gpio.write(2, gpio.LOW)
			gpio7stare = 1
		end
		if blikej and not uzBlika then
			uzBlika = true
			tmr.alarm(5,200,1,function()
				if blikej and citac ~= 1 then
					gpio.write(5, gpio.HIGH)
					gpio.write(1, gpio.HIGH)
					citac = 1
				elseif blikej then
					gpio.write(5, gpio.LOW)
					gpio.write(1, gpio.LOW)
					citac = 0
				end
			end)
		elseif not blikej then
			tmr.unregister(5)
		end
	end)
end