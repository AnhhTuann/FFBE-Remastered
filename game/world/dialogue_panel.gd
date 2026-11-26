extends PanelContainer

## Presentation-only dialogue panel. Text is supplied as localization keys by
## DialogueManager; this script resolves them through LocaleManager.

signal next_pressed()
signal choice_selected(choice_id: String)
signal close_pressed()

@onready var speaker_label: Label = $DialogueLayout/SpeakerLabel
@onready var text_label: Label = $DialogueLayout/TextLabel
@onready var choices_container: VBoxContainer = $DialogueLayout/ChoicesScroll/ChoicesContainer
@onready var next_button: Button = $DialogueLayout/ButtonRow/NextButton
@onready var close_button: Button = $DialogueLayout/ButtonRow/CloseButton

var _page: Dictionary = {}


func _ready() -> void:
	next_button.pressed.connect(func() -> void: next_pressed.emit())
	close_button.pressed.connect(func() -> void: close_pressed.emit())
	LocaleManager.locale_changed.connect(_apply_locale)


func show_page(page: Dictionary) -> void:
	_page = page.duplicate(true)
	_clear_choices()
	var awaiting_choice: bool = bool(page.get("awaiting_choice", false))
	# Choice pages have no body line; reclaim the text minimum so the buttons
	# always fit inside the panel at 1024x640, 1280x720 and 1920x1080.
	text_label.custom_minimum_size.y = 0 if awaiting_choice else 70
	if awaiting_choice:
		var buttons: Array[Button] = []
		for choice_variant: Variant in (page.get("choices", []) as Array):
			var choice: Dictionary = choice_variant
			var button := Button.new()
			button.custom_minimum_size = Vector2(0, 38)
			button.focus_mode = Control.FOCUS_ALL
			button.text = LocaleManager.t(str(choice.get("label_key", "")))
			var choice_id: String = str(choice.get("id", ""))
			button.pressed.connect(func() -> void: choice_selected.emit(choice_id))
			choices_container.add_child(button)
			buttons.append(button)
		for index: int in range(buttons.size()):
			buttons[index].focus_neighbor_top = (buttons[index - 1] if index > 0 else close_button).get_path()
			buttons[index].focus_neighbor_bottom = (
				buttons[index + 1] if index + 1 < buttons.size() else close_button
			).get_path()
	next_button.visible = not awaiting_choice
	next_button.disabled = bool(page.get("finished", false))
	_apply_locale(LocaleManager.current_locale)
	show()
	if awaiting_choice and choices_container.get_child_count() > 0:
		(choices_container.get_child(0) as Control).grab_focus()
	else:
		next_button.grab_focus()


func current_page() -> Dictionary:
	return _page.duplicate(true)


func _clear_choices() -> void:
	# Immediate removal prevents a second show_page() in the same frame from
	# relabelling stale buttons by index.
	for child: Node in choices_container.get_children():
		choices_container.remove_child(child)
		child.free()


func _apply_locale(_locale: String = "") -> void:
	speaker_label.text = LocaleManager.t(str(_page.get("speaker_key", "")))
	text_label.text = LocaleManager.t(str(_page.get("line_key", "")))
	next_button.text = LocaleManager.t("world.dialogue.next")
	close_button.text = LocaleManager.t("dialogue.choice.close")
	for index: int in range(choices_container.get_child_count()):
		var choices: Array = (page_choices() as Array)
		if index < choices.size():
			var choice: Dictionary = choices[index]
			var button: Button = choices_container.get_child(index) as Button
			button.text = LocaleManager.t(str(choice.get("label_key", "")))


func page_choices() -> Array:
	return _page.get("choices", []) if _page.has("choices") else []
