---
title: "BankID-smishingkit — teknisk analyse"
subtitle: "Flertrinns innsamling av påloggingsdata med sanntidseksfiltrering via Telegram, rettet mot norske bankkunder"
author: "0xS3J4D"
version: "2.0"
date: "November 2026"
lang: nb
---

| | |
|---|---|
| **Rapport-ID** | 0xS3-TR-2026-01 |
| **Versjon** | 2.0 (revidert utgave — se endringslogg) |
| **Opprinnelig analyse** | Mars 2026 |
| **Gradering** | TLP:CLEAR — offentlig, sensitive indikatorer sladdet |
| **Kategori** | Analyse av phishingkit / trusseletterretning |
| **Mål** | Norske BankID-brukere (geofiltrert til `countryCode: NO`) |
| **Leveringsmetode** | SMS-phishing (smishing) med forfalsket avsender |
| **Kittype** | PHP på serversiden, eksfiltrering via Telegram Bot API |
| **Metode** | Statisk kodegjennomgang — kittet ble aldri kjørt |

> **Ansvarsfraskrivelse.** Rapporten er publisert for læring, sikkerhetsbevissthet og forsvar. Den beskriver hvordan et eksisterende phishingkit fungerer, slik at det kan gjenkjennes, oppdages og stoppes — den er ikke en oppskrift på å lage eller drive et. Ingen angrep ble utført, ingen aktiv infrastruktur eller offerdata ble berørt, og kittet ble aldri satt i drift. Nøkler, tokener, ID-er og brukernavn er sladdet, og domener er «defanget» (`example[.]com`).

# 1. Sammendrag

Et komplett phishingkit som utgir seg for å være **BankID** kom til forfatteren som en helt vanlig smishing-SMS. Forfatteren oppdaget et forfalsket domene, hentet kittets ZIP-arkiv fra lenken og analyserte det statisk. Kittet er laget for å spres via SMS med forfalsket avsender, og fører offeret gjennom **fem innsamlingssteg** — bank, fødselsnummer, telefonnummer, engangskode og personlig passord — før offeret sendes videre til den ekte `bankid.no`.

Hvert felt sendes **i sanntid til operatøren via en Telegram-bot**. Det gjør kittet til mer enn et passordlager: en operatør som følger med i kanalen kan bruke en fersk engangskode mot den ekte BankID-tjenesten før den utløper — et klassisk «adversary-in-the-middle»-angrep (AiTM).

Kittet beskytter seg med geofilter (kun Norge), krav om mobil nettleser, tegn-for-tegn-tilsløring av DOM-en mot innholdsbasert deteksjon, og `noindex`-metatagger.

**Det viktigste for forsvarere**

| | Funn | Hvorfor det betyr noe |
|---|---|---|
| 1 | Engangskoden sendes i sanntid via Telegram | Muliggjør kontoovertakelse mens offeret er på siden; engangskode alene stopper det ikke |
| 2 | Samler inn fødselsnummer | Permanent identifikator — kan ikke byttes etter lekkasje |
| 3 | Geo- og enhetsfiltrering | Sandkasser og skannere utenfor Norge eller på PC ser bare en videresending |
| 4 | Tilsløring av sideteksten | Omgår enkel tekstbasert deteksjon av phishingsider |
| 5 | Hardkodede hemmeligheter i `config.php` | Verdifulle indikatorer for nedtaking og jakt |

# 2. Hvordan undersøkelsen startet

Forfatteren mottok selv SMS-en som et potensielt offer. Dette var altså ikke et utlevert testeksemplar:

