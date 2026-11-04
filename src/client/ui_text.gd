class_name UiText
extends RefCounted
## Every player-facing string of the client (pt-BR), kept in one place so a
## later localization pass has a single file to extract.

const CHARACTER_NAMES: Dictionary = {
	"duque": "Duque",
	"assassino": "Assassino",
	"capitao": "Capitão",
	"embaixador": "Embaixador",
	"condessa": "Condessa",
}

## Text of each card face: [label, [lines]] for the action row and the block row.
const CARD_TEXT: Dictionary = {
	"duque": {"action": ["TAXAR", ["receba 3 moedas"]], "block": ["BLOQUEIA", ["Ajuda Externa"]]},
	"assassino": {"action": ["ASSASSINAR", ["pague 3 moedas: o alvo", "perde 1 influência"]],
			"block": ["BLOQUEADO POR", ["Condessa"]]},
	"capitao": {"action": ["EXTORQUIR", ["pegue 2 moedas de outro", "jogador"]], "block": ["BLOQUEIA", ["Extorsão"]]},
	"embaixador": {"action": ["TROCAR", ["compre 2 cartas e devolva 2"]], "block": ["BLOQUEIA", ["Extorsão"]]},
	"condessa": {"action": ["AÇÃO", ["nenhuma ação própria"]], "block": ["BLOQUEIA", ["Assassinato"]]},
}

const ACTION_NAMES: Dictionary = {
	"renda": "Renda",
	"ajuda_externa": "Ajuda Externa",
	"golpe": "Golpe de Estado",
	"taxas": "Taxas",
	"assassinar": "Assassinar",
	"extorquir": "Extorquir",
	"trocar": "Trocar",
}

## Server error codes shown to the player.
const ERRORS: Dictionary = {
	"not_your_turn": "Não é a sua vez.",
	"insufficient_coins": "Moedas insuficientes.",
	"must_coup": "Com 10 ou mais moedas você precisa dar um Golpe.",
	"invalid_target": "Alvo inválido.",
	"not_eligible": "Você não pode responder agora.",
	"already_responded": "Você já respondeu.",
	"room_not_found": "Sala não encontrada.",
	"room_full": "A sala está cheia.",
	"match_started": "A partida já começou.",
	"not_host": "Só quem criou a sala pode começar.",
	"invalid_player_count": "São necessários de 2 a 6 jogadores.",
	"already_in_room": "Você já está em uma sala.",
	"invalid_name": "Digite um nome.",
	"not_in_room": "Você não está em uma sala.",
	"match_not_over": "A partida ainda não terminou.",
	"no_response_pending": "A janela de resposta já fechou.",
	"no_influence_loss_pending": "Ninguém precisa perder influência agora.",
	"no_exchange_pending": "Não há troca em andamento.",
	"not_your_loss": "Não é você quem perde a influência.",
	"not_your_exchange": "A troca não é sua.",
	"invalid_card": "Carta inválida.",
	"invalid_keep": "Escolha o número certo de cartas.",
	"invalid_block_character": "Essa carta não bloqueia esta ação.",
	"invalid_intent": "Comando inválido.",
	"match_not_started": "A partida ainda não começou.",
	"already_joined": "Você já está nesta sala.",
}

const TITLE: String = "Coup Online"
const TAGLINE: String = "Blefe, desafie e sobreviva."
const COPY_CODE: String = "Copiar código"
const CODE_COPIED: String = "Código copiado"
const HOST_TAG: String = "ANFITRIÃO"
const WINNER_CAPTION: String = "VENCEDOR"
const SERVER_LABEL: String = "Servidor"
const NAME_LABEL: String = "Seu nome"
const CODE_LABEL: String = "Código da sala"
const CREATE_ROOM: String = "Criar sala"
const JOIN_ROOM: String = "Entrar"
const START_MATCH: String = "Começar partida"
const LEAVE_ROOM: String = "Sair da sala"
const CONNECTING: String = "Conectando..."
const CONNECTION_FAILED: String = "Não foi possível conectar."
const CONNECTION_LOST: String = "Conexão perdida."
const MATCH_ABORTED: String = "A partida foi encerrada: um jogador saiu."
const ROOM_CODE: String = "Sala %s"
const WAITING_HOST: String = "Aguardando o anfitrião começar..."
const YOU_SUFFIX: String = " (você)"
const COINS: String = "%d moedas"
const EXILED: String = "Exilado"
const YOUR_CARDS: String = "Suas cartas"
const YOUR_TURN: String = "Sua vez: escolha uma ação."
const CHOOSE_ACTION: String = "Ações disponíveis:"
const YOUR_ANSWER: String = "Sua resposta é necessária."
const WAITING_FOR: String = "Aguardando %s..."
const WAITING_RESPONSES: String = "Aguardando as respostas dos outros jogadores..."
const PICK_TARGET: String = "Escolha o alvo de %s:"
const CANCEL: String = "Cancelar"
const CHALLENGE: String = "Contestar"
const PASS: String = "Deixar passar"
const BLOCK_AS: String = "Bloquear como %s"
const CLAIM_PROMPT: String = "%s declara %s para %s. Contestar?"
const BLOCK_CLAIM_PROMPT: String = "%s declara %s para bloquear. Contestar?"
const BLOCK_PROMPT: String = "%s usa %s%s. Bloquear?"
const AGAINST_YOU: String = " contra você"
const LOSE_PROMPT: String = "Você perdeu uma influência. Escolha a carta que será revelada:"
const EXCHANGE_PROMPT: String = "Embaixador: escolha %d carta(s) para ficar com você."
const CONFIRM: String = "Confirmar"
const GAME_OVER: String = "Fim de jogo: %s venceu!"
const SPECTATING: String = "Você foi exilado e acompanha a partida como espectador."
const SPECTATOR_BANNER: String = "Exilado: assistindo"
const RESULT_TITLE: String = "Resultado"
const RANK: String = "%dº"
const WINNER_SUFFIX: String = " — vencedor"
const BACK_TO_LOBBY: String = "Voltar ao lobby"


const LAST_ACTION: String = "ÚLTIMA AÇÃO"
const TREASURY: String = "Tesouro"
const DECK: String = "Baralho"
const YOUR_COINS_TITLE: String = "SUAS MOEDAS"
const COUP_HINT: String = "Golpe de Estado a partir de %d"
const LOG_TITLE: String = "REGISTRO"
const LOG_BUTTON: String = "Registro"
const NO_LOG_YET: String = "Nada aconteceu ainda."
const MENU_TITLE: String = "Menu"
const RULES_TITLE: String = "Regras"
const CLOSE: String = "Fechar"
const CONTINUE: String = "Continuar"
const ENTER_FULLSCREEN: String = "Entrar em tela cheia"
const LEAVE_MATCH: String = "Sair da partida"
const TURN_OF: String = "VEZ DE %s"
const YOUR_TURN_TITLE: String = "SUA VEZ"
const CHOOSE_ACTION_SUB: String = "Escolha uma ação"
const YOUR_ANSWER_TITLE: String = "SUA RESPOSTA"
const SPECTATOR_TITLE: String = "EXILADO"
const WAITING_SUB: String = "Aguardando..."
const MATCH_STARTED: String = "A partida começou"

## Short medallion captions for narrow screens.
const ACTION_SHORT: Dictionary = {"ajuda_externa": "Ajuda", "golpe": "Golpe"}

## Lines of the rules sheet (the character rows come from CARD_TEXT).
const RULES_LINES: Array[String] = [
	"Seja o último jogador com influência.",
	"Renda: pegue 1 moeda.",
	"Ajuda Externa: pegue 2 moedas (o Duque bloqueia).",
	"Golpe de Estado: pague 7; o alvo perde 1 influência. Com 10 moedas ou mais é obrigatório.",
	"Qualquer carta declarada pode ser contestada: quem perde a contestação perde 1 influência.",
]


static func character(id: String) -> String:
	return CHARACTER_NAMES.get(id, id)


static func action(id: String) -> String:
	return ACTION_NAMES.get(id, id)


static func error(code: String) -> String:
	return ERRORS.get(code, "Erro: %s" % code)
