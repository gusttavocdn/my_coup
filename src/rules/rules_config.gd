class_name RulesConfig
extends RefCounted
## Data-driven rule values for the Coup rules core. No logic lives here.

const MIN_PLAYERS: int = 2
const MAX_PLAYERS: int = 6

const DUQUE: String = "duque"
const ASSASSINO: String = "assassino"
const CAPITAO: String = "capitao"
const EMBAIXADOR: String = "embaixador"
const CONDESSA: String = "condessa"
const CHARACTERS: Array[String] = [DUQUE, ASSASSINO, CAPITAO, EMBAIXADOR, CONDESSA]
const COPIES_PER_CHARACTER: int = 3

const INFLUENCE_PER_PLAYER: int = 2
const STARTING_COINS: int = 2
const STARTING_COINS_TWO_PLAYER: int = 1
## 24 coins + 6 gold coins worth 5 each (manual contents).
const TOTAL_COINS: int = 54
## A player starting a turn with at least this many coins may only Golpe.
const FORCED_COUP_COINS: int = 10

const RENDA: String = "renda"
const AJUDA_EXTERNA: String = "ajuda_externa"
const GOLPE: String = "golpe"
const TAXAS: String = "taxas"
const ASSASSINAR: String = "assassinar"
const EXTORQUIR: String = "extorquir"
const TROCAR: String = "trocar"

## Cards an Embaixador draws from the Court deck when exchanging.
const EXCHANGE_DRAW: int = 2

## Block rules for actions that can be blocked. "blockers" are the characters
## a player may claim to block it; "target_only" limits blocking to the target.
const BLOCKS: Dictionary = {
	AJUDA_EXTERNA: {"blockers": [DUQUE], "target_only": false},
	ASSASSINAR: {"blockers": [CONDESSA], "target_only": true},
	EXTORQUIR: {"blockers": [EMBAIXADOR, CAPITAO], "target_only": true},
}

## Per-action data. "character" is "" for general actions. "amount" is the
## coins gained (Renda, Ajuda Externa, Taxas) or the maximum stolen (Extorquir).
const ACTIONS: Dictionary = {
	RENDA: {"cost": 0, "targeted": false, "character": "", "amount": 1},
	AJUDA_EXTERNA: {"cost": 0, "targeted": false, "character": "", "amount": 2},
	GOLPE: {"cost": 7, "targeted": true, "character": "", "amount": 0},
	TAXAS: {"cost": 0, "targeted": false, "character": DUQUE, "amount": 3},
	ASSASSINAR: {"cost": 3, "targeted": true, "character": ASSASSINO, "amount": 0},
	EXTORQUIR: {"cost": 0, "targeted": true, "character": CAPITAO, "amount": 2},
	TROCAR: {"cost": 0, "targeted": false, "character": EMBAIXADOR, "amount": 0},
}