1. **Meldingen så ekte ut.** Fordi avsendernavnet var forfalsket, havnet SMS-en i samme tråd som tidligere, ekte meldinger fra BankID. Ingenting ved avsenderen virket galt.
2. **Lenken gjorde ikke det.** Ved nærmere ettersyn sto det `bankld` i domenet — med en liten **L** i stedet for **i**. Den forskjellen er nesten usynlig på en mobilskjerm.
3. **Sjekk.** Da forfatteren skrev domenet med en ekte `i`, fungerte ikke lenken — BankID har ingen side på den adressen. Dermed var det bekreftet at lenken gikk til et forfalsket domene (typosquatting), ikke til BankID.
4. **Innsamling.** I stedet for å taste inn noe, prøvde forfatteren å lagre en kopi av siden for analyse. Lenken ga da et ZIP-arkiv med hele kittet (PHP, HTML, JavaScript og CSS), som er grunnlaget for denne rapporten.

Ingen personopplysninger ble tastet inn på siden. Hele domenet er holdt tilbake i den offentlige utgaven.

**Lærdom:** avsendernavn kan ikke stoles på, og en kjent meldingstråd beviser ingenting. Det eneste angriperen ikke kunne forfalske var domenet — og én bokstav avslørte det.

# 3. Bakgrunn

## 3.1 Hvorfor BankID er et attraktivt mål

Nesten alle voksne i Norge bruker BankID for å logge inn i nettbank, hos Skatteetaten, på helseportaler og i mange andre tjenester. En stjålet BankID-økt gjelder derfor ikke bare én konto — den kan gi tilgang til flere banker og offentlige tjenester samtidig.

## 3.2 Levering: smishing med forfalsket avsender

Leveringsmetoden er bekreftet førstehånds (kapittel 2). Den stemmer også med kittets utforming (kun mobil, norsk geofilter, BankID-profil) og med kampanjer omtalt offentlig av NRK, Telenor, DNB og politiet [1–7].

Med forfalsket avsender ser SMS-en ut til å komme fra «BankID», «DNB» eller et annet kjent navn, og kan havne **i en eksisterende, ekte meldingstråd** på telefonen. Da er den svært vanskelig å skille fra ekte meldinger [5][6].

> **Viktig:** BankID sier at de aldri sender SMS med lenker. En SMS som påstår å være fra BankID og inneholder en lenke, er svindel [3].

## 3.3 Typiske lokkemeldinger

Typiske temaer fra offentlige saker (ikke hentet fra kittet):

| Tema | Eksempel | Psykologisk virkemiddel |
|---|---|---|
| Sperret konto | «BankID: Din BankID er midlertidig sperret. Gjenopprett nå: [lenke]» | Hastverk, frykt for å miste tilgang |
| Mistenkelig aktivitet | «Det er oppdaget mistenkelig aktivitet på din konto. Bekreft her: [lenke]» | Frykt for uautorisert tilgang |
| Overgang | «BankID Mobil skal avvikles. Oppdater nå for å beholde tilgang: [lenke]» | Utnytter ekte endringer i tjenesten |
| Skattesesong | «Skatteetaten: Skatteoppgjøret ditt er klart. Se beregningen: [lenke]» | Sesongbasert tillit |
| Bankinnlogging | «DNB: Uvanlig innlogging registrert. Bekreft din identitet: [lenke]» | Bankimitasjon + hastverk |

Da BankID på mobil (SIM-basert) ble faset ut i 2023, brukte svindlerne selve overgangen som påskudd [3][7].

## 3.4 Omfang

DNBs Financial Cyber Crime Center rapporterte svindelforsøk mot banken og kundene på rundt 1,8 milliarder kroner i 2023 [5], og for 2024 ble det meldt om rekordmange ofre for BankID-relatert svindel [8].

# 4. Mål med analysen

1. Kartlegge hele offerets vei gjennom kittet og alle datafelt som samles inn.
2. Finne eksfiltreringsmetoden og hente ut kompromitteringsindikatorer (IOC-er).
3. Dokumentere teknikker for unnvikelse og antianalyse.
4. Vurdere konsekvensene for ofrene og det norske ID-økosystemet.
5. Koble funnene til MITRE ATT&CK og lage deteksjonsregler forsvarere kan bruke.

