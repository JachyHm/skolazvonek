import socket
import time
from prompter import yesno
from threading import Thread
import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GObject
from msvcrt import getch

pripojene = False

class Connection:
    def __init__ (self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    def connect(self, ip, port):
        self.socket.connect((ip,port))
    def disconnect(self):
        self.socket.close()
    def send(self,data):
        self.socket.sendall(bytes(data,'ASCII'))


def ZiskejMACaIP(parent, message, title=""):
    dialogWindow = Gtk.MessageDialog(parent,
                            Gtk.DialogFlags.MODAL | Gtk.DialogFlags.DESTROY_WITH_PARENT,
                            Gtk.MessageType.QUESTION,
                            Gtk.ButtonsType.OK_CANCEL,
                            message)

    dialogWindow.set_title(title)

    dialogWindow.set_default_size(150,100)

    macAdresaLabel = Gtk.Label("MAC adresa:")

    rozsahIPlabel = Gtk.Label("Rozsah IP adres:")

    macAdresaEntry = Gtk.Entry()

    rozsahIPentry = Gtk.Entry()

    vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing = 1)

    dradek1 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing = 2)

    box = dialogWindow.get_content_area()

    box.pack_start(vbox, True, True, 0)
            
    vbox.pack_start(dradek1, True, True, 0)
    
    dradek1.pack_start(macAdresaLabel, False, False, 5)

    dradek1.pack_start(macAdresaEntry, True, True, 5)
        
    macAdresaEntry.set_text("5C:CF:7F:8B:5A:9B")
            
    dialogWindow.show_all()
        
    response = dialogWindow.run()

    mac = macAdresaEntry.get_text()

    dialogWindow.destroy()

    if (response == Gtk.ResponseType.OK) and (mac != ""):
        return (mac)
    else:
        return None

class DialogYNWiFi(Gtk.Dialog):
    def __init__(self, parent):
        Gtk.Dialog.__init__(self, "Opravdu nahrát?", parent, 0,
            (Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
             Gtk.STOCK_OK, Gtk.ResponseType.OK))

        self.set_default_size(150, 100)
        
        souborwifi = open(win.vstupWiFi.get_text(),"r")    
        SSIDradek = souborwifi.readline()
        HESLOradek = souborwifi.readline()
        SSID = SSIDradek[5:-1]
        HESLO = HESLOradek[6:-1]

        label = Gtk.Label('Opravdu má být nahrán WiFiconfig s SSID sítě:\n'+SSID+"\na heslem sítě:\n"+HESLO+"\n?")

        box = self.get_content_area()
        box.add(label)
        self.show_all()

