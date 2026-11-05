# JARVIS – dein persönlicher Sekretär (Handy-App)

Web-App (PWA), die du auf dem Handy-Startbildschirm installierst. Das „Gehirn" ist Claude.

**Kann:** Chat & Sprache (spricht dich mit „Chef" an) · erklärt Schulstoff · Aufgaben/Hausaufgaben · Termine (Google Kalender oder lokal) · Gmail lesen, zusammenfassen, Antworten entwerfen & senden (nur nach deiner Bestätigung) · überwacht Mails alle 5 Min. · Morgen-Briefing · Erinnerungen · „ruft an" (Vollbild-Anruf mit Sprachgespräch).

## 1. Online stellen (GitHub Pages)
1. GitHub → dieses Repo → **Settings → Pages**
2. Source: *Deploy from a branch*, Branch: `jarvis-app`, Ordner `/ (root)` → Save
3. Nach ~1 Min.: `https://leonardbenn7-cmyk.github.io/claude/`

(Bei privatem Repo braucht Pages GitHub Pro – sonst Repo auf öffentlich stellen. Deine Keys liegen nie im Repo, nur auf deinem Handy.)

## 2. Aufs Handy
- **Android (Chrome):** Seite öffnen → ⋮ → „App installieren"
- **iPhone (Safari):** Teilen → „Zum Home-Bildschirm"

## 3. Claude API-Key
console.anthropic.com → API Keys → Key erstellen → in der App unter ⚙️ Setup eintragen. Kostet nach Verbrauch (ein paar Cent pro Gespräch; Haiku ist am billigsten).

## 4. Gmail + Kalender (optional, ~10 Min.)
1. console.cloud.google.com → neues Projekt
2. **APIs & Dienste → Bibliothek:** „Gmail API" und „Google Calendar API" aktivieren
3. **OAuth-Zustimmungsbildschirm:** Extern, App-Name „Jarvis", deine Mail als **Testnutzer** hinzufügen
4. **Anmeldedaten → OAuth-Client-ID → Webanwendung**, Autorisierte JavaScript-Quelle: `https://leonardbenn7-cmyk.github.io`
5. Client-ID kopieren → App ⚙️ Setup → „Mit Google verbinden"

Google zeigt eine Warnung „App nicht überprüft" – normal, weil es deine eigene App ist → „Weiter".

## Grenzen (ehrlich)
- **Anrufen:** Jarvis ruft *in der App* an (Klingeln, Vibration, Sprachgespräch) – keine echte Telefonnummer. Dafür bräuchte man einen Server + Dienst wie Twilio (kostet).
- **Überwachung/Briefing** laufen nur, solange die App offen ist oder im Hintergrund lebt. Das Handy beendet Web-Apps irgendwann. Das Briefing kommt dann beim nächsten Öffnen nach der eingestellten Uhrzeit.
- Spracherkennung klappt am besten in Chrome (Android). Auf dem iPhone ist sie eingeschränkt.
- Google-Login läuft nach 1 Std. ab und wird beim Öffnen automatisch erneuert.
