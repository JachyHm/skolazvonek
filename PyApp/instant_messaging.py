import socket
from threading import Thread
from gi.repository import Gtk, GObject
from msvcrt import getch

class Connection:
    def __init__ (self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    def rec(self):
        print(self.socket.recv(1024))
    def connect(self, ip, port):
        self.socket.connect((ip,port))
        self.r = Thread(target=self.rec)
        self.r.start()
    def send(self,data):
        self.socket.sendall(bytes(data,'ASCII'))

c=Connection()

class Okno(Gtk.Window):
    
    
    def __init__(self):
        #Definuje funkci __start__
        Gtk.Window.__init__(self, title="Připojení")
        #Vytvoří okno "Ahoj světe po síti"
        self.set_size_request(300, 100)
        #Definuje velikost 300 na 100 px

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)
        #Vytvoří TextBox

        self.entry = Gtk.Entry()
        self.entry.set_text("Sem zadejte IP adresu partnera")
        vbox.pack_start(self.entry, True, True, 0)
        #Nastaví text "Sem zadejte IP adresu partnera"
        #Definuje TextBox viditelnost: true, editovatelnost: true a ta nula nevím co dělá :D

        
        button = Gtk.Button.new_with_label("Připoj")
        button.connect("clicked", self.pripoj)
        vbox.pack_start(button, True, True, 0)

        button = Gtk.Button.new_with_label("Zavři")
        button.connect("clicked", self.konec)
        vbox.pack_start(button, True, True, 0)
        #Definuje tlačítko "pripoj_cudlo" s textem "přpoj"
        #Při zmáčknutí spustí funkci (self = vlastní, tzn. je definováno v té samé třídě) "odesli_zmack"
        #Definuje čudlo "pripoj_cudlo" s viditelností "true" a zmáčknutelností "true", nula nevím co dělá


        
        self.ip=""
        #Definuje proměnou ip s hodnotou:
        

    def pripoj(self, button):
        self.ip=self.entry.get_text()
        c.connect(self.ip, 62803)
        dialog = PripojeniOK(self)
        response = dialog.run()
        if response == Gtk.ResponseType.OK:
            okno2=Okno2()
            win1.show_all()
        dialog.destroy()
        
        
        #Definuje funkcii "odesli_zmack" navázanou na "pripoj_cudlo"
        #Zapíše do promměnné "ip" hodnotu z pole "ip_vstup"

    def konec(self, button):
        Gtk.main_quit()

class PripojeniOK(Gtk.Dialog):

    def __init__(self, parent):
        Gtk.Dialog.__init__(self, "Oznámení", parent, 0,
             (Gtk.STOCK_OK, Gtk.ResponseType.OK))

        self.set_default_size(150, 100)

        label = Gtk.Label("Připojení proběhlo v pořádku!")

        box = self.get_content_area()
        box.add(label)
        self.show_all()

class Okno2(Gtk.Window):
    def enter_klik(self):
            key = getch()
            if key == 13:
                odesli()
    def okno_start(self):
        #Definuje funkci __start__
        Gtk.Window.__init__(self, title="Instant messaging")
        #Vytvoří okno "Ahoj světe po síti"
        self.set_size_request(300, 100)
        #Definuje velikost 300 na 100 px

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)
        #Vytvoří TextBox

        self.entry = Gtk.Entry()
        self.entry.set_text("Sem zadejte zprávu")
        vbox.pack_start(self.entry, True, True, 0)
        #Nastaví text "Sem zadejte IP adresu partnera"
        #Definuje TextBox viditelnost: true, editovatelnost: true a ta nula nevím co dělá :D

        
        button = Gtk.Button.new_with_label("Odešli")
        button.connect("clicked", self.odesli)
        vbox.pack_start(button, True, True, 0)

        button = Gtk.Button.new_with_label("Zavři")
        button.connect("clicked", self.konec)
        vbox.pack_start(button, True, True, 0)
        #Definuje tlačítko "pripoj_cudlo" s textem "přpoj"
        #Při zmáčknutí spustí funkci (self = vlastní, tzn. je definováno v té samé třídě) "odesli_zmack"
        #Definuje čudlo "pripoj_cudlo" s viditelností "true" a zmáčknutelností "true", nula nevím co dělá


        Enter=Thread(target=self.enter_klik)
        self.ip=""
        self.zprava=""
        Enter.start
        #Definuje proměnou ip s hodnotou: 

    def odesli(self, button):
        zprava=self.entry.get_text()
        c.send(zprava)
        self.entry.set_text("")
        
        
        #Definuje funkcii "odesli_zmack" navázanou na "pripoj_cudlo"
        #Zapíše do promměnné "ip" hodnotu z pole "ip_vstup"

    def konec(self, button):
        Gtk.main_quit()

    


win = Okno()
win1=Okno2()
win1.okno_start()
win.connect("delete-event", Gtk.main_quit)
win.show_all()
Gtk.main()