class_name ShopSystem
extends RefCounted

## Prompt 05 synthetic shop system. Stock, costs and limits come from
## SYNTHETIC_FIXTURE data; no FFBE shop inventory is represented. Item outputs
## become inventory entries with local UIDs; pure resources use PlayerState.
## The fixture `refresh` field is metadata only: no refresh action, timer or
## stock reset is implemented, and no refresh cadence is inferred from it.

const EVIDENCE_LABEL := "REMASTERED_DESIGN"
const MAX_QUANTITY := 99
const MAX_RECEIPT_LENGTH := 128

var state: Node = null


func _init(p_state: Node) -> void:
	state = p_state


func _repo() -> Node:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	return tree.root.get_node_or_null("ContentRepository") if tree != null else null


func shops() -> Dictionary:
	return _repo().call("get_shops")


func shop(shop_id: String) -> Dictionary:
	return _repo().call("get_shop", shop_id)


func stock(shop_id: String) -> Array[Dictionary]:
	var def: Dictionary = shop(shop_id)
	var result: Array[Dictionary] = []
	var entries: Array = def.get("stock", []) if def.get("stock", []) is Array else []
	for entry: Variant in entries:
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result


## Receipts normalize like summon receipts: trimmed edges, bounded length and a
## stable invalid_receipt diagnostic before any cost is checked or charged.
func normalize_receipt(receipt: String) -> String:
	var trimmed: String = receipt.strip_edges()
	if trimmed.is_empty() or trimmed.length() > MAX_RECEIPT_LENGTH:
		return ""
	return trimmed


func buy(shop_id: String, stock_id: String, quantity: int, receipt: String = "") -> Dictionary:
	var normalized: String = normalize_receipt(receipt)
	if normalized.is_empty():
		return _fail("invalid_receipt", "reason.invalid_receipt", {
			"key": "", "receipt_length": receipt.length(), "max_length": MAX_RECEIPT_LENGTH
		})
	var def: Dictionary = shop(shop_id)
	if def.is_empty():
		return _fail("unknown_shop", "shop.unknown", {"key": shop_id})
	if quantity <= 0 or quantity > MAX_QUANTITY:
		return _fail("invalid_quantity", "shop.quantity", {"key": shop_id})
	var stock_entry: Dictionary = {}
	for entry: Dictionary in stock(shop_id):
		if str(entry.get("stock_id", "")) == stock_id:
			stock_entry = entry
			break
	if stock_entry.is_empty():
		return _fail("unknown_stock", "shop.stock", {"key": shop_id})
	var definition_id: String = str(stock_entry.get("definition_id", ""))
	if not _repo().call("definition_exists", definition_id):
		return _fail("invalid_definition", "shop.definition", {"key": shop_id})
	var parsed_definition: ContentId = ContentId.parse(definition_id)
	if parsed_definition != null and parsed_definition.is_valid() and \
			str(parsed_definition.region) != str(def.get("region", "")):
		return _fail("region_mismatch", "reason.region_mismatch", {"key": shop_id})
	var required_flags: Array = stock_entry.get("required_flags", []) if stock_entry.get("required_flags", []) is Array else []
	for flag_variant: Variant in required_flags:
		if not _has_flag(str(flag_variant)):
			return _fail("flag_required", "shop.flag", {"key": shop_id, "flag": str(flag_variant)})

	var claim_key: String = "shop|%s|%s|%s" % [shop_id, stock_id, normalized]
	var purchase_key: String = "%s|%s" % [shop_id, stock_id]
	var data: Dictionary = state.get("data")
	var section: Dictionary = _read_section(data, "shops")
	var claims: Dictionary = _read_section(section, "claims")
	if claims.has(claim_key):
		return _fail("already_claimed", "shop.claimed", {"key": claim_key})
	var purchases: Dictionary = _read_section(section, "purchases")
	var bought: int = maxi(int(purchases.get(purchase_key, 0)), 0)
	var limit: int = maxi(int(stock_entry.get("limit", 0)), 0)
	if limit <= 0 or bought + quantity > limit:
		return _fail("limit_reached", "shop.limit", {"key": claim_key, "limit": limit, "purchased": bought})

	var unit_cost: Dictionary = _clamped_cost(stock_entry.get("cost", {}))
	var cost: Dictionary = {}
	for key: String in unit_cost.keys():
		cost[key] = unit_cost[key] * quantity
	if cost.is_empty():
		return _fail("invalid_cost", "shop.cost", {"key": claim_key})
	if not state.call("can_pay", cost):
		return _fail("insufficient_resources", "shop.resources", {"key": claim_key})

	var snapshot: String = _snapshot()
	if not bool(state.call("pay", cost)):
		_restore(snapshot)
		return _fail("payment_failed", "shop.payment", {"key": claim_key})
	var granted: Dictionary = {}
	var uids: Array[String] = []
	var outputs: Dictionary = {definition_id: quantity}
	for output_id: String in outputs.keys():
		var grant_result: Dictionary = _grant_output(output_id, quantity, "shop_purchase")
		if not bool(grant_result.get("ok", false)):
			_restore(snapshot)
			return _fail(str(grant_result.get("reason", "grant_failed")), "shop.grant", {"key": claim_key})
		uids.append_array(grant_result.get("uids", []) as Array[String])
		granted.merge(grant_result.get("granted", {}) as Dictionary, true)

	data = state.get("data")
	section = _ensure_section(data, "shops")
	claims = _ensure_section(section, "claims")
	purchases = _ensure_section(section, "purchases")
	bought += quantity
	purchases[purchase_key] = bought
	claims[claim_key] = {
		"shop_id": shop_id,
		"stock_id": stock_id,
		"quantity": quantity,
		"receipt": normalized,
		"cost": cost,
		"evidence": EVIDENCE_LABEL
	}
	section["claims"] = claims
	section["purchases"] = purchases
	data["shops"] = section
	return _commit("shops", snapshot, "shop.buy.ok", {
		"key": claim_key,
		"granted": granted,
		"uids": uids,
		"purchased": bought,
		"limit": limit
	})


