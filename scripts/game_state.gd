extends Node

signal item_collected(item_id: String, count: int)
signal message_shown(text: String)
signal health_changed(current: float, maximum: float)
signal quest_updated(quest_id: String)
signal dialogue_started(speaker: String)
signal dialogue_ended
signal player_died
signal enemy_defeated(enemy_id: String)

const MAX_HEALTH := 100.0

var collected: Dictionary = {}
var health: float = MAX_HEALTH
var is_dead: bool = false
var enemies_killed: Dictionary = {}
var dialogue_open: bool = false

## quest_id -> { title, description, status, objectives:[{id,text,type,target,current,required,done}] }
var quests: Dictionary = {}
var active_quest_id: String = ""


func _ready() -> void:
	_register_quests()


func _register_quests() -> void:
	quests = {
		"clear_wind": {
			"title": "清风院异变",
			"description": "与守院老者交谈，查明院中异状。",
			"status": "available", # available | active | completed
			"objectives": [
				{"id": "talk_elder", "text": "与守院老者交谈", "type": "talk", "target": "elder", "current": 0, "required": 1, "done": false},
			],
		},
		"gather_relics": {
			"title": "寻回旧物",
			"description": "寻回散落院中的三件旧物。",
			"status": "locked",
			"objectives": [
				{"id": "get_scroll_left", "text": "拾取左侧亭中古卷", "type": "collect", "target": "scroll_left", "current": 0, "required": 1, "done": false},
				{"id": "get_scroll_right", "text": "拾取右侧亭中古卷", "type": "collect", "target": "scroll_right", "current": 0, "required": 1, "done": false},
				{"id": "get_jade", "text": "拾取供台玉佩", "type": "collect", "target": "jade", "current": 0, "required": 1, "done": false},
			],
		},
		"purge_bandits": {
			"title": "清剿宵小",
			"description": "击退潜入清风院的三名匪徒。",
			"status": "locked",
			"objectives": [
				{"id": "kill_bandits", "text": "击败匪徒", "type": "kill", "target": "bandit", "current": 0, "required": 3, "done": false},
			],
		},
		"return_elder": {
			"title": "复命老者",
			"description": "将结果告知守院老者。",
			"status": "locked",
			"objectives": [
				{"id": "report_elder", "text": "向守院老者复命", "type": "talk", "target": "elder_report", "current": 0, "required": 1, "done": false},
			],
		},
	}


func collect(item_id: String, display_name: String) -> void:
	if not collected.has(item_id):
		collected[item_id] = 0
	collected[item_id] += 1
	item_collected.emit(item_id, collected[item_id])
	show_message("获得：%s" % display_name)
	_progress_objective("collect", item_id, 1)


func show_message(text: String) -> void:
	message_shown.emit(text)


func get_collect_count() -> int:
	var total := 0
	for key in collected:
		total += int(collected[key])
	return total


func has_item(item_id: String) -> bool:
	return collected.get(item_id, 0) > 0


func set_health(value: float) -> void:
	health = clampf(value, 0.0, MAX_HEALTH)
	health_changed.emit(health, MAX_HEALTH)
	if health <= 0.0 and not is_dead:
		is_dead = true
		player_died.emit()
		show_message("你力竭倒地……按 R 重生")


func damage_player(amount: float) -> void:
	if is_dead or dialogue_open:
		return
	set_health(health - amount)


func heal_player(amount: float) -> void:
	if is_dead:
		return
	set_health(health + amount)


func respawn_player() -> void:
	is_dead = false
	set_health(MAX_HEALTH)
	show_message("元气恢复，重新起身")


func register_kill(enemy_id: String) -> void:
	if not enemies_killed.has(enemy_id):
		enemies_killed[enemy_id] = 0
	enemies_killed[enemy_id] += 1
	enemy_defeated.emit(enemy_id)
	_progress_objective("kill", enemy_id, 1)


func start_quest(quest_id: String) -> void:
	if not quests.has(quest_id):
		return
	var q: Dictionary = quests[quest_id]
	if q.status == "completed" or q.status == "active":
		return
	q.status = "active"
	active_quest_id = quest_id
	quest_updated.emit(quest_id)
	show_message("新任务：%s" % q.title)


func complete_quest(quest_id: String) -> void:
	if not quests.has(quest_id):
		return
	var q: Dictionary = quests[quest_id]
	q.status = "completed"
	quest_updated.emit(quest_id)
	show_message("任务完成：%s" % q.title)
	_unlock_next(quest_id)


func _unlock_next(finished_id: String) -> void:
	match finished_id:
		"clear_wind":
			quests["gather_relics"].status = "active"
			active_quest_id = "gather_relics"
			quest_updated.emit("gather_relics")
			show_message("新任务：寻回旧物")
		"gather_relics":
			quests["purge_bandits"].status = "active"
			active_quest_id = "purge_bandits"
			quest_updated.emit("purge_bandits")
			show_message("新任务：清剿宵小")
		"purge_bandits":
			quests["return_elder"].status = "active"
			active_quest_id = "return_elder"
			quest_updated.emit("return_elder")
			show_message("新任务：复命老者")
		"return_elder":
			active_quest_id = ""
			show_message("清风院暂归安宁。")


func report_talk(target: String) -> void:
	_progress_objective("talk", target, 1)


func _progress_objective(obj_type: String, target: String, amount: int) -> void:
	for qid in quests:
		var q: Dictionary = quests[qid]
		if q.status != "active":
			continue
		var changed := false
		for obj in q.objectives:
			if obj.done:
				continue
			if obj.type != obj_type:
				continue
			if str(obj.target) != target:
				continue
			obj.current = mini(int(obj.required), int(obj.current) + amount)
			if obj.current >= int(obj.required):
				obj.done = true
			changed = true
		if changed:
			quest_updated.emit(qid)
			if _all_objectives_done(q):
				complete_quest(qid)


func _all_objectives_done(q: Dictionary) -> bool:
	for obj in q.objectives:
		if not obj.done:
			return false
	return true


func get_active_quest() -> Dictionary:
	if active_quest_id != "" and quests.has(active_quest_id):
		return quests[active_quest_id]
	for qid in quests:
		if quests[qid].status == "active":
			return quests[qid]
	return {}


func get_quest_tracker_text() -> String:
	var q := get_active_quest()
	if q.is_empty():
		if quests.get("clear_wind", {}).get("status", "") == "available":
			return "【指引】\n· 与守院老者交谈"
		if quests.get("return_elder", {}).get("status", "") == "completed":
			return "【清风院】\n· 主线已完结，自由探索"
		return "当前无任务"
	var lines: PackedStringArray = []
	lines.append("【%s】" % q.title)
	for obj in q.objectives:
		var mark := "✓" if obj.done else "·"
		if obj.type == "kill" or (int(obj.required) > 1):
			lines.append("%s %s (%d/%d)" % [mark, obj.text, obj.current, obj.required])
		else:
			lines.append("%s %s" % [mark, obj.text])
	return "\n".join(lines)


func set_dialogue_open(open: bool) -> void:
	dialogue_open = open
	if open:
		dialogue_started.emit("")
	else:
		dialogue_ended.emit()
