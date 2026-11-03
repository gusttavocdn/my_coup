# Referência de design: "Cartas e moedas — conjunto original"

Cópia dos quadros do canvas de design (https://claude.ai/artifact/EoVp7sMqQucT3Y2CcEkYna),
salva em 2026-11-03. São páginas HTML estáticas com SVG inline: abra num navegador
(removendo a linha `<script src="./support.js">`) ou leia o código.

- Cartas: `Main` (Duque), `Assassino`, `Capitao`, `Embaixador`, `Condessa`, `Inquisidor`, `Verso`, `Moedas`
- Telas: `Desktop`, `Mobile`, `MobileAlvo`, `MobileReacao`, `MobilePerda`
- `canvas.json` guarda o tamanho de cada quadro e as notas de design.

`tools/extract_design_assets.py` extrai daqui os SVGs usados no jogo (`assets/arte/design/`).
