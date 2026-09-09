extends RefCounted

var items := {}


func add_item(id: String, amount: int = 1) -> void:
	if id == "" or amount <= 0:
		return
	items[id] = int(items.get(id, 0)) + amount


func remove_item(id: String, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if count(id) < amount:
		return false
	var remaining := count(id) - amount
	if remaining <= 0:
		items.erase(id)
	else:
		items[id] = remaining
	return true


func count(id: String) -> int:
	return int(items.get(id, 0))


func can_pay(cost: Dictionary) -> bool:
	for id in cost.keys():
		if count(String(id)) < int(cost[id]):
			return false
	return true


func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	for id in cost.keys():
		remove_item(String(id), int(cost[id]))
	return true


func clear() -> void:
	items.clear()


func copy_items() -> Dictionary:
	return items.duplicate(true)

