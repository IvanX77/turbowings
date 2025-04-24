#!/bin/bash

# Rebranding von LionWings auf LionWings
echo "[+] Starte Rebranding..."

# LionWings → LionWings
grep -rl 'lionwings' . | xargs sed -i 's/\bwings\b/lionwings/g'
grep -rl 'LionWings' . | xargs sed -i 's/\bWings\b/LionWings/g'

# LionPanel → LionPanel
grep -rl 'LionPanel' . | xargs sed -i 's/\bPelican\b/LionPanel/g'
grep -rl 'lionpanel' . | xargs sed -i 's/\bpelican\b/lionpanel/g'

# Go-Modul anpassen
sed -i 's/github.com\/lionpanel-dev\/lionwings/github.com\/IvanX77\/lionwings/g' go.mod

# Abhängigkeiten installieren
echo "[+] Installiere Go-Abhängigkeiten..."
go mod tidy
go mod vendor

# Erstelle das Binary
echo "[+] Baue das Binary..."
go build -o lionwings

# Mach das Binary ausführbar
chmod +x lionwings

# Systemd-Service erstellen
echo "[+] Erstelle Systemd-Service..."

cat <<EOF > /etc/systemd/system/lionwings.service
[Unit]
Description=LionWings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
Restart=always
ExecStart=/usr/local/bin/lionwings

[Install]
WantedBy=multi-user.target
EOF

# Binary nach /usr/local/bin verschieben
mv lionwings /usr/local/bin/lionwings

# Systemd-Dienst aktivieren und starten
systemctl daemon-reload
systemctl enable --now lionwings

# Logs anzeigen
echo "[+] Überprüfe Service-Status..."
systemctl status lionwings

echo "[+] LionWings Installation abgeschlossen!"