# 5. Omfang og metode

## 5.1 Omfang

Arkivet inneholdt 29 filer. De funksjonelt viktige er:

| Fil | Rolle |
|---|---|
| `index.php` | Steg 1 — valg av bank |
| `11siffer.php` | Steg 2 — fødselsnummer (11 siffer) |
| `telefonnummer.php` | Steg 3 — telefonnummer |
| `6siffer.php` | Steg 4 — engangskode (6 siffer) |
| `Personlig-passord.php` | Steg 5 — personlig passord |
| `success.php` | Videresending til ekte `bankid.no` |
| `action.php` | Bakende: tar imot POST-data og sender videre til Telegram |
| `config.php` | Hardkodet Telegram-bottoken og chat-ID |
| `block.php` | Geo-IP-filter (kun Norge) |
| `files/` | Kopiert BankID-CSS, SVG-logoer, favikon og lasteanimasjon (resten av filene) |

## 5.2 Metode

| Fase | Aktivitet |
|---|---|
| Innsamling | Oppdaget det forfalskede domenet `bankld` i en mottatt SMS og hentet kittets ZIP-arkiv fra lenken i stedet for å taste inn data. |
| Triage | Pakket ut arkivet og gikk gjennom fillisten. Norske filnavn (`siffer`, `telefonnummer`, `passord`) og kombinasjonen `config.php` + `action.php` tydet på et kit som eksfiltrerer via Telegram. |
| Flytkartlegging | Leste hver side i rekkefølge og fulgte jQuery AJAX-kall og `location.href`-videresendinger for å rekonstruere offerets vei. |
| Bakendeanalyse | Koblet hver POST-handler i `action.php` (`bankselect`, `11siffer`, `telefonnummer`, `6siffer`, `personligpassord`, `card`) til tilhørende Telegram-kall. |
| Unnvikelse | Gikk gjennom `block.php` og JavaScript på hver side. |
| IOC-uttrekk | Samlet hardkodede infrastrukturverdier, videresendingsdomener og fingeravtrykk av filer. |
| Kontekst | Sammenholdt levering og konsekvenser med offentlige norske kilder. |

Alt arbeid var statisk. Interaksjon med operatørens infrastruktur (for eksempel med bottokenet) var bevisst **utenfor omfang**: det ville innebære å bruke kriminelles påloggingsdata uten fullmakt, og kunne varsle operatøren eller ødelegge bevis.

# 6. Teknisk analyse

## 6.1 Offerets vei

```
 SMS med lenke ──► [block.php] geofilter: kun NO ──► [JS] krav om mobil
                                                           │
   ┌───────────────────────────────────────────────────────┘
   ▼
 1 index.php            valg av bank          ──┐
 2 11siffer.php         fødselsnummer         ──┤
 3 telefonnummer.php    telefonnummer         ──┼─► action.php ─► Telegram ─► operatør
 4 6siffer.php          engangskode           ──┤        (hvert steg, i sanntid)
 5 Personlig-passord    personlig passord     ──┘
   ▼
 6 success.php  ──► videresending til ekte https://www.bankid.no/privat/
```

| Steg | Side | Data | Sendt til Telegram |
|---|---|---|---|
| 1 | `index.php` | Bank (nedtrekksliste med 40+ norske banker) | Bank + IP + økt-ID |
| 2 | `11siffer.php` | Fødselsnummer | Fødselsnummer + IP + økt-ID |
| 3 | `telefonnummer.php` | Mobilnummer | Telefon + IP + økt-ID |
| 4 | `6siffer.php` | 6-sifret engangskode | Kode + IP + økt-ID |
| 5 | `Personlig-passord.php` | Personlig passord | Passord + IP + økt-ID |
| 6 | `success.php` | — | — |

Hvert steg sendes til `action.php` via AJAX før neste side vises, så **et offer som avbryter halvveis har likevel lekket alt som er tastet inn**.

