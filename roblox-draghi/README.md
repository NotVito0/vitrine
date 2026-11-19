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
- **40 draghi** dalle uova in 5 rarità, più 4 esclusivi del negozio. Uno su 50 nasce brillante.
- **Probabilità sempre visibili** sopra ogni uovo, come chiede Roblox.
- **Rinascita**: ricominci le isole, tieni i draghi e guadagni più monete per sempre.
- **Mercato delle pozioni** su ogni isola: 4 pozioni che cambiano ogni 5 minuti (uguali in tutti i server),
  con scorte limitate e pozioni rare (Shiny, Super Luck) che escono di rado. Rifornimento immediato a 15 R$.
- **Regali a tempo**: 12 regali in un'ora di gioco (monete, cristalli, pozioni, uova gratis). Si possono
  aprire tutti subito per 49 R$.
- **Inventario pozioni**: le pozioni si usano quando vuoi; usarne un'altra uguale aggiunge tempo.
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

## Dove si cambiano le cose

| Cosa | File |
|---|---|
| Isole, mostri, costi | `src/shared/Config/Islands.lua` |
| Draghi e rarità | `src/shared/Config/Dragons.lua` |
| Difficoltà (danni, livelli, rinascita) | `src/shared/Config/Balance.lua` |
| Game pass e prezzi | `src/shared/Config/Passes.lua` |
| Pacchetti, pozioni, cristalli | `src/shared/Config/Products.lua` |
| Elementi e debolezze | `src/shared/Config/Elements.lua` |

## Prossime fasi

- Nido degli incroci, meteo che cambia gli incroci, muri da aprire con l'elemento giusto.
- Premio giornaliero, regali a tempo, codici, ruota.
- Eventi automatici: meteore, weekend x2, admin abuse del sabato, eventi delle feste.
- Configurazione da remoto e aggiornamenti automatici del sabato.
- Boss delle isole, abilità dei draghi, scambi, classifiche.
