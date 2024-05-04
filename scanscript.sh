#!/bin/bash

start_ip="10.200.1.1"
end_ip="10.200.254.254"

IFS='.' read -r -a start_ip_octets <<< "$start_ip"
IFS='.' read -r -a end_ip_octets <<< "$end_ip"

for i in $(seq ${start_ip_octets[2]} ${end_ip_octets[2]}); do
    for j in $(seq ${start_ip_octets[3]} 254); do
        ip="${start_ip_octets[0]}.${start_ip_octets[1]}.$i.$j"
        echo "Scanning IP: $ip"
        nmap "$ip" -Pn -vv  # Hier kannst du nmap-Optionen hinzufügen, wie benötigt
    done
done
