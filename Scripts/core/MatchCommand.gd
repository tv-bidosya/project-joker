class_name MatchCommand

extends RefCounted


# Нейтральный формат действия игрока. Пока он не подключён к сети:
# следующий этап будет использовать его и для локальной, и для Steam-партии.
enum Type {
	INVALID,
	BID,
	PLAY_CARD,
	JOKER_CONDITION,
	NEXT_ROUND_READY,
	UNDO_REQUEST,
	UNDO_VOTE,
	SOCIAL_ACTION,
	CHAT_MESSAGE,
	RESYNC_REQUEST
}


var type: Type = Type.INVALID
var player_index := -1
var round_number := 0
var revision := 0
var payload: Dictionary = {}


func _init(
	command_type: Type = Type.INVALID,
	actor_index := -1,
	current_round_number := 0,
	state_revision := 0,
	command_payload: Dictionary = {}
) -> void:
	type = command_type
	player_index = actor_index
	round_number = current_round_number
	revision = state_revision
	payload = command_payload.duplicate(true)


func is_valid() -> bool:
	return (
		type != Type.INVALID
		and player_index >= 0
		and round_number >= 0
		and revision >= 0
	)


func to_dictionary() -> Dictionary:
	return {
		"type": int(type),
		"player_index": player_index,
		"round_number": round_number,
		"revision": revision,
		"payload": payload.duplicate(true)
	}


static func from_dictionary(data: Dictionary) -> MatchCommand:
	var command_payload: Dictionary = data.get("payload", {})
	return MatchCommand.new(
		int(data.get("type", Type.INVALID)),
		int(data.get("player_index", -1)),
		int(data.get("round_number", 0)),
		int(data.get("revision", 0)),
		command_payload
	)
