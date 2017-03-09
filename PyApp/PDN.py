import socket
import time
from prompter import yesno

class Connection:
    def __init__ (self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    def connect(self, ip, port):
        self.socket.connect((ip,port))
    def send(self,data):
        self.socket.sendall(bytes(data,'ASCII'))

class Main:
    def __init__(self):
        if yesno("Riziková operace!\nPři nahrání vadného WiFiConf hrozí neobnovitelný stav zařízení!\nOpravdu nahrát?"):
            c=Connection()
            souborip = open("IPnodeMCU.ini","r")
            ip = souborip.readline()
            print("Nahrávám do zařízení "+ip)
            c.connect(ip, 59460)
            souborwifi = open("wificonf.lua","r")
            souborzvon = open("zvoneni.txt","r")
            c.send("z:"+souborzvon.read()+"w:"+souborwifi.read())
            time.sleep(2)
            print("Úspěšně nahráno do zařízení!")
            input("Pro ukončení zmáčkněte Enter...")
        else:
            input("Operace zrušena! Pro ukončení zmáčkněte Enter...")
m=Main()
