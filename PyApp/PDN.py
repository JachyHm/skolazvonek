import socket
import subprocess
import sys
import time
from prompter import yesno

class Connection:
    def __init__ (self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    def connect(self, ip, port):
        self.socket.connect((ip,port))
    def send(self,data):
        self.socket.sendall(bytes(data,'ASCII'))
    def rec(self):
        response = ""
        while not ("konec" in response):
            response = response+self.socket.recv(131072).decode("ASCII")
        return(response[:-5])
    def close(self):
        self.socket.close()

class OverSoubor:
    def over(soubor):
        souborzvon = open(soubor,"r")
        radek = 1
        poziceNaRadku = 0
        bylCas = False
        buff = ""
        zvoneniStrDelka = ""
        delkazvoneni = 0
        while True:
            while True:
                pismenko = souborzvon.read(1)
                poziceNaRadku = poziceNaRadku + 1
                if pismenko == " ":
                    if not bylCas:
                        zvoneni = buff
                        zvoneniStrDelka = len(zvoneni or "")
                        if zvoneniStrDelka == 0:
                            souborzvon.close()
                            return radek, 0, "není uvedený čas zvonění"
                        else:
                            if int(zvoneni) < 245959:
                                try:
                                    sekundy = int(zvoneni[-2:])
                                except:
                                    souborzvon.close()
                                    return radek, 0, "sekundy nejsou číslo"
                                else:
                                    if sekundy > 59:
                                        souborzvon.close()
                                        return radek, 0, "sekundy jsou větší, než 59"
                                
                                minutyString = zvoneni[-4:-3]
                                if minutyString != "":
                                    try:
                                        minuty = int(minutyString)
                                    except:
                                        souborzvon.close()
                                        return radek, 0, "minuty nejsou číslo"
                                    else:
                                        if minuty > 59:
                                            souborzvon.close()
                                            return radek, 0, "minuty jsou větší, než 59"
                                        hodinyString = zvoneni[-6:-5]
                                        if hodinyString != "":
                                            try:
                                                hodiny = int(hodinyString)
                                            except:
                                                souborzvon.close()
                                                return radek, 0, "hodiny nejsou číslo"
                                            else:
                                                if hodiny > 24:
                                                    souborzvon.close()
                                                    return radek, 0, "hodiny jsou větší, než 24"
                            else:
                                souborzvon.close()
                                return radek, 0, "čas je větší, než 245959"
                        zvoneni = int(zvoneni)
                        bylCas = True
                    else:
                        bylCas = False
                        delkazvoneni = buff
                        delkaZvoneniStrDelka = len(delkazvoneni or "")
                        if delkaZvoneniStrDelka == 0:
                            souborzvon.close()
                            return radek, poziceNaRadku, "chybí zadaná délka zvonění"
                        else:
                            if not int(delkazvoneni):
                                souborzvon.close()
                                return radek, poziceNaRadku, "délka zvonění není číslo"
                            else:
                                if int(delkazvoneni) > 59:
                                    souborzvon.close()
                                    return radek, poziceNaRadku, "délka zvonění je větší, než 59"
                    buff = ""
                    delkazvoneni = int(delkazvoneni)
                elif pismenko == "\n" or pismenko == "":
                    dnyplatnosti = buff
                    if poziceNaRadku < 5:
                        souborzvon.close()
                        return radek, 0, "řádek neobsahuje žádná data"
                    else:
                        i = 0
                        while i <= 6:
                            if dnyplatnosti[i:i+1] != "0" and dnyplatnosti[i:i+1] != "1":
                                souborzvon.close()
                                return radek, poziceNaRadku - 6 + i, "datumové přepínače nejsou kompletní, nebo obsahují jinou hodnotu, než 0/1"
                            i = i + 1
                    buff = ""
                    radek = radek + 1
                    poziceNaRadku = 0
                    break
                else:
                    buff = buff+pismenko
            if pismenko == "":
                break
        return None, None, None

class Main:
    def __init__(self):
        blokuj = False
        if yesno("Riziková operace!\nPři nahrání vadného WiFiConf hrozí neobnovitelný stav zařízení!\nOpravdu nahrát?"):
            chybaRadek, chybaDelka, chybaText = OverSoubor.over("zvoneni.txt")
            if chybaRadek == None:
                input('Připojte se k síti "ZvonekNahraj" a poté stiskněte Enter')
                c=Connection()
                try:
                    ip = socket.gethostbyname("Zvonek")
                except:
                    print("Zařízení nebylo v síti nalezeno automaticky, používám výchozí adresu 10.10.10.0!")
                    ip = "10.10.10.0"
                try:
                    souborwifi = open("wificonf.lua","r")
                except:
                    print("\nChybějící soubor s definicí WiFi sítě! Kód chyby: 1")
                    input("Operace zrušena! Pro ukončení zmáčkněte Enter...")
                else:
                    SSIDradek = souborwifi.readline()
                    HESLOradek = souborwifi.readline()
                    SSID = SSIDradek[6:-2]
                    HESLO = HESLOradek[7:-1]
                    if yesno('\nOpravdu má být nahrán WiFiconfig s SSID sítě "'+SSID+'"\na heslem sítě "'+HESLO+'"?'):
                        if input("\nOpište SSID sítě a potvrďte Enterem!") == SSID:
                            if input("\nOpište heslo sítě a potvrďte Enterem!") == HESLO:
                                try:
                                    souborzvon = open("zvoneni.txt","r")
                                except:
                                    print("\nChybějící soubor s definicí časů zvonění! Kód chyby: 3")
                                    input("Operace zrušena! Pro ukončení zmáčkněte Enter...\n")
                                else:
                                    print("\nNahrávám do zařízení "+ip+" port 59460.")
                                    try:
                                        c.connect(ip, 59460)
                                    except:
                                        print("\nZařízení nebylo na zadané IP adrese nalezeno! Kód chyby: 12")
                                        input("Operace zrušena! Pro ukončení zmáčkněte Enter...")
                                    else:
                                        pokusy = 3
                                        souborwifi.seek(0)
                                        souborzvon.seek(0)
                                        c.send("z:"+souborzvon.read()+"w:"+souborwifi.read()+"konec")
                                        print("\nÚspěšně odesláno do zařízení, čekám na odpověď!")
                                        souborwifi.seek(0)
                                        souborzvon.seek(0)
                                        while c.rec() != "z:"+souborzvon.read()+"w:"+souborwifi.read(): 
                                            souborwifi.seek(0)
                                            souborzvon.seek(0)
                                            pokusy = pokusy - 1
                                            print("\nOdpověď není vpořádku! Nahrávám znovu! Počet zbýajících pokusů: "+str(pokusy)+".")
                                            c.send("z:"+souborzvon.read()+"w:"+souborwifi.read()+"konec")
                                            print("\nÚspěšně odesláno do zařízení, čekám na odpověď!")
                                            if pokusy == 0:
                                                input("\nNepovedlo se nahrát zvonek! Zkuste to znovu!")
                                                break
                                        print("\nOdpověď v pořádku, přijatá data souhlasí!")
                                        c.close()
                                        c=Connection()
                                        c.connect(ip, 59460)
                                        c.send("dataOKkonec")
                                        while c.rec() != "UlozenoOK!":
                                            time.sleep(1)
                                        input("Data úspěšně uložena! Po stisknutí Enter se aplikace ukončí!")                                        
                                        c.close()
                            else:
                                input("\nChybná potvrzovací sekvence! Kód chyby: 11\nOperace zrušena! Pro ukončení zmáčkněte Enter...")
                        else:
                            input("\nChybná potvrzovací sekvence! Kód chyby: 11\nOperace zrušena! Pro ukončení zmáčkněte Enter...")
                    else:
                        input("\nOperace zrušena! Pro ukončení zmáčkněte Enter...")
            else:
                input("\nNa řádku "+str(chybaRadek)+" v délce "+str(chybaDelka)+" je chyba: "+chybaText+"! Přerušuji nahrávání, opravte chybu!")
        else:
            input("\nOperace zrušena! Pro ukončení zmáčkněte Enter...")
m=Main()
