# Hospedagem do Coup Online: proposta

Status: **opção A escolhida em 2026-11-04** (VPS em São Paulo com Docker + Caddy; veja
"Como publicar na opção A" no fim). A conta, a VM, o domínio e o primeiro deploy ainda
não foram feitos. Nada foi criado, pago ou publicado. Preços e limites abaixo vieram de buscas na web em 2026-11-04
e são **estimativas a confirmar na página do provedor antes de contratar**.

## O que precisa ser hospedado

| Peça | Tamanho / comportamento |
|---|---|
| Cliente web (`build/web`) | 44 MB: `index.wasm` 39,5 MB (≈10 MB com gzip), `index.pck` 5,7 MB (≈5,4 MB com gzip). Arquivos estáticos. |
| Servidor de partidas | Container headless do Godot (`Dockerfile`, história 016). WebSocket na porta 9080, sem estado em disco, poucos MB de RAM por sala. |
| TLS | O navegador exige `https://` para instalar o PWA e `wss://` para a partida. O servidor fala `ws://`; o proxy termina o TLS (`deploy/Caddyfile`). |

O primeiro acesso baixa ≈15 MB comprimidos; depois o service worker deixa tudo em
cache. Coup é por turnos: latência de dezenas de ms não atrapalha, então a região
importa pouco para jogar entre amigos no Brasil.

## Opções

### A. Um VPS pequeno em São Paulo com Docker + Caddy (tudo em um lugar)

- **Como funciona:** uma VM roda o container do servidor e o Caddy. O Caddy serve o
  cliente (com compressão) e repassa o `wss://` para o servidor, tudo em um único
  endereço `https://`.
- **Custo:** cerca de **US$ 5–6/mês** (plano de 1 vCPU, 1 GB RAM, por exemplo Vultr
  São Paulo; preço de lista de um comparador, não confirmado para São Paulo). Mais um
  nome de domínio (cerca de R$ 40/ano) ou um nome gratuito baseado no IP (tipo
  `sslip.io`), porque o certificado automático precisa de um nome, não de um IP.
- **Esforço:** médio. Criar a VM, instalar Docker, abrir 80/443, subir os dois
  containers; atualizar = um script de publicação via SSH. Segurança do sistema
  operacional (atualizações) é por sua conta.
