extends RefCounted

const SLOT_COUNT := 36
const STACK_LIMIT := 64

var slots: Array = []


func _init() -> void:
	clear()


func clear() -> void:
	slots.clear()
	for i in range(SLOT_COUNT):
		slots.append(_empty_slot())


func add_item(item_id: String, amount: int = 1) -> int:
	if item_id == "" or amount <= 0:
		return amount
	var remaining: int = amount
	remaining = _fill_existing_stacks(slots, item_id, remaining)
	if remaining <= 0:
		return 0
	return _fill_empty_slots(slots, item_id, remaining)


func remove_item(item_id: String, amount: int = 1) -> bool:
	if item_id == "" or amount <= 0:
		return false
	if count(item_id) < amount:
		return false
	remove_up_to(item_id, amount)
	return true


func remove_up_to(item_id: String, amount: int) -> int:
	if item_id == "" or amount <= 0:
		return 0
	var remaining: int = amount
	var removed: int = 0
	for i in range(slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = slots[i]
		if String(slot.get("id", "")) != item_id:
			continue
		var slot_amount: int = int(slot.get("amount", 0))
		var taken: int = remaining if remaining < slot_amount else slot_amount
		slot_amount -= taken
		remaining -= taken
		removed += taken
		if slot_amount <= 0:
			slots[i] = _empty_slot()
		else:
			slot["amount"] = slot_amount
			slots[i] = slot
	return removed


func remove_one_stack(item_id: String) -> int:
	if item_id == "":
		return 0
	for i in range(slots.size()):
		var slot: Dictionary = slots[i]
		if String(slot.get("id", "")) != item_id:
			continue
		var removed: int = int(slot.get("amount", 0))
		slots[i] = _empty_slot()
		return removed
	return 0


func remove_from_slot(slot_index: int, item_id: String, amount: int) -> int:
	if slot_index < 0 or slot_index >= slots.size() or item_id == "" or amount <= 0:
		return 0
	var slot: Dictionary = slots[slot_index]
	if String(slot.get("id", "")) != item_id:
		return 0
	var slot_amount: int = int(slot.get("amount", 0))
	var removed: int = amount if amount < slot_amount else slot_amount
	slot_amount -= removed
	if slot_amount <= 0:
		slots[slot_index] = _empty_slot()
	else:
		slot["amount"] = slot_amount
		slots[slot_index] = slot
	return removed


func remove_stack_from_slot(slot_index: int, item_id: String) -> int:
	if slot_index < 0 or slot_index >= slots.size() or item_id == "":
		return 0
	var slot: Dictionary = slots[slot_index]
	if String(slot.get("id", "")) != item_id:
		return 0
	var removed: int = int(slot.get("amount", 0))
	slots[slot_index] = _empty_slot()
	return removed


func count(item_id: String) -> int:
	var total := 0
	for slot_value in slots:
		var slot: Dictionary = slot_value
		if String(slot.get("id", "")) == item_id:
			total += int(slot.get("amount", 0))
	return total


func can_pay(cost: Dictionary) -> bool:
	for item_id in cost.keys():
		if count(String(item_id)) < int(cost[item_id]):
			return false
	return true


func pay(cost: Dictionary) -> bool:
	if not can_pay(cost):
		return false
	for item_id in cost.keys():
		remove_item(String(item_id), int(cost[item_id]))
	return true


func can_receive(items: Dictionary) -> bool:
	var simulated_slots: Array = _copy_slots(slots)
	for item_id in items.keys():
		var remaining: int = int(items[item_id])
		remaining = _fill_existing_stacks(simulated_slots, String(item_id), remaining)
		remaining = _fill_empty_slots(simulated_slots, String(item_id), remaining)
		if remaining > 0:
			return false
	return true


func copy_items() -> Dictionary:
	var result := {}
	for slot_value in slots:
		var slot: Dictionary = slot_value
		var item_id: String = String(slot.get("id", ""))
		var amount: int = int(slot.get("amount", 0))
		if item_id == "" or amount <= 0:
			continue
		result[item_id] = int(result.get(item_id, 0)) + amount
	return result


func get_slots() -> Array:
	return _copy_slots(slots)


func get_filled_stacks() -> Array:
	var result: Array = []
	for slot_value in slots:
		var slot: Dictionary = slot_value
		var item_id: String = String(slot.get("id", ""))
		var amount: int = int(slot.get("amount", 0))
		if item_id != "" and amount > 0:
			result.append({"id": item_id, "amount": amount})
	return result


func stack_limit() -> int:
	return STACK_LIMIT


func slot_count() -> int:
	return SLOT_COUNT


func _fill_existing_stacks(target_slots: Array, item_id: String, amount: int) -> int:
	var remaining: int = amount
	for i in range(target_slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = target_slots[i]
		if String(slot.get("id", "")) != item_id:
			continue
		var slot_amount: int = int(slot.get("amount", 0))
		if slot_amount >= STACK_LIMIT:
			continue
		var free_space: int = STACK_LIMIT - slot_amount
		var moved: int = remaining if remaining < free_space else free_space
		slot["amount"] = slot_amount + moved
		target_slots[i] = slot
		remaining -= moved
	return remaining


func _fill_empty_slots(target_slots: Array, item_id: String, amount: int) -> int:
	var remaining: int = amount
	for i in range(target_slots.size()):
		if remaining <= 0:
			break
		var slot: Dictionary = target_slots[i]
		if String(slot.get("id", "")) != "":
			continue
		var moved: int = remaining if remaining < STACK_LIMIT else STACK_LIMIT
		target_slots[i] = {"id": item_id, "amount": moved}
		remaining -= moved
	return remaining


func _copy_slots(source_slots: Array) -> Array:
	var result: Array = []
	for slot_value in source_slots:
		var slot: Dictionary = slot_value
		result.append({
			"id": String(slot.get("id", "")),
			"amount": int(slot.get("amount", 0))
		})
	return result


func _empty_slot() -> Dictionary:
	return {"id": "", "amount": 0}
