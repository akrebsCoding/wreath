1. Wir machen einen Nmap Scan mit folgendem Befehl:

>sudo nmap -p 1-15000 10.200.105.200 -vv > nmap.txt

2. Wir kriegen 5 Ports zurücl, wobei einer closed ist. Dann scannen wir diese 5 Ports nochmal mit foglendem Befehl:

>sudo nmap -p 22,80,443,9090,10000 10.200.105.200 -vv -sC -sV -O > nmap.txt

3. Wir machen ein wenig OSINT und tragen folgende Infos zusammen:

    - Thomas Wreath
    - Webentwickler mit PHP, Python, NodeJS und Golang
    - Spezialisiert auf CentOS LAMP installlationen
    - Kennt sich mit diesen Netzwerken aus: Windows, Linux and BSD hosts (as well as any necessary embedded systems)
    - Experience
        - 2019 - Present
            Freelance Developer
            Thomas Wreath Development

            Yorkshire, United Kingdom
        
        - 2016 - 2019
            Development Team Leader
            Vanguard Software Solutions, Ltd

            Solihull, United Kingdom
        
        - 2012 - 2016
            Software Developer
            New Year Software, Ltd

            Edinburgh, United Kingdom
        
        - 2007 - 2012
            Systems Administrator
            Edinburgh University

            Edinburgh, United Kingdom
    - Mag die Buchauthoren Philip Pullman, Daniel Keyes and George Orwell. 
    - Fing mit 7 Jahren auf einem Commodore 64 an
    - Geht gerne Hiken in Yorkshire
    
```
Contact
Address
21 Highland Court,
Easingwold,
East Riding,
Yorkshire,
England,
YO61 3QL
Phone Number
01347 822945
Mobile Number
+447821548812
Email
me@thomaswreath.thm
```

4. Wir sehen, dass auf dem Host eine vulnerable Webmin Version die wir exploiten können

5. Wir kriegen eine Shell und erstellen eine Reverse Shell und Upgrade diese mit:
>python3 -c 'import pty; pty.spawn("/bin/bash")'

6. Wir schauen uns die /etc/shadow Datei an und kriegen den Hash für den Root User:
>root:$6$i9vT8tk3SoXXxK2P$HDIAwho9FOdd4QCecIJKwAwwh8Hwl.BdsbMOUAd3X/chSCvrmpfy.5lrLgnRVNq6/6g0PxK9VqSdy47/qKXad1::0:99999:7:::

7. Wir können den Hash leider nicht cracken, da das Passwort wohl komplex ist. 

8. Wir kopieren uns den Inhalt der /root/.ssh/id_rsa Datei und fügen ihn in eine Datei auf unserem Computer ein. Damit loggen wir uns als root User per SSH ein:

>ssh -i ./id_rsa root@10.200.105.200