## 6.2 Geofilter (`block.php`)

Kittet slår opp i den kommersielle tjenesten `pro.ip-api.com` med en hardkodet API-nøkkel. Bare norske IP-adresser slipper gjennom; alle andre sendes til et annet domene. `localhost` er hvitlistet slik at operatøren kan teste lokalt.

```php
// block.php — forenklet, nøkkel sladdet
$ip_infos = file_get_contents('https://pro.ip-api.com/php/' . $ip . '?key=<SLADDET>&fields=countryCode');
if (in_array($ip_infos['countryCode'], ['NO'])) {
    $_SESSION['user_allowed'] = true;
} else {
    header('Location: http://scampage[.]net/');
    exit();
}
```

Dette snevrer inn offergruppen og skjuler kittet for forskere, skannere og sandkasser som ikke bruker norsk IP.

## 6.3 Kun mobil

Hver side skjuler innholdet til en sjekk av nettleserens user-agent er bestått. Besøkende på PC sendes bort før noe vises.

```javascript
var isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);
if (!isMobile) { window.location.href = 'https://scampages[.]net'; }
else           { document.body.style.display = 'block'; }
```

Dette passer med smishing: offeret trykker på lenken på den samme telefonen som mottok SMS-en.

## 6.4 Eksfiltrering i sanntid via Telegram

`action.php` sender hver innsending til Telegram Bot API med token og chat-ID fra `config.php`. Meldingsformat (verdier sladdet):

```
+----/!\----<.![+] Bankid 11-siffer [+]!.>---/!\----+
[11-siffer] : <fødselsnummer>
[ID]        : <øktens tidsstempel>
[IP]        : http://geoiptool[.]com/en/?ip=<offerets IP>
+----Contact Me IF YOU NEED HELP : @[SLADDET] \----+>
```

- **Økt-ID-en** (et Unix-tidsstempel) lar operatøren koble sammen bitene fra ett og samme offer.
- **«Contact me»**-linjen med et Telegram-brukernavn er typisk for kit som selges eller deles; brukernavnet kan tilhøre utvikleren og ikke nødvendigvis den som driver kampanjen.
- Med Telegram trengs ingen egen C2-server, og trafikken går til en legitim og mye brukt tjeneste som er vanskelig å blokkere.

**AiTM.** Fordi dataene kommer frem i løpet av sekunder, kan operatøren bruke fødselsnummer, engangskode og passord til å logge inn i den ekte tjenesten mens koden fortsatt er gyldig. Telenor beskriver dette sanntidsmønsteret i norske svindelsaker [6]. Kittet inneholder ingen automatikk for dette; videreføringen gjøres manuelt av operatøren.

**Sovende korthåndtering.** `action.php` inneholder også en `card`-handler (kortnummer, utløpsdato, CVV) uten tilhørende side, noe som tyder på en felles kodebase for en større kitfamilie.

## 6.5 Falsk lasteskjerm

Etter hvert steg vises en animert BankID-spinner i åtte sekunder før neste skjema dukker opp, slik offeret er vant til fra den ekte tjenesten.

```javascript
setTimeout(function () {
    document.getElementById('wait').style.display = 'none';
    document.getElementById('getNnin').style.display = 'block';
}, 8000);
```

## 6.6 Tilsløring av DOM-en

Ved innlasting skrives all synlig tekst om slik at hvert tegn pakkes inn i sitt eget `<font>`- eller egendefinerte `<az>`-element, og tilfeldige klassenavn legges til:

```javascript
const modifiedText = [...text].map(letter => `<font>${letter}</font>`).join('');
element.classList.add(`class-${rndLetter}${rndNum}-class-${rndLetter1}${rndNum1}`);
```

Offeret ser vanlig tekst, men en skanner som leser DOM-en finner ikke ord som `BankID` eller `Fødselsnummer` som sammenhengende tekst, og klassebaserte fingeravtrykk endres ved hver innlasting. Selve mønsteret — hundrevis av elementer med ett tegn hver — er likevel et sterkt deteksjonssignal (se kapittel 10).

