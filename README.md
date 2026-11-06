# RETRO ROLEPLAY — Family Operations

Statisches Kontrollzentrum für die Verwaltung einer GTA-RP-Familie. Die Anwendung benötigt weder Build-Schritt noch eigenen Server. GitHub Pages veröffentlicht die Seite nach jedem Push auf `main` automatisch.

## Nutzung

Die Live-Seite: https://undefinedclub.github.io/retro-roleplay/

Mitglieder, Telefonbuch, Familieninfos, Aufgaben, Finanzen, Kredite, Equipment-Ausgaben, Lager, Routen, Personenakten und Termine lassen sich direkt in der Anwendung verwalten. Änderungen werden im lokalen Browser gespeichert.

Unter **Einstellungen** kannst du ein JSON-Backup exportieren oder importieren. Die Beispieldaten lassen sich dort ebenfalls wiederherstellen.

## Hinweise

- Alle Daten verbleiben im `localStorage` des verwendeten Browsers und werden nicht synchronisiert.
- Die Passwortabfrage ist eine clientseitige Zugangshürde, keine echte Zugriffskontrolle: GitHub Pages stellt HTML, JavaScript und den Passwortprüfwert öffentlich bereit. Vertrauliche Daten sind dort nicht geschützt.
- Die Schriftarten werden von Google Fonts geladen; bei fehlender Verbindung greift eine lokale generische Ersatzschrift.
- Ein gemeinsamer Datenstand oder echter privater Zugriff erfordert einen geschützten Hosting-Anbieter bzw. Backend-Dienst; diese statische Version arbeitet bewusst ohne Server.
- Das Familienpasswort lässt sich unter **Einstellungen** ändern; ohne Server gilt die Änderung nur in diesem Browser. Die Sitzung kann dort auch gesperrt werden.