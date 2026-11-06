# RETRO ROLEPLAY — Family Operations

Statisches Kontrollzentrum für die Verwaltung einer GTA-RP-Familie. Die Anwendung benötigt weder Build-Schritt noch eigenen Server. GitHub Pages veröffentlicht die Seite nach jedem Push auf `main` automatisch.

## Nutzung

Die Live-Seite: https://undefinedclub.github.io/retro-roleplay/

Mitglieder, Aufgaben, Finanzen, Lagerbestände und Termine lassen sich direkt in der Anwendung verwalten. Änderungen werden im lokalen Browser gespeichert.

Unter **Einstellungen** kannst du ein JSON-Backup exportieren oder importieren. Die Beispieldaten lassen sich dort ebenfalls wiederherstellen.

## Hinweise

- Alle Daten verbleiben im `localStorage` des verwendeten Browsers und werden nicht synchronisiert.
- Die Schriftarten werden von Google Fonts geladen; bei fehlender Verbindung greift eine lokale generische Ersatzschrift.
- Für mehrere Nutzer mit gemeinsamem Datenstand wäre ein eigener Backend-Dienst erforderlich; diese statische Version arbeitet bewusst ohne Server.