## 6.7 Skjult for søkemotorer

Alle sider har `<meta name="robots" content="noindex, nofollow">`, slik at URL-ene ikke dukker opp i søk eller oppdages av robotsøk.

## 6.8 Videresending etter innsamling

`success.php` sender offeret til ekte `https://www.bankid.no/privat/`. Når offeret havner på den ekte siden, forsvinner det tydeligste tegnet på at noe var galt, og varsling skjer senere.

# 7. Hovedfunn

1. **Smishing bekreftet førstehånds** — forfatteren mottok SMS-en i en eksisterende BankID-tråd; lenken brukte domenet `bankld`.
1. **Laget for smishing** — krav om mobil, norsk geofilter og BankID-profil peker alle mot SMS-levering.
2. **Fem innsamlingssteg**: bank, fødselsnummer, telefonnummer, engangskode og passord.
3. **Eksfiltrering per felt i sanntid via Telegram**, som muliggjør AiTM med engangskoden.
4. **Hardkodet bottoken, chat-ID og operatørens brukernavn** — konkrete IOC-er.
5. **Flere lag med unnvikelse**: geofilter, user-agent-filter, tegn-for-tegn-tilsløring, tilfeldige klassenavn, `noindex`.
6. **Tro kopi av BankID**: originale CSS-filer, SVG-logoer, favikon og spinner.
7. **Sovende funksjon for kortdata**, som tyder på en gjenbrukbar kitfamilie.
8. **Tillitsbevarende avslutning** med videresending til ekte `bankid.no`.

# 8. Konsekvenser

| Data | Konsekvens |
|---|---|
| Fødselsnummer | Permanent identifikator i bank, helse og offentlig sektor. Kan ikke endres; muliggjør ID-tyveri over lang tid. |
| Engangskode | Kan brukes mot den ekte tjenesten mens den er gyldig, og gir angriperen en innlogget økt. |
| Personlig passord | Andre BankID-faktor; sammen med det over gir det innlogging. |
| Telefonnummer | Åpner for oppfølgende telefonsvindel («dette er bankens svindelavdeling …») og ny smishing. |
| Offerets IP | Lar operatøren etterligne offerets region dersom banken sjekker lokasjon. |

Siden BankID brukes av svært mange norske tjenester, kan én vellykket økt ramme flere banker og offentlige tjenester samtidig. Fordi offeret havner på den ekte siden, merker mange det ikke før pengene er borte.

# 9. MITRE ATT&CK

Koblet mot ATT&CK Enterprise (og Mobile for SMS-delen). Revidert i v2.0 — se endringslogg.

| Taktikk | ID | Teknikk | Observert atferd |
|---|---|---|---|
| Resource Development | T1583.001 | Acquire Infrastructure: Domains | Forfalsket domene `bankld` (l i stedet for i) |
| Resource Development | T1583.006 | Acquire Infrastructure: Web Services | Telegram-bot brukt som mottaker |
| Resource Development | T1608.005 | Stage Capabilities: Link Target | PHP-kittet ligger bak SMS-lenken |
| Reconnaissance | T1598.003 | Phishing for Information: Spearphishing Link | Lenke til flertrinns datainnsamling |
| Initial Access | T1566.002 | Phishing: Spearphishing Link | Lenken leveres via forfalsket SMS |
| Initial Access (Mobile) | T1660 | Phishing | SMS som leveringskanal |
| Defense Evasion | T1656 | Impersonation | Kopiert BankID-profil, lasteskjerm og flyt |
| Defense Evasion | T1480 | Execution Guardrails | Innhold vises bare for norske IP-er på mobil |
| Defense Evasion | T1027 | Obfuscated Files or Information | Tegn-for-tegn-innpakking og tilfeldige klassenavn |
| Credential Access / Collection | T1056.003 | Input Capture: Web Portal Capture | Falske skjemaer fanger alle felt |
| Credential Access | T1111 | Multi-Factor Authentication Interception | Engangskoden fanges i sanntid |
| Exfiltration | T1567 | Exfiltration Over Web Service | Hvert felt sendes til Telegram Bot API |
| Impact | T1657 | Financial Theft | Endelig mål: kontoovertakelse og overføringer |

