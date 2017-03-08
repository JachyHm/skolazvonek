zvoneni=0
buff=""
pismenko=""
nejblizsizvoncas=0
nejblizsizvondelka=0
aktualnicas=0
casraw = 0
cas = 0
i = 0
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
				if pismenko == nil then	
					zvonenisoubor:close()
					byloposlednizvoneni = true
					buff = ""
					zvonenisoubor = file.open("zvoneni.txt","r")
				end
				break
			else
				buff = buff..pismenko
			end
		end
		print("Cas zvoneni "..tostring(zvoneni))
		print("Delka zvoneni "..tostring(delkazvoneni))
		print("Aktualni cas "..tostring(aktualnicas))
		print("Dosahl jsi konce seznamu "..tostring(byloposlednizvoneni))
		if zvoneni > aktualnicas or byloposlednizvoneni == true then
			zvonenisoubor:close()
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
				gpio.write(3, gpio.HIGH)
				print("Cingilingi")
			else
				gpio.write(3, gpio.LOW)
				if byloposlednizvoneni ~= true then
					nejblizsizvoncas,nejblizsizvondelka = nejblizsizvon()
				end
			end
		end
		if tonumber(aktualnicas) - tonumber(poslednicheck) > 120000 then
			sntp.sync({"tik.cesnet.cz","tak.cesnet.cz"},
				function(sec, usec, server, info)
					print("Uspesna synchronizace, cas od UNIX epochy:", sec, usec,", pouzity server:", server,", dalsi informace:", info)
				end,
				function()
					print("Selhala synchronizace s NTP!")
				end
			)
			--sntp.sync()
			poslednicheck = aktualnicas
		end
		-- if chcksum(souborserver) != chcksum(souborlokalni) then
			-- stáhni soubor se zvoněním ze serveru
			-- nejblizsizvoncas,nejblizsizvondelka = nejblizsizvon()
		-- end
	end
	if aktualnicas == 0 then
		byloposlednizvoneni = false
	end
end)