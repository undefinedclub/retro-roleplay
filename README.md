# RETRO ROLEPLAY — Family Operations

Statisches Kontrollzentrum für die Verwaltung einer GTA-RP-Familie. Die Anwendung benötigt weder Build-Schritt noch eigenen Server. GitHub Pages veröffentlicht die Seite nach jedem Push auf `main` automatisch.

## Nutzung

Die Live-Seite: https://undefinedclub.github.io/retro-roleplay/

Mitglieder, Telefonbuch, Familieninfos, Aufgaben, Finanzen, Kredite, Equipment-Ausgaben, Lager, Routen, Personenakten und Termine lassen sich direkt in der Anwendung verwalten. Ohne Cloud-Konfiguration bleiben Änderungen im lokalen Browser.

Unter **Einstellungen** kannst du ein JSON-Backup exportieren oder importieren. Die Beispieldaten lassen sich dort ebenfalls wiederherstellen.

## Gemeinsame Cloud

Die Supabase-Projektkonfiguration ist in `supabase-config.js` hinterlegt. Die geschützte Tabellen-/RPC-Struktur ist erreichbar. Der erste zugelassene Auth-Nutzer muss noch als Familienmitglied in `public.app_members` eingetragen werden.

1. Erstelle ein Supabase-Projekt im Free-Tarif.
2. Führe beide SQL-Dateien unter `supabase/migrations/` in Zeitstempel-Reihenfolge einmal im SQL Editor des Projekts aus. Sie erstellen Schema/RLS/privaten Storage-Bucket und anschließend den relationalen Spiegel samt Löschprotokoll.
3. Lege in **Authentication → Users** den ersten Nutzer an und kopiere seine User-UUID. Führe im SQL Editor aus:

	```sql
	insert into public.app_members (user_id, role, active)
	values ('HIER-DIE-USER-UUID', 'admin', true)
	on conflict (user_id) do update set role = 'admin', active = true;
	```

	Weitere freigegebene Nutzer kommen ebenfalls in `app_members`, mit `role = 'member'`.
4. Trage Projekt-URL und Publishable Key in [`supabase-config.js`](supabase-config.js) ein. Nur den Publishable Key verwenden; niemals den Service-Role-Key eintragen.
5. Committe und pushe die Konfiguration. Anmeldung, Workspace-Sync und privater Route-Bildspeicher verwenden Supabase; RLS erlaubt nur aktive Einträge in `app_members`.

Vor einem ersten Upload oder Wechsel auf vorhandene Cloud-Daten fordert die App eine Bestätigung an und erstellt ein Backup. Workspace-Schreibvorgänge verwenden Revisionsnummern; Konflikte und Sync-Fehler werden angezeigt. Route-Bilder liegen im privaten Bucket `route-images` und werden nicht als Base64 im LocalStorage abgelegt.

## Hinweise

- Ohne Supabase-Konfiguration verbleiben Daten im `localStorage` und werden nicht synchronisiert.
- Die Passwortabfrage ist eine clientseitige Zugangshürde, keine echte Zugriffskontrolle: GitHub Pages stellt HTML, JavaScript und den Passwortprüfwert öffentlich bereit. Vertrauliche Daten sind dort nicht geschützt.
- Die Schriftarten werden von Google Fonts geladen; bei fehlender Verbindung greift eine lokale generische Ersatzschrift.
- Bei aktivierter Cloud werden Authentifizierung und gemeinsame Zugriffe über Supabase geregelt. GitHub Pages selbst bleibt öffentlich; die App-Daten sind durch Supabase RLS geschützt.
- Ohne Cloud bleibt das Familienpasswort nur eine clientseitige Hürde und ist kein echter Zugriffsschutz.