# 10. Deteksjon og tiltak

## 10.1 For SOC og deteksjonsteam

- **Kit på disk / hos hostingleverandør:** bruk YARA-regelen i [`detection/bankid_kit.yar`](../detection/bankid_kit.yar) for å skanne webrøtter og kitarkiver. Den kombinerer de norske filnavnene med referanser til Telegram og ip-api.
- **Heuristikk på ferdig side:** flagg sider der en stor andel tekstnoder er enkelttegn i `<font>`/`<az>`, kombinert med BankID-elementer på et domene som ikke tilhører BankID.
- **Passiv fingeravtrykking:** det kopierte stilarket `authorization.feb520e19d2d6db01d95.css` og favikon-hashen kan søkes etter i urlscan.io og lignende for å finne søsterinstallasjoner.
- **Proxy / DNS:** utgående kall fra webservere til både `api.telegram.org` og `pro.ip-api.com` er uvanlig for vanlige småsider.
- **Skannetips:** analyser mistenkelige URL-er fra norsk IP med mobil user-agent — ellers viser kittet bare en videresending.

## 10.2 For banker og BankID

- Overvåk nye domener og sertifikater med *bankid*, banknavn eller norske ord (`passord`, `siffer`).
- Behandle innlogginger der enhet, IP eller tidspunkt avviker fra økten som startet flyten som høy risiko.
- Fortsett å flytte brukere over til app-basert, phishingresistent pålogging (BankID-appen med biometri) fremfor kodebrikker.

## 10.3 For privatpersoner

- Les domenet bokstav for bokstav: `bankld` er ikke `bankid`. Et kjent avsendernavn eller en kjent tråd beviser ingenting.
- BankID sender **aldri** SMS med lenker. Ikke trykk — slett meldingen.
- Gi aldri engangskode eller passord til noen, på en side du kom til via en lenke.
- Har du tastet inn noe: ring bankens sperretelefon med en gang, og anmeld deretter til politiet.

# 11. Kompromitteringsindikatorer (IOC)

Verdier er sladdet i den offentlige utgaven; se [`iocs/`](../iocs/README.md).

| Type | Indikator | Status |
|---|---|---|
| Telegram-bottoken | `[SLADDET]` | Sladdet |
| Telegram chat-ID | `[SLADDET]` | Sladdet |
| Operatørens brukernavn | `@[SLADDET]` | Sladdet |
| Phishingdomene (forfalsket) | `bankld[.][SLADDET]` | Delvis sladdet |
| Geo-IP API-nøkkel (ip-api.com) | `[SLADDET]` | Sladdet |
| Videresending (utenfor NO) | `scampage[.]net` | Offentlig |
| Videresending (PC) | `scampages[.]net` | Offentlig |
| Geooppslag i melding | `geoiptool[.]com` | Offentlig (legitim tjeneste, misbrukt) |
| Kopiert fil | `authorization.feb520e19d2d6db01d95.css` | Offentlig |
| Filnavn | `11siffer.php`, `6siffer.php`, `telefonnummer.php`, `Personlig-passord.php` | Offentlig |

Merk: videresendingsdomenene er der kittet sender uønskede besøkende; det er ikke bekreftet at operatøren eier dem.

# 12. Begrensninger

- Kun statisk analyse; kjøretidsatferd som logging på serveren kunne ikke bekreftes.
- Hostingleverandør og kampanjens omfang (andre mottakere, andre domener) er ukjent.
- Status på bottokenet ble **ikke** testet, med vilje. Det kan være tilbakekalt.
- Brukernavnet er et spor, ikke en attribusjon: det kan tilhøre utvikleren, en forhandler eller en kunde.
- Siden for kortdata mangler i denne varianten; andre varianter kan ha den.

