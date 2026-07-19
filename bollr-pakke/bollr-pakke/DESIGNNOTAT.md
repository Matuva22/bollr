# Bollr — designnotat og overlevering

Alt som er bestemt så langt, samlet på ett sted. Ment for å fortsette utviklingen på PC og koble på en delt backend (Supabase).

---

## 1. Hva Bollr er

En community-app for å finne og vurdere boller på bakerier. Kjernen:

- **Anonyme vurderinger** — alle scorer er anonyme utad, så folk tør å være ærlige.
- **Innlogging for personlige lister** — «Smakt» og «Ønskeliste», synket mellom enheter.
- **Finn i nærheten** — bakerier rundt din posisjon, sortert på fellesskapets snitt.
- **Kart + veibeskrivelse** — pins på kart, lenke til Google Maps for rute.
- **Primært norsk**, men laget så turister kan bruke det (engelsk undertittel er en mulighet senere).

Navn: **bollr** (beholdes foreløpig; kandidater hvis det byttes: Bolla, Bollekart).

**Tagline (hierarki):** «Finn og ranger boller» er den forklarende produkttaglinjen under logoen (og lang form «Finn og ranger Norges beste boller» ved innlogging). «Norges beste boller» brukes som *ambisjonslinje* — overskrift på Kåring-siden og i markedsføring («Bli med å kåre Norges beste bolle») — ikke som hovedtagline, siden den beskriver en påstand snarere enn hva appen gjør. Følger navnet til merket er kjent nok til å stå alene — samme grep som Untappd.

---

## 2. Visuell identitet

Rolig, «eksklusivt konditori» heller enn app-butikk. Mye luft, rolige flater, serif-typografi, ingen sterke farger.

### Palett

| Rolle | Navn | HEX |
|---|---|---|
| Bakgrunn | Lys deig | `#F7EFDD` |
| Innsatsflate (kart, felt) | Deig dypere | `#EFE3C8` |
| Aksent | Kanel | `#6F4A2F` |
| Tekst / dyp | Kardemomme | `#141210` |
| Dempet tekst | Stone | `#8A7D6D` |

### Typografi

- **Fraunces** (lett serif, vekt 300–400) — logo, overskrifter, navn, score.
- **Inter** (400–600) — brødtekst, etiketter, knapper.
- Begge fra Google Fonts. NB: bør pakkes lokalt for garantert offline-visning.

### Logo

- **Spiral** = én tynn, jevn linje (kanelbolle-snurr sett ovenfra). Uten fyll.
- **Ordmerke** = `bollr` i Fraunces, liten forbokstav, vid bokstavsperring, med litt tyngre `r`.
- Fungerer som spiral alene (ikon) + ordmerke (i appen).

### Ikoner (ligger i pakken)

- `icon-512.png` / `icon-180.png` / `icon-192.png` — **hovedikon**: lys-deig-spiral på kardemomme-sort.
- `icon-light-*.png` — lys variant: kanel-spiral på lys deig.
- `spiral.png` + `final-spiral.svg` — transparent kanel-spiral (favicon / i-app-bruk).
- SVG-kildene (`final-icon-*.svg`) er med, så alt kan regenereres skarpt i alle størrelser.

---

## 3. Vurderingskriterier

Sju kriterier, vektet (summerer til 1,00). Skala 1–6. Totalscore = vektet snitt.

| Kriterium | Vekt | Hint |
|---|---|---|
| Smak | 0,20 | Helhetlig smak |
| Saftighet | 0,18 | Fuktig, ikke tørr |
| Deig / tekstur | 0,15 | Luftig, ikke brødaktig |
| Fyll / topping | 0,15 | Krem, glasur, dryss |
| Sødme / balanse | 0,12 | Ikke for søt |
| Utseende | 0,10 | Form og appell |
| Størrelse / pris | 0,10 | Verdi for pengene |

