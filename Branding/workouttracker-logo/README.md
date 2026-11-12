# WorkoutTracker: logo og bruksguide

**Idé:** En W der det siste strøket er skilt fra og klatrer høyere: neste rep, neste økt.

## Filer
| Fil/mappe | Innhold |
|---|---|
| `wt-symbol-color.svg` | Hovedmerke (marineblå W og grønt strøk) for lys bakgrunn |
| `wt-symbol-on-dark.svg` | Hvit W og grønt strøk for mørk eller marineblå bakgrunn |
| `wt-symbol.svg` | Én farge (svart) |
| `wt-symbol-small.svg` | Versjon for ≤ 32 px: tykkere strøk, større mellomrom |
| `wt-horizontal-*.svg/png` | Symbol og ordmerke |
| `ios/AppIcon-{light,dark,tinted}-1024.png` | App-ikon for Xcode (Any / Dark / Tinted), uten alfa |
| `variants/` | Svart, hvit, én farge, favicon, web-ikoner |
| `presentation.html`, `presentation-slides/` | Presentasjon med mockups |
| `source-kit.py` | Generator (strøk 36, mellomrom 84, klatrestrøk 75°) |

## Farger
| | HEX | Rolle |
|---|---|---|
| Marineblå | `#0A2850` | merkevarefarge, W på lys bakgrunn, flate på app-ikonet (gradient `#0E3A72` → `#071A36`) |
| Grønn | `#32D46B` | klatrestrøket: alltid og bare det |
| Hvit | `#FFFFFF` | W på mørk bakgrunn |

## Regler
- Klatrestrøket er alltid grønt, eller i samme farge som W-en i versjonen med én farge. Det er aldri en annen farge.
- Marineblått merke brukes aldri på marineblå bakgrunn. Bruk `on-dark`.
- Frisone: strekbredden × 2 rundt symbolet. Minste størrelse: 16 px (bruk `small` til og med 32 px).
- Ikke roter, speilvend eller fest strøket til W-en, og ikke legg til manualer, skygger eller gradienter i selve merket.

## Ordmerket
Satt i SF Pro (systemfonten) og ikke konvertert til stier. I appen brukes `Text` med systemfonten. For bruk utenfor Apple-plattformer: sjekk lisensen eller bytt til en åpen font og konverter til stier.
