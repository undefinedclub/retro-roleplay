# RETRO ROLEPLAY — Family Operations

Statisches Kontrollzentrum für die Verwaltung einer GTA-RP-Familie. Die Anwendung benötigt weder Build-Schritt noch eigenen Server. GitHub Pages veröffentlicht die Seite nach jedem Push auf `main` automatisch.

## Nutzung

Die Live-Seite: https://undefinedclub.github.io/retro-roleplay/

Mitglieder, Telefonbuch, Familieninfos, Aufgaben, Finanzen, Kredite, Equipment-Ausgaben, Lager, Routen, Personenakten und Termine lassen sich direkt in der Anwendung verwalten. Ohne Cloud-Konfiguration bleiben Änderungen im lokalen Browser.

Unter **Einstellungen** kannst du ein JSON-Backup exportieren oder importieren. Die Beispieldaten lassen sich dort ebenfalls wiederherstellen.

## Gemeinsame Cloud

Die Supabase-Projektkonfiguration ist in `supabase-config.js` hinterlegt. Die geschützte Tabellen-/RPC-Struktur ist erreichbar. Aktive Familienkonten werden in `public.app_members` freigeschaltet. Im Cloud-Modus erfolgt die Anmeldung mit Benutzername und Passwort.

1. Erstelle ein Supabase-Projekt im Free-Tarif.
2. Führe alle SQL-Dateien unter `supabase/migrations/` in Zeitstempel-Reihenfolge einmal im SQL Editor des Projekts aus. Sie erstellen Schema/RLS/privaten Storage-Bucket, den relationalen Spiegel samt Löschprotokoll und die owner-geschützte Benutzerverwaltung.
3. Lege in **Authentication → Users** das Owner-Konto an. Als Auth-E-Mail verwendest du den internen Alias `ownername@users.retro-roleplay.invalid` (mit `ownername` als gewünschtem Benutzernamen) und bestätigst das Konto in Supabase. Ändere bei einem bereits vorhandenen Konto dessen Auth-E-Mail auf diesen Alias. Kopiere seine User-UUID und trage im SQL Editor ein:

	```sql
	insert into public.app_members (user_id, username, role, active, discord_id)
	values ('HIER-DIE-USER-UUID', 'ownername', 'owner', true, '1434906594742632603')
	on conflict (user_id) do update
	set username = excluded.username, role = 'owner', active = true,
	    discord_id = excluded.discord_id;
	```

4. Trage Projekt-URL und Publishable Key in [`supabase-config.js`](supabase-config.js) ein. Nur den Publishable Key verwenden; niemals den Service-Role-Key eintragen.
5. Committe und pushe die Konfiguration. Der Owner kann unter **Berechtigungen** weitere Personen freischalten und Zugänge widerrufen. Dafür muss ein Auth-Konto zuerst in Supabase angelegt und bestätigt werden. Seine Auth-E-Mail muss dem internen Muster `benutzername@users.retro-roleplay.invalid` entsprechen; für die Anmeldung in der App genügt dann Benutzername und Passwort. Beim Widerruf wird nur der App-Zugang entfernt, nicht das Supabase-Auth-Konto.

Vor einem ersten Upload oder Wechsel auf vorhandene Cloud-Daten fordert die App eine Bestätigung an und erstellt ein Backup. Workspace-Schreibvorgänge verwenden Revisionsnummern; Konflikte und Sync-Fehler werden angezeigt. Route-Bilder liegen im privaten Bucket `route-images` und werden nicht als Base64 im LocalStorage abgelegt.

## Hinweise

- Ohne Supabase-Konfiguration verbleiben Daten im `localStorage` und werden nicht synchronisiert.
- Die Passwortabfrage ist eine clientseitige Zugangshürde, keine echte Zugriffskontrolle: GitHub Pages stellt HTML, JavaScript und den Passwortprüfwert öffentlich bereit. Vertrauliche Daten sind dort nicht geschützt.
- Die Schriftarten werden von Google Fonts geladen; bei fehlender Verbindung greift eine lokale generische Ersatzschrift.
- Bei aktivierter Cloud werden Authentifizierung und gemeinsame Zugriffe über Supabase geregelt. GitHub Pages selbst bleibt öffentlich; die App-Daten sind durch Supabase RLS geschützt.
- Ohne Cloud bleibt das Familienpasswort nur eine clientseitige Hürde und ist kein echter Zugriffsschutz.