class Funkce:
    
    def Konec(self,par1,par2):
        c = Connection()
        c.disconnect()
        Gtk.main_quit(par1,par2)
        
    def ZkontrolujIP(self,ip):
        i = 0
        tecky=[]
        if ip.find(".") != -1:
            poziceTecky1 = ip.find(".")+1
            tecky=[0,poziceTecky1]
            i=1
            while ip.find(".",tecky[i]+1) != -1:
                tecky.append(ip.find(".",tecky[i]+1)+1)
                i=i+1
            
        else:
            tecky=[0]

        if len(ip) != tecky[i]:
            tecky.append(len(ip))

        celek = ""
        
        try:
            cast1 = ip[tecky[0]:tecky[1]]
            if cast1.find(".") != -1:
                if int(cast1[:len(cast1)-1]) > 255:
                    cast1 = "255."
                    
            elif int(cast1) > 255:
                cast1 = "255"

            if cast1 != "":
                celek = celek+cast1
            else:
                cast1 = None
                
        except:
            cast1 = None
            
        try:
            cast2 = ip[tecky[1]:tecky[2]]
            if cast2.find(".") != -1:
                if int(cast2[:len(cast2)-1]) > 255:
                    cast2 = "255."
                
            elif int(cast2) > 255:
                cast2 = "255"

            if cast2 != "":
                celek = celek+cast2
            else:
                cast2 = None
                
        except:
            cast2 = None
            
        try:
            cast3 = ip[tecky[2]:tecky[3]]
            if cast3.find(".") != -1:
                if int(cast3[:len(cast3)-1]) > 255:
                    cast3 = "255."
                
            elif int(cast3) > 255:
                cast3 = "255"

            if cast3 != "":
                celek = celek+cast3
            else:
                cast3 = None
                
        except:
            cast3 = None
            
        try:
            cast4 = ip[tecky[3]:tecky[4]]
            if cast4.find(".") != -1:
                cast4 = cast4[:len(cast4)-1]
                
            if int(cast4) > 255:
                cast4 = "255"

            if cast4 != "":
                celek = celek+cast4
            else:
                cast4 = None
                
        except:
            cast4 = None

        if cast1 != None and cast2 != None and cast3 != None and cast4 != None:
            return(celek,True)
        else:
            return(celek,False)
        
    def OdpojButtonPressed(self):
        c = Connection()
        
        print("Odpojuji")
        c.disconnect()
        win.set_title("Editor konfigurace zvonku. Nepřipojeno - zadaná IP!")
        pripojene = False
        
    def NahrajKonfiguraceButtonPressed(self):
        fce=Funkce()
        c=Connection()
        print("Nahrávám")
        if not pripojene:
            win.PripojButtonPressed("_")
        try:
            souborwifi = open(win.vstupWiFi.get_text(),"r")
        except:
            win.DiagChybaWiFi()
        else:
            try:
                souborzvon = open(win.vstupCasy.get_text(),"r")
            except:
                win.DiagChybaCasy()
            else:
                if win.DiagYesNoWiFi():

                    c.connect(win.vstupIP.get_text(),59460)
                    c.send("z:"+souborzvon.read()+"w:"+souborwifi.read())
                    c.disconnect()

                    hodnota = 0
                    win.progressbar.set_text("Nahrávání souborů...")
                    win.progressbar.set_show_text(True)
                    
                    win.activity_mode = True
                        
                    print("\nÚspěšně nahráno do zařízení!")

    def ZapniZvoneniButtonPressed(self):
        c = Connection()
        if not pripojene:
            win.PripojButtonPressed("_")
            c.connect(win.vstupIP.get_text(),59460)
        c.send("zapnizvon")
        c.disconnect()

    def VypniZvoneniButtonPressed(self):
        c = Connection()
        if not pripojene:
            win.PripojButtonPressed("_")
            c.connect(win.vstupIP.get_text(),59460)
        c.send("vypnizvon")
        c.disconnect()
        
    def RestartujButtonPressed(self):
        c = Connection()
        fce=Funkce()
        if not pripojene:
            win.PripojButtonPressed("_")
            c.connect(win.vstupIP.get_text(),59460)
        c.send("restart")
        c.disconnect()
        fce.OdpojButtonPressed()

