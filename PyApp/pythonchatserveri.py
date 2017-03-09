import socket
from threading import Thread
from gi.repository import Gtk, GObject
from msvcrt import getch


class Connection():

    def __init__ (self):
        self.serversocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.serversocket.bind(('', 62803))
        self.serversocket.listen(5)
        
       
    def rec(self):
        while True:
            prijata_data=self.jachym.recv(1024)
            Okno.prijem.set_text(prijata_data)
    def listen(self):
        (self.jachym, self.blLVA) = self.serversocket.accept()
        self.r = Thread(target=self.rec)
        self.r.start()
       
    def send(self,data):
        self.jachym.sendall(bytes(data,'ASCII'))
        
prijata_data=""
c = Connection()
c.listen()
class Okno(Gtk.Window):
    def __init__(self):
        #Definuje funkci __start__
        Gtk.Window.__init__(self, title="Instant messaging (server)")
        #Vytvoří okno "Ahoj světe po síti"
        self.set_size_request(300, 100)
        #Definuje velikost 300 na 100 px

        vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.add(vbox)
        #Vytvoří TextBox


        
        self.prijem = Gtk.Entry()
        self.prijem.set_text("Zde se budou zobrazovat přijaté zprávy")
        self.prijem.progress_pulse()
        vbox.pack_start(self.prijem, True, True, 1)
        
        self.entry = Gtk.Entry()
        self.entry.set_text("Sem zadejte zprávu")
        self.entry.progress_pulse()
        vbox.pack_start(self.entry, True, True, 1)
        
        button = Gtk.Button.new_with_label("Odešli")
        button.connect("clicked", self.odesli)
        vbox.pack_start(button, True, True, 0)

        button = Gtk.Button.new_with_label("Zavři")
        button.connect("clicked", self.konec)
        vbox.pack_start(button, True, True, 0)
       
        self.zprava=""
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
win.connect("delete-event", Gtk.main_quit)
win.show_all()
Gtk.main()