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
}

const TITLE: String = "Coup Online"
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


static func character(id: String) -> String:
	return CHARACTER_NAMES.get(id, id)


static func action(id: String) -> String:
	return ACTION_NAMES.get(id, id)


static func error(code: String) -> String:
	return ERRORS.get(code, "Erro: %s" % code)