Hver oppføring har også: bakeri-navn, sted, **type bolle** (skillingsbolle, skolebolle, semle …), og et fritt notat.

---

## 4. Hvor prosjektet står

**Ferdig:**
- Fungerende forhåndsvisning av hele opplevelsen (`bollr-forhandsvisning.html`) med demodata — nærhet, kåring, kart, vurdering, innlogging, personlige lister.
- Visuell identitet, palett, ikoner, kriterier låst.

**Forhåndsvisningen bruker foreløpig:**
- Lokale demodata i minnet (ikke ekte database).
- Innlogging «på liksom».
- Kart som stilisert illustrasjon, ikke ekte kartmotor.

**Neste steg (denne PC-økten):** bytte demodata mot ekte delt backend. Se punkt 5.

---

## 5. Teknisk vei videre (på PC)

### Steg A — Legg appen på nett (bollr.no)
1. Kjøp domenet `bollr.no` (norsk registrar, f.eks. Domeneshop; privatperson med fødselsnr. kan eie .no).
2. Legg appfilene i et GitHub-repo, skru på **GitHub Pages**.
3. Sett `bollr.no` som custom domain + fire A-records mot GitHub:
   `185.199.108.153`, `185.199.109.153`, `185.199.110.153`, `185.199.111.153`
4. Slå på «Enforce HTTPS».

### Steg B — Supabase (delt database + innlogging)
1. Opprett gratis prosjekt på supabase.com.
2. Tabeller (forslag):
   - `bakeries` (id, navn, sted, type, lat, lng, opprettet)
   - `ratings` (id, bakery_id, user_id, score-felter, notat, opprettet) — **user_id lagres, men vises aldri offentlig**
   - `wishlist` (user_id, bakery_id)
   - snitt-score kan beregnes som view/aggregat over `ratings`.
3. Skru på **Auth**: Google (enkelt), Apple (fint for iPhone). Vipps krever bedriftsavtale → senere.
4. Sett **Row Level Security**: alle kan lese snitt/bakerier; en bruker kan bare skrive/endre sine egne ratings og ønskeliste; rå enkeltvurderinger med identitet er ikke offentlig lesbare (kun aggregat).

### Steg C — Koble frontend til Supabase
- Bytt de lokale `BAKERIES`/`MY_TASTED`-variablene i forhåndsvisningen mot Supabase-kall.
- Behold all UI som den er — bare datalaget endres.

### Steg D — Kart og posisjon
- Nettleserens Geolocation API for «nær meg» (krever samtykke).
- Kart: Leaflet + OpenStreetMap (gratis) eller Google Maps.
- Veibeskrivelse: lenke `https://www.google.com/maps/dir/?api=1&destination=LAT,LNG`.

---

## 6. Lansering (mot kaldstart-problemet)

En anmeldelses-app uten anmeldelser er verdiløs. Hele startjobben er å få ett område til å føles levende:

1. **Start smalt** — én region (f.eks. Grenland / Skien-Porsgrunn), ikke hele Norge.
2. **Seed selv** — du og noen venner vurderer de 20–30 kjente bakeriene før lansering, så appen aldri er tom.
3. **Finn entusiastene** — lokale mat-/hva-skjer-Facebook-grupper; én god post slår betalt annonse.
4. **Skap en kåring** — «Grenlands beste bolle 2026» er mer delbart enn «last ned appen». Vinnerbakeriet deler selv.
5. **Bakerier som allierte** — de som topper lista har interesse av at appen finnes.
6. **Din egen historie** — «mannen som kjører gjennom Norge for beste bolle» er en fortelling lokalpresse liker.
7. **Utvid** til neste region først når den første føles full.

## 7. Åpne valg / senere

- Vipps-innlogging (krever avtale).
- Engelsk språkvariant for turister.
- App Store-publisering (krever Mac + 99 USD/år) — først når brukertallet forsvarer det. PWA på bollr.no dekker behovet fram til da.
- Pakke Fraunces/Inter lokalt for offline.
