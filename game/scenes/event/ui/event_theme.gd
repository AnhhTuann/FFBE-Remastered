class_name EventTheme
extends RefCounted

## Prompt 07.2 presentation-only theme tokens and helpers.
## No gameplay state or content definitions live here.

const BG := Color("#081321")
const BG_SECONDARY := Color("#0D1B2B")
const PANEL := Color("#13263B")
const PANEL_ELEVATED := Color("#1B3048")
const GOLD := Color("#D7B36A")
const GOLD_DIM := Color(0.843, 0.702, 0.416, 0.42)
const CYAN := Color("#55C7CF")
const CYAN_DIM := Color(0.333, 0.780, 0.812, 0.28)
const TEXT := Color("#F4F0E8")
const TEXT_MUTED := Color("#AAB8C7")
const DANGER := Color("#D98A8A")
const SUCCESS := Color("#7FD3A8")

const FONT_TINY := 11
const FONT_SMALL := 13
const FONT_BODY := 15
const FONT_TITLE := 21
const FONT_HERO := 28
const SPACING := 8
const RADIUS := 8


static func motion_enabled() -> bool:
	if OS.get_environment("FFBE_REDUCED_MOTION") == "1":
		return false
	return not bool(ProjectSettings.get_setting("ffbe_remastered/ui/reduced_motion", false))


static func tween_property(node: Node, property: String, value: Variant, duration: float = 0.14) -> Tween:
	if node == null:
		return null
	if node.get(property) == value or not motion_enabled() or not node.is_inside_tree():
		node.set(property, value)
		return null
	var tween: Tween = node.create_tween()
	tween.tween_property(node, NodePath(property), value, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	return tween


static func make_style(
	bg: Color,
	border: Color = GOLD_DIM,
	radius: int = RADIUS,
	border_width: int = 1,
	margin: int = SPACING
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = maxi(2, margin / 2)
	style.content_margin_bottom = maxi(2, margin / 2)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = maxi(0, radius / 3)
	style.shadow_offset = Vector2(0, 2)
	return style


static func build_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_BODY

	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_color_hover", "Button", TEXT)
	theme.set_color("font_color_pressed", "Button", TEXT)
	theme.set_color("font_color_disabled", "Button", TEXT_MUTED)
	theme.set_color("font_color_focus", "Button", CYAN)
	theme.set_color("font_color", "LineEdit", TEXT)

	theme.set_stylebox("normal", "Button", make_style(PANEL_ELEVATED, GOLD_DIM))
	theme.set_stylebox("hover", "Button", make_style(PANEL_ELEVATED.lightened(0.06), CYAN, RADIUS, 1, SPACING))
	theme.set_stylebox("pressed", "Button", make_style(PANEL, GOLD, RADIUS, 2, SPACING))
	theme.set_stylebox("disabled", "Button", make_style(PANEL, Color(GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b, 0.4), RADIUS, 1, SPACING))
	theme.set_stylebox("focus", "Button", make_style(Color(0, 0, 0, 0), CYAN, RADIUS, 2, SPACING))

	theme.set_stylebox("panel", "PanelContainer", make_style(PANEL, GOLD_DIM))
	theme.set_stylebox("panel", "Panel", make_style(PANEL, GOLD_DIM))
	theme.set_stylebox("panel", "ScrollContainer", make_style(Color(0, 0, 0, 0), Color(0, 0, 0, 0), 0, 0, 2))

	theme.set_stylebox("background", "ProgressBar", make_style(BG_SECONDARY, GOLD_DIM, 4, 1, 0))
	theme.set_stylebox("fill", "ProgressBar", make_style(CYAN.darkened(0.18), CYAN, 4, 1, 0))
	theme.set_stylebox("background_disabled", "ProgressBar", make_style(BG_SECONDARY, Color(GOLD_DIM.r, GOLD_DIM.g, GOLD_DIM.b, 0.4), 4, 1, 0))
	theme.set_stylebox("fill_disabled", "ProgressBar", make_style(TEXT_MUTED.darkened(0.2), TEXT_MUTED, 4, 1, 0))
	theme.set_color("font_color", "ProgressBar", TEXT)

	theme.set_constant("h_separation", "HBoxContainer", SPACING)
	theme.set_constant("v_separation", "VBoxContainer", SPACING)
	theme.set_constant("separation", "HSplitContainer", SPACING * 2)
	theme.set_constant("separation", "VSplitContainer", SPACING * 2)
	return theme


static func make_label(text: String, size: int = FONT_BODY, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


static func make_panel(filled: bool = true, elevated: bool = false) -> PanelContainer:
	var panel := PanelContainer.new()
	var bg: Color = PANEL_ELEVATED if elevated else PANEL
	if not filled:
		bg = Color(0, 0, 0, 0)
	panel.add_theme_stylebox_override("panel", make_style(bg, GOLD_DIM))
	return panel


static func accent_for_category(category: String) -> Color:
	match category:
		"collaboration":
			return GOLD
		"limited":
			return Color("#C88BD8")
		"permanent":
			return SUCCESS
		"seasonal":
			return Color("#E0A66B")
		"challenge":
			return Color("#D98A8A")
		_:
			return CYAN