class OknoAplikace(Gtk.Window):

    def on_timeout(self, user_data):
        """
        Update value on the progress bar
        """
        if self.activity_mode:
            new_value = self.progressbar.get_fraction() + 0.01

            if new_value > 1:
                self.activity_mode = False

            self.progressbar.set_fraction(new_value)

        # As this is a timeout function, return True so that it
        # continues to get called
        return True

    def DiagChybaWiFi(self):
        dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.ERROR,
            Gtk.ButtonsType.OK, "Chyba!")
        dialog.format_secondary_text(
            "Chybně zadaná cesta k souboru s definicí WiFi sítě!")
        dialog.run()
        dialog.destroy()

    def DiagChybaCasy(self):
        dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.ERROR,
            Gtk.ButtonsType.OK, "Chyba!")
        dialog.format_secondary_text(
            "Chybně zadaná cesta k souboru s definicí časů zvonění!")
        dialog.run()
        dialog.destroy()
        
    def DiagYesNoWiFi(self):
    
        dialog = DialogYNWiFi(self)
        response = dialog.run()

        if response == Gtk.ResponseType.OK:
            odpoved = True
        elif response == Gtk.ResponseType.CANCEL:
            odpoved = False

        dialog.destroy()
        
        return(odpoved)

    def PripojButtonPressed(self,_):

        c=Connection()
        Fce=Funkce()
        
        print("Připojuji")
        
        ip = self.vstupIP.get_text()
        ip, plati = Fce.ZkontrolujIP(ip)
        
        if plati:
            try:
                c.connect(ip,59460)
            except Exception as e:
                dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.OK, "Chyba!")
                dialog.format_secondary_text(
                    str(e))
                dialog.run()
                dialog.destroy()
            else:
                win.set_title("Editor konfigurace zvonku. Připojeno!")
                pripojene = True
        else:
            dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.INFO,
                Gtk.ButtonsType.OK, "Chyba!")
            dialog.format_secondary_text(
                "Zadejte platnou IP adresu!")
            dialog.run()
            dialog.destroy()

        
    def AutoIPsearchButtonPressed(self,_):
        c=Connection()
        
        self.progressbar.set_fraction(0)
        self.progressbar.set_text("Prohledávání sítě...")
        self.progressbar.set_show_text(True)
        try:
            ip = socket.gethostbyname("Zvonek")
        except Exception as e:
            self.progressbar.set_fraction(1)
            dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.ERROR,
                Gtk.ButtonsType.OK, "Chyba!")
            dialog.format_secondary_text(
                "Zařízení nebylo v síti nalezeno, zkontrolujte připojení!\n\nChyba: %s" % (e))
            dialog.run()
            dialog.destroy()
        else:
            self.vstupIP.set_text(ip)
            self.progressbar.set_fraction(1)
            dialog = Gtk.MessageDialog(self, 0, Gtk.MessageType.INFO,
                Gtk.ButtonsType.OK, "Dokončeno!")
            dialog.format_secondary_text(
                "Zařízení bylo nalezeno.")
            dialog.run()
            dialog.destroy()
          
        #print(spust(mac,ip))
    
    def on_file_clicked(self, widget):
        dialog = Gtk.FileChooserDialog("Vyberte prosím soubor s časy zvonění:", self,
                Gtk.FileChooserAction.OPEN,
                (Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                 Gtk.STOCK_OPEN, Gtk.ResponseType.OK))
        self.add_filters(dialog,flt="zvoneni")

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            self.vstupCasy.set_text(dialog.get_filename())

        dialog.destroy()
        
    def on_WiFifile_clicked(self, widget):
        dialog = Gtk.FileChooserDialog("Vyberte prosím soubor s konfigurací WiFi:", self,
                Gtk.FileChooserAction.OPEN,
                (Gtk.STOCK_CANCEL, Gtk.ResponseType.CANCEL,
                 Gtk.STOCK_OPEN, Gtk.ResponseType.OK))
        self.add_filters(dialog,flt="wifi")

        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            self.vstupWiFi.set_text(dialog.get_filename())

        dialog.destroy()

    def ZmenaIP(self,_):
        c = Connection()
        
        ip = self.vstupIP.get_text()

        Fce=Funkce()
        
        celek,platna = Fce.ZkontrolujIP(ip)

        if platna:
            win.set_title("Editor konfigurace zvonku. Nepřipojeno - zadaná IP!")
        else:
            c.disconnect()
            win.set_title("Editor konfigurace zvonku. Nepřipojeno - nezadaná IP!")
        
        self.vstupIP.set_text(celek)

    def add_filters(self, dialog, flt):
        filter_text = Gtk.FileFilter()
        if flt == "zvoneni":
            filter_text.set_name("Soubory s časy zvonění")
            filter_text.add_mime_type("text/plain")
        elif flt == "wifi":
            filter_text.set_name("Soubory s konfigurací WiFi sítě")
            filter_text.add_pattern("*.lua")
        dialog.add_filter(filter_text)

    def __init__(self):
        Gtk.Window.__init__(self, title="Editor konfigurace zvonku. Nepřipojeno - nezadaná IP!")

        self.set_size_request(500,200)
        
        hlavni = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing = 5)
        self.add(hlavni)

        radek1 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing = 3)
        hlavni.pack_start(radek1,True,True,5)

        radek2 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing = 3)
        hlavni.pack_start(radek2,True,True,5)

        radek3 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing = 3)
        hlavni.pack_start(radek3,True,True,5)

        radek4 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing = 6)
        hlavni.pack_start(radek4,True,True,5)

        radek5 = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing = 1)
        hlavni.pack_start(radek5,True,True,10)
        
        #Radek 1
        
        vlozteIPlabel = Gtk.Label()
        vlozteIPlabel.set_markup("Sem vložte IP adresu zvonku:")
        radek1.pack_start(vlozteIPlabel, False,False,5)

        self.vstupIP = Gtk.Entry()
        self.vstupIP.connect("changed", self.ZmenaIP)
        self.vstupIP.set_max_length(15)
        radek1.pack_start(self.vstupIP, True, True, 5)

        automatickyNajit = Gtk.Button.new_with_label("Zkusit najít zařízení automaticky")
        automatickyNajit.connect("clicked", self.AutoIPsearchButtonPressed)
        radek1.pack_start(automatickyNajit, False, False, 5)
        
        #Radek 2

        vyberteCasy = Gtk.Label()
        vyberteCasy.set_markup("Vyberte soubor s časy zvonění:")
        radek2.pack_start(vyberteCasy, False,False,5)

        self.vstupCasy = Gtk.Entry()
        radek2.pack_start(self.vstupCasy, True, True, 5)

        vyberteCasyButton = Gtk.Button.new_with_label("Procházet...")
        vyberteCasyButton.connect("clicked", self.on_file_clicked)
        radek2.pack_start(vyberteCasyButton, False, False, 5)

        #Radek 3

        vyberteWiFi = Gtk.Label()
        vyberteWiFi.set_markup("Vyberte soubor s konfigurací WiFi sítě:")
        radek3.pack_start(vyberteWiFi, False,False,5)

        self.vstupWiFi = Gtk.Entry()
        radek3.pack_start(self.vstupWiFi, True, True, 5)

        vyberteWiFiButton = Gtk.Button.new_with_label("Procházet...")
        vyberteWiFiButton.connect("clicked", self.on_WiFifile_clicked)
        radek3.pack_start(vyberteWiFiButton, False, False, 5)

        #Radek 4

        pripojButton = Gtk.Button.new_with_label("Připoj")
        pripojButton.connect("clicked", self.PripojButtonPressed)
        radek4.pack_start(pripojButton, True, True, 5)

        odpojButton = Gtk.Button.new_with_label("Odpoj")
        odpojButton.connect("clicked", Funkce.OdpojButtonPressed)
        radek4.pack_start(odpojButton, True, True, 5)

        nahrajKonfiguraceButton = Gtk.Button.new_with_label("Nahraj!")
        nahrajKonfiguraceButton.connect("clicked", Funkce.NahrajKonfiguraceButtonPressed)
        radek4.pack_start(nahrajKonfiguraceButton, True, True, 5)

        zapniZvoneniButton = Gtk.Button.new_with_label("Zapni zvonění")
        zapniZvoneniButton.connect("clicked", Funkce.ZapniZvoneniButtonPressed)
        radek4.pack_start(zapniZvoneniButton, True, True, 5)

        vypniZvoneniButton = Gtk.Button.new_with_label("Vypni zvonění")
        vypniZvoneniButton.connect("clicked", Funkce.VypniZvoneniButtonPressed)
        radek4.pack_start(vypniZvoneniButton, True, True, 5)

        vypniZvoneniButton = Gtk.Button.new_with_label("Restartuj zařízení")
        vypniZvoneniButton.connect("clicked", Funkce.RestartujButtonPressed)
        radek4.pack_start(vypniZvoneniButton, True, True, 5)

        #Radek 5

        self.progressbar = Gtk.ProgressBar()
        radek5.pack_start(self.progressbar, True, True, 10)
        
        self.timeout_id = GObject.timeout_add(3, self.on_timeout, None)
        self.activity_mode = False

Fce = Funkce()
win = OknoAplikace()
win.connect("delete-event",Fce.Konec)
win.show_all()
Gtk.main()