- **WebSocket e TLS:** sim, ambos pelo Caddy, certificado automático (Let's Encrypt).
- **Latência a partir do Brasil:** baixa (região São Paulo).
- **Limites que importam:** 1 GB de RAM sobra; transferência mensal (≈2 TB em planos
  assim) sobra; o limite por IP do servidor enxerga o IP do Caddy, não o do jogador
  (ver `docs/running-the-server.md`).
- **Ponto forte:** mesma origem para página e `wss://`, sem CORS, e o arquivo de
  39,5 MB sai comprimido. O cliente já deriva o endereço do servidor a partir da
  página (`server_address.gd`), faltando só usar `wss://host` sem porta atrás do proxy.

### B. Fly.io para o servidor + hospedagem estática gratuita para o cliente

- **Como funciona:** `flyctl deploy` usa o `Dockerfile` da história 016 e publica o
  servidor na região de São Paulo (`gru`), com `wss://` e certificado gerenciados pela
  Fly em `<app>.fly.dev`. O cliente vai para um serviço estático (por exemplo GitHub
  Pages) e aponta para esse endereço.
- **Custo:** máquina `shared-cpu-1x` de 256 MB cerca de **US$ 2/mês** de lista (as
  fontes divergem: 1,94 a 2,19; o multiplicador da região `gru` não foi confirmado).
  Como o servidor Godot provavelmente precisa de **512 MB**, conte **US$ 4–6/mês**.
  A hospedagem estática do cliente é gratuita, com ressalvas abaixo.
- **Esforço:** baixo para o servidor (sem administrar sistema operacional), médio no
  total por serem dois lugares com dois endereços (o endereço do servidor precisa
  entrar no build do cliente).
- **WebSocket e TLS:** sim, TLS automático.
- **Latência a partir do Brasil:** baixa (`gru`).
- **Limites que importam:**
  - Cloudflare Pages **não serve**, em princípio: o limite por arquivo costuma ser
    25 MiB e `index.wasm` tem 37,7 MiB (a busca não confirmou o número; confira em
    `developers.cloudflare.com/pages/platform/limits`).
  - GitHub Pages aceita arquivos de até 100 MB, mas só funciona de graça com
    repositório público e não deixa configurar cabeçalhos; não confirmado aqui.
  - A Fly não tem plano gratuito para contas novas (cobrança por uso).

### C. Oracle Cloud "Always Free" (VM gratuita), mesma receita da opção A

- **Como funciona:** igual à opção A, em uma VM gratuita da Oracle.
- **Custo:** **R$ 0 / US$ 0 no papel**; cobrança só se você sair do plano gratuito.
- **Esforço:** o mesmo da A, mais a criação da conta (exige cartão) e a disputa por
  capacidade: relatos frequentes de "Out of capacity" ao criar a VM.
- **WebSocket e TLS:** sim, pelo Caddy.
- **Latência a partir do Brasil:** não confirmei que o plano gratuito exista na
  região de São Paulo; se só houver região fora do Brasil, a latência sobe (ainda
  aceitável para um jogo por turnos).
- **Limites que importam:** contas e instâncias ociosas podem ser recuperadas pela
  Oracle; sem garantia de disponibilidade.

## Comparação resumida

| | A. VPS São Paulo | B. Fly.io + estático | C. Oracle grátis |
|---|---|---|---|
| Custo mensal (estimado) | US$ 5–6 (+ domínio ≈ R$ 40/ano) | US$ 4–6 (cliente grátis, com ressalvas) | US$ 0 no papel |
| Esforço de montagem | médio | baixo no servidor, dois destinos | médio–alto (capacidade, conta) |
| `wss://` + TLS automático | sim (Caddy) | sim (Fly) | sim (Caddy) |
| Latência do Brasil | baixa | baixa (`gru`) | a confirmar |
| Risco principal | você administra a VM | cliente de 39,5 MB limita o hospedeiro estático | disponibilidade e recuperação de instância |

## Recomendação

**Opção A** (um VPS pequeno em São Paulo com Docker + Caddy): uma máquina, um endereço
`https://`, o cliente sai comprimido, o `Dockerfile` e o `deploy/Caddyfile` do repositório
já são a receita, e o script de publicação (build, envio por SSH, reinício) fica simples
e repetível. Se você prefere não administrar uma VM, a opção B é a segunda escolha, com
o cuidado do hospedeiro estático para o `index.wasm`. A opção C só vale se aceitar o risco
de disponibilidade em troca de custo zero.

## Como publicar na opção A

Peças do repositório: `tools/publish.sh` (build + envio + reinício + smoke check),
`tools/smoke-check.sh` (verificação pós-publicação), `deploy/docker-compose.yml`,
`deploy/Caddyfile`, `Dockerfile`. O endereço do servidor não precisa de variável de
build: sob `https://` o cliente usa `wss://` no mesmo endereço da página
(`src/client/server_address.gd`); `?server=wss://...` na URL sobrescreve.

**Uma vez (por você):**

1. Criar a VM (Ubuntu/Debian recente, 1 vCPU, 1 GB RAM, região São Paulo) e um usuário
   com chave SSH e permissão de usar o Docker.
2. Instalar Docker com o plugin compose; abrir as portas 80 e 443 (TCP) e 443 (UDP).
3. Apontar o nome (domínio ou nome gratuito baseado no IP) para o IP da VM **antes** do
   primeiro deploy, senão o Caddy não consegue emitir o certificado.

**A cada publicação** (na sua máquina, no Git Bash, com o Docker aberto e o Godot 4.7.2):

```bash
export COUP_DEPLOY_HOST=usuario@IP_DA_VM
export COUP_DOMAIN=jogo.seudominio.com
bash tools/publish.sh --dry-run   # mostra os passos sem executar nada
bash tools/publish.sh             # publica de verdade
```

O script pode rodar duas vezes seguidas: a release do cliente é nomeada pelo conteúdo do
build (não reenvia o que já está lá, a troca do `current` é atômica e as 3 últimas
releases ficam para voltar atrás), a imagem do servidor só é enviada se mudou, e
`docker compose up -d` não mexe no que não mudou. No fim roda `tools/smoke-check.sh`
(abre a página e os arquivos do PWA, depois um cliente cria uma sala e outro entra) e
termina com `PUBLISHED` ou `PUBLISH FAILED`. O smoke check também roda sozinho:
`bash tools/smoke-check.sh https://jogo.seudominio.com`.

**Voltar atrás:** na VM, `cd /opt/coup/site && ln -sfn releases/<release-anterior> current`
(as releases ficam em `releases/`, a mais recente primeiro por data).

**Verificação de funcionamento (primeira medição em 2026-11-04, na sua máquina, `localhost`):**
a pilha compose (Caddy + servidor) subiu; `index.wasm` de 39,5 MB trafega com 10,6 MB e o
`index.pck` com 5,6 MB (gzip); o upgrade para WebSocket passa pelo Caddy (HTTP 101);
HTTP redireciona para HTTPS; o campo "Servidor" abre com `wss://localhost`. Não foi
testado numa VM real nem com certificado público.

## O que depende de você (nada disso foi feito)

1. Escolher a opção (A, B ou C).
2. Criar a conta no provedor e informar o cartão (cobrança é sua).
3. Definir o endereço (domínio ou nome gratuito) e apontá-lo para o servidor.
4. Aprovar o primeiro deploy; depois disso, o script de publicação roda sozinho.

## Custos e segredos

- Estimativa mensal: opção A **US$ 5–6**, opção B **US$ 4–6**, opção C **US$ 0** (valores
  de lista, a confirmar). Escolhida a opção, este número passa a ser o orçamento oficial.
- Nenhum token, senha ou chave vai para o repositório: chaves SSH, tokens do provedor e
  senhas ficam em variáveis de ambiente ou no gerenciador de segredos do provedor.

## Fontes consultadas (2026-11-04)

- [Fly.io Resource Pricing](https://fly.io/docs/about/pricing/)
- [Fly.io Pricing 2026 (comparativo)](https://www.buildmvpfast.com/blog/fly-io-pricing-2026-ram-increase-vs-hetzner)
- [Cloudflare Pages: aumento do limite de arquivos](https://developers.cloudflare.com/changelog/post/2026-01-23-pages-file-limit-increase/)
- [Oracle Cloud vs Vultr (comparador)](https://getdeploying.com/oracle-cloud-vs-vultr)
- [Melhores VPS em São Paulo 2026](https://valebyte.com/en/blog/best-vps-in-sao-paulo-2026-review-and-prices/)