# 13. Lærdommer

**Teknisk**

- Telegram gir kriminelle gratis, kryptert sanntids-C2 uten egen infrastruktur — forvent det i de fleste moderne kit.
- Flertrinns innsamling er verre enn én enkelt side: hvert delsteg har verdi, og stegvis flyt bygger tillit.
- Tekstmatching i DOM-en er ikke nok; strukturelle signaler (tegninnpakking, kopierte filer) er mer robuste.
- Kitutviklere hardkoder ofte hemmeligheter, noe som gir forsvarere gode spor.

**Operasjonelt**

- Geo- og enhetsfiltrerte kit krever analyseoppsett som ligner offeret (norsk IP, mobil user-agent).
- Videresendingen til den ekte siden er en undervurdert del av angrepet — den kjøper tid for operatøren.

# 14. Anbefalte neste steg

1. Rapporter bottoken og brukernavn til Telegrams misbruksteam, og del det fullstendige IOC-settet med **NorCERT / NSM**, **Nordic Financial CERT** og varemerkeeieren gjennom etablerte kanaler.
2. Meld domener til URLhaus / PhishTank og del YARA-regelen med hostingleverandører.
3. Let etter søsterinstallasjoner med hashene til kopiert CSS og favikon.
4. Gjør tilsløringsmønsteret om til en heuristikk for nettleserutvidelse eller sikker webgateway.
5. Med fullmakt: dynamisk analyse i isolert sandkasse med norsk IP og mobil user-agent — uten å sende ekte data og uten å kontakte operatørens Telegram-bot.

# Kilder

1. TV 2 — «Ny svindelmetode oppdaget i Norge». <https://www.tv2.no>
2. NRK — «Advarer mot ny BankID-svindel: Ikke følg SMS-lenker». <https://www.nrk.no>
3. BankID — «Rådene som beskytter deg mot BankID-svindel». <https://www.bankid.no/privat/sikkerhet/>
4. Nordea — «Svindel: råd og ulike former for svindel». <https://www.nordea.no>
5. DNB / svindel.no — «Se opp for SMS-svindel». <https://www.dnb.no/svindel>
6. Telenor — «Slik prøver svindlerne å lure deg i sanntid». <https://www.telenor.no>
7. Politiet — «Beskytt deg mot svindel og ID-tyveri». <https://www.politiet.no>
8. Skimsafe — «BankID-svindel øker». <https://www.skimsafe.no>
9. Criipto — «How BankID Secure Start helps prevent phishing attacks». <https://www.criipto.com>
10. MITRE ATT&CK. <https://attack.mitre.org>

# Vedlegg A — Endringslogg

| Versjon | Dato | Endringer |
|---|---|---|
| 1.0 | Mars 2026 | Første utgave (trukket tilbake). |
| 2.0 | November 2026 | Ny struktur med sammendrag og deteksjonskapittel; norsk utgave lagt til. **ATT&CK-rettelser:** T1566.001 → T1566.002 (lenke, ikke vedlegg); T1041 → T1567 (Telegram er en webtjeneste); fjernet T1078 og T1036.005 (ikke observert / feil teknikk); lagt til T1111, T1480, T1656, T1583.006, T1608.005, T1657 og Mobile T1660. Konsekvent «fem steg». Fjernet påstanden om at bottokenet var «aktivt» (ikke testet i en statisk analyse), og erstattet anbefalingen om å spørre operatørens bot med rapportering via riktige kanaler. Lagt til YARA-regel, flytdiagram og kilde-URL-er. Lagt til førstehåndsberetning om hvordan SMS-en ble mottatt og det forfalskede domenet oppdaget (kapittel 2), samt T1583.001. |
