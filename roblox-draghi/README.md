# Dragon Elements Sim

Gioco Roblox: un simulator di draghi elementali con combattimento automatico, zona di allenamento,
uova, 8 isole e negozio completo. Il codice è in Luau ed è organizzato per [Rojo](https://rojo.space).

I testi del gioco sono in inglese, perché il pubblico di Roblox è internazionale: Roblox li traduce
da solo in italiano, spagnolo, portoghese e altre lingue. I commenti nel codice sono in italiano.

## Cosa c'è (fase 1)

- **8 isole** costruite dal codice: Meadow, Forest, Beach, Desert, Volcano, Glacier, Thunder Peaks,
  Cloud Isle. Ognuna ha decorazioni, mostri, un uovo e una zona di allenamento, e si sblocca con le monete.
- **Combattimento automatico**: avvicinati ai mostri e i draghi attaccano da soli. Gli elementi contano
  (l'acqua batte il fuoco, il fuoco batte il ghiaccio...).
- **Zona di allenamento**: stando dentro, anche fermi, i draghi guadagnano esperienza e salgono di livello.
- **108 draghi**: 72 dalle uova (9 per isola), 20 ibridi del nido e 16 esclusivi (negozio, premio giornaliero,
  feste, admin abuse). Uno su 50 nasce brillante.
- **9 rarità nelle uova**: Common 44%, Uncommon 28%, Rare 16%, Epic 7,5%, Legendary 3%, Mythic 1,2%,
  Divine 0,25%, Celestial 0,04% e Secret 0,01% (1 su 10.000). Divine e superiori vengono annunciati;
  i Secret in tutti i server. Più le rarità speciali Exclusive, Event e Limited.
- **Evoluzioni**: 5 draghi uguali → 1 Golden (x3), 5 Golden → 1 Rainbow (x8), 5 Rainbow → 1 Void (x20).
- **Probabilità sempre visibili** sopra ogni uovo, come chiede Roblox.
- **Rinascita**: ricominci le isole, tieni i draghi e guadagni più monete per sempre.
- **Mercato delle pozioni** su ogni isola: 4 pozioni che cambiano ogni 5 minuti (uguali in tutti i server),
  con scorte limitate e pozioni rare (Shiny, Super Luck) che escono di rado. Rifornimento immediato a 15 R$.
- **Regali a tempo**: 12 regali in un'ora di gioco (monete, cristalli, pozioni, uova gratis). Si possono
  aprire tutti subito per 49 R$.
- **Inventario pozioni**: le pozioni si usano quando vuoi; usarne un'altra uguale aggiunge tempo.
- **Nido degli incroci** su ogni isola: due draghi di elementi diversi danno uno dei 20 ibridi segreti.
  Alcuni nascono solo con un certo meteo (l'Eclipse Dragon solo durante l'eclissi). Il primo al mondo a
  scoprire un ibrido viene annunciato in tutti i server.
- **Meteo** che cambia ogni 15 minuti (sole, vento, pioggia, temporale, neve, eclissi rara), uguale in tutti
  i server: rafforza un elemento del 25% e cambia cielo, luce, pioggia, neve e lampi.
- **Codici** (`Config/Codes.lua`) e **premio giornaliero** di 7 giorni, con un drago esclusivo al 7°.
- **Eventi automatici** (`Config/Events.lua`): pioggia di meteore ogni ora, ora d'oro ogni giorno, weekend
  con monete x2, e le feste dell'anno (San Valentino, Pasqua, estate, scuola, Halloween, Black Friday,
  Natale) con moltiplicatori, mostri colorati a tema e un drago esclusivo che i mostri lasciano di rado.
- **Admin abuse ogni sabato** alle 17:00 UTC (18 italiane d'inverno, 19 d'estate): avvisi 60, 30, 10, 5 e
  1 minuto prima, poi 7 eventi da 5 minuti pescati tra 15 tipi (fortuna x10, boss giganti, pioggia di uova,
  gravità bassa, draghi giganti, mostri d'oro, eclissi forzata...), mai gli stessi della settimana prima,
  con un tema diverso ogni sabato. Il finale regala a tutti il drago admin della settimana.
- **Comandi admin in chat** (solo per te): `/event abuse` lancia un admin abuse in tutti i server,
  `/event luck10` (o un altro evento) ne lancia uno solo, `/event stop` li ferma.
- **Abilità** (`Config/Abilities.lua`): 6 poteri con pulsante e ricarica (Fire Breath gratis, poi Tidal Wave,
  Frenzy, Thunder Strike, Coin Magnet, Meteor Call), sbloccati con i cristalli. Tasti 1–6 da computer.
- **Stile** (`Config/Cosmetics.lua`): 20 aure e 20 scie visibili da tutti, con rarità. In cristalli, sbloccate
  dai traguardi (rinascite o uova aperte, fino a 10.000 uova e 50 rinascite), esclusive in Robux
  (Rainbow Aura 99 R$, Rainbow Trail 79 R$) o del VIP (Royal Aura, Golden Trail). Il VIP ha anche il tag
  sopra la testa e [VIP] dorato in chat.
- **Negozio della rinascita** (`Config/RebirthShop.lua`): gettoni a ogni rinascita per potenziamenti
  permanenti (monete, danni, allenamento, fortuna, posti in squadra).
- **Negozio delle uova**: tutte le uova con probabilità e un pulsante per andare subito al piedistallo.
- **Missioni giornaliere** (`Config/Quests.lua`): 3 al giorno pescate da 9, più un premio se le finisci tutte.
- **Effetti**: schiusa animata (l'uovo trema, lampo, bagliore della rarità), numeri dei danni, mostri che
  lampeggiano quando vengono colpiti, monete che volano verso di te, pannelli e pulsanti animati, suoni.
- **Negozio**:
  - pass a livelli: Coins, Damage, Training, Luck (x2, poi x4, poi x8), Multi Hatch, Team Slots;
  - pass singoli: VIP e Fast Walk;
  - pacchetti da 9, 25 e 99 R$ con draghi esclusivi;
  - drago limitato numerato (500 in tutto);
  - pozioni, cristalli e monete;
  - offerta del Mini Pack quando non hai abbastanza monete per un uovo.
- **Salvataggi sicuri**, con protezione contro i salvataggi doppi tra due server e contro gli acquisti
  dati due volte.

## Come provarlo in Roblox Studio

1. Installa **Roblox Studio** e il plugin **Rojo** (dal Creator Store, cerca "Rojo").
2. Installa Rojo sul computer, oppure usa l'estensione Rojo di Visual Studio Code.
3. Apri il terminale in questa cartella e lancia `rojo serve`.
4. In Studio crea un gioco nuovo partendo dal modello **Baseplate**, apri il plugin Rojo e premi **Connect**.
5. Premi **Play**.

In Studio i pass e i prodotti con `Id = 0` si "comprano" per finta: puoi provare tutto il negozio senza
spendere niente.

Per provare anche i salvataggi: **Game Settings → Security → Enable Studio Access to API Services**.

## Prima di pubblicare: creare pass e prodotti

1. Pubblica il gioco da Studio (**File → Publish to Roblox**).
2. Nel [Creator Dashboard](https://create.roblox.com/dashboard/creations), apri il gioco e vai su
   **Monetization**:
   - in **Passes** crea un pass per ogni voce di `src/shared/Config/Passes.lua`, con lo stesso prezzo;
   - in **Developer Products** crea un prodotto per ogni voce di `src/shared/Config/Products.lua`.
3. Copia il numero (ID) di ognuno al posto dello `0` corrispondente nei due file.
4. Ripubblica.

## Prima di pubblicare: impostazioni da fare a mano (Game Settings / Creator Dashboard)

Dalla lista di controllo per la pubblicazione della skill roblox-game, le voci che non si fanno dal codice:

- [ ] **Questionario sui contenuti** (età consigliata) compilato.
- [ ] **Icona 512x512** e almeno **3 miniature** (o un video).
- [ ] **Descrizione** chiara, con le parole che la gente cerca (dragon, simulator, pets...).
- [ ] **Genere**: Simulator. **Giocatori per server**: 12–16.
- [ ] **Dispositivi**: telefono, tablet, computer, console.
- [ ] **Server privati** attivi (gratis o a pochi Robux).
- [ ] **Gruppo Roblox** del gioco, per le notizie e i premi del gruppo.
- [ ] Pass e prodotti creati, con gli ID incollati in `Config/Passes.lua` e `Config/Products.lua`.
- [ ] Prova di un acquisto vero in un server pubblico (in Studio sono simulati).
- [ ] Prova con almeno 2 giocatori insieme e prova su telefono.

## Dove si cambiano le cose

| Cosa | File |
|---|---|
| Isole, mostri, costi | `src/shared/Config/Islands.lua` |
| Draghi e rarità | `src/shared/Config/Dragons.lua` |
| Difficoltà (danni, livelli, rinascita) | `src/shared/Config/Balance.lua` |
| Game pass e prezzi | `src/shared/Config/Passes.lua` |
| Pacchetti, pozioni, cristalli | `src/shared/Config/Products.lua` |
| Elementi e debolezze | `src/shared/Config/Elements.lua` |
| Codici (solo sul server, nessuno li vede prima) | `src/server/Config/Codes.lua` |
| Eventi, feste e admin abuse | `src/shared/Config/Events.lua` |

Il file del gioco per Roblox Studio si crea con `python3 tools/build_place.py` (finisce in `build/`).

## Prossime fasi

- Nido degli incroci, meteo che cambia gli incroci, muri da aprire con l'elemento giusto.
- Premio giornaliero, regali a tempo, codici, ruota.
- Eventi automatici: meteore, weekend x2, admin abuse del sabato, eventi delle feste.
- Configurazione da remoto e aggiornamenti automatici del sabato.
- Boss delle isole, abilità dei draghi, scambi, classifiche.