# --- item/resource grant -------------------------------------------------------

func _grant_output(definition_id: String, quantity: int, source: String) -> Dictionary:
	if not _repo().call("definition_exists", definition_id):
		return _fail("invalid_definition", "shop.definition", {})
	var section_name: String = ""
	if not _repo().call("get_equipment_definition", definition_id).is_empty():
		section_name = "equipment"
	elif not _repo().call("get_materia_definition", definition_id).is_empty():
		section_name = "materia"
	elif not _repo().call("get_vision_card_definition", definition_id).is_empty():
		section_name = "vision_cards"
	else:
		state.call("grant", {definition_id: maxi(quantity, 0)})
		return _ok("shop.resource_grant", {"granted": {definition_id: maxi(quantity, 0)}, "uids": [] as Array[String]})
	var parsed: ContentId = ContentId.parse(definition_id)
	if parsed == null or not parsed.is_valid():
		return _fail("invalid_definition", "shop.definition", {})
	var data: Dictionary = state.get("data")
	var inventory: Dictionary = _read_section(data, "inventory")
	var entries: Array = inventory.get(section_name, []) if inventory.get(section_name, []) is Array else []
	var uids: Array[String] = []
	for index: int in range(maxi(quantity, 0)):
		var uid: String = _unique_equip_uid(parsed, entries)
		entries.append({
			"uid": uid,
			"definition_id": definition_id,
			"level": 1,
			"locked": false,
			"source": source
		})
		uids.append(uid)
	inventory[section_name] = entries
	data = state.get("data")
	data["inventory"] = inventory
	return _ok("shop.item_grant", {"granted": {definition_id: maxi(quantity, 0)}, "uids": uids})


# --- helpers -------------------------------------------------------------------

func _unique_equip_uid(parsed: ContentId, entries: Array) -> String:
	var taken: Dictionary = {}
	for entry_variant: Variant in entries:
		if entry_variant is Dictionary:
			taken[str((entry_variant as Dictionary).get("uid", ""))] = true
	var serial: int = maxi(int(state.call("next_equip_serial")), 1)
	var uid: String = ""
	while true:
		uid = "owned:%s:%s:%04d@%s" % [parsed.region, parsed.native_id, serial, parsed.form]
		if not taken.has(uid):
			break
		serial += 1
	var data: Dictionary = state.get("data")
	data["next_equip_serial"] = serial + 1
	return uid


func _has_flag(flag: String) -> bool:
	var data: Dictionary = state.get("data")
	var flags_variant: Variant = data.get("flags", {})
	if flags_variant is Dictionary:
		return bool((flags_variant as Dictionary).get(flag, false))
	var profile_variant: Variant = data.get("profile", {})
	if profile_variant is Dictionary:
		var profile_flags: Variant = (profile_variant as Dictionary).get("flags", {})
		return profile_flags is Dictionary and bool((profile_flags as Dictionary).get(flag, false))
	return false


func _clamped_cost(value: Variant) -> Dictionary:
	var result: Dictionary = {}
	if not value is Dictionary:
		return result
	for key: Variant in (value as Dictionary).keys():
		result[str(key)] = maxi(int((value as Dictionary)[key]), 0)
	return result


func _read_section(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	return (value as Dictionary).duplicate(true) if value is Dictionary else {}


func _ensure_section(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key, {})
	if not value is Dictionary:
		value = {}
		data[key] = value
	return value


func _snapshot() -> String:
	return JSON.stringify(state.get("data"))


func _restore(snapshot: String) -> void:
	var parser := JSON.new()
	if parser.parse(snapshot) == OK and parser.data is Dictionary:
		state.set("data", parser.data)


func _commit(section: String, snapshot: String, message: String, extras: Dictionary) -> Dictionary:
	var error: Error = state.call("commit", section)
	if error != OK:
		_restore(snapshot)
		return _fail("save_failed", "save.error.invalid", extras)
	return _ok(message, extras)


func _ok(message: String, extras: Dictionary) -> Dictionary:
	var result: Dictionary = {"ok": true, "reason": "", "message": message, "data": {}}
	for key: Variant in extras.keys():
		var field: String = str(key)
		if field == "ok" or field == "data":
			continue
		result[field] = extras[key]
	return result


func _fail(reason: String, message: String, extras: Dictionary) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": reason, "message": message, "data": {}}
	for key: Variant in extras.keys():
		var field: String = str(key)
		if field == "ok" or field == "reason" or field == "message" or field == "data":
			continue
		result[field] = extras[key]
	return result
