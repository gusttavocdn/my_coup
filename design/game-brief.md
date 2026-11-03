# Game Brief: Coup Online

**One-sentence pitch:** Coup online em tempo real onde amigos blefam, contestam e eliminam uns aos outros em salas de 2 a 6 jogadores.

## Core loop
- No seu turno: escolhe uma ação (Renda, Ajuda Externa, Golpe ou ação de personagem), declarando uma carta, real ou blefe.
- Outros jogadores contestam ou bloqueiam; contestação perdida = perde influência.
- Ação resolve, ganha moedas ou elimina rival, turno passa. Repete até sobrar um.

## Player goal & fail state — what "working" looks like
- Meta: ser o último jogador com influência. Falha: perder as 2 cartas e ser exilado.
- Uma partida completa de 2–6 jogadores roda do lobby ao vencedor, com regras do manual aplicadas e servidor como autoridade.

## MVP — what must exist to be the game
- Motor de regras: ações, contestações, bloqueios, influência, golpe obrigatório com 10+ moedas (autoridade no servidor).
- Servidor de partida: salas por código, 2–6 jogadores, estado oculto por jogador (ninguém vê cartas alheias).
- Fluxo de turno: janela de contestação/bloqueio com resposta de todos, e cadeia contestação → bloqueio → contestação do bloqueio.
- Mesa de jogo: cartas, moedas, cartas reveladas, escolha de ação/alvo.
- Troca do Embaixador e reembaralho após contestação ganha.
- Fim de partida: eliminação, vencedor, tela de resultado.

## Out of scope — not building this
- Bots/IA, modo solo, hot-seat local.
- Variante Inquisidor e mais de 6 jogadores.
- Contas, ranking, matchmaking público, chat de voz.
- Reconexão avançada e persistência de partidas.
- Cosméticos e monetização.

## Build order
1. Motor de regras puro (testável sem rede): ações, contestações, bloqueios.
2. Servidor com sala + estado oculto, partida jogável por 2 jogadores.
3. Mesa de jogo e fluxo de turno no cliente.
4. 3–6 jogadores, Embaixador, fim de partida, polimento.

---
**Who it's for / what they feel:** Grupos de amigos que querem blefe e tensão social em partidas de ~10–15 min à distância.

**Art & audio direction:** Intriga renascentista italiana: cartas ilustradas, paleta quente e escura, som de moedas e cartas.

**Reference game:** Coup (La Mame Games), a mesma regra base do manual, sem a variante Inquisidor.
