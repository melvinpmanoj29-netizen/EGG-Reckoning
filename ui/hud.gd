extends CanvasLayer

## In-game HUD displaying player vitals, interaction prompts, story alerts, and boss health.

@onready var health_bar: ProgressBar = $Margin/TopLeft/VBox/HealthBar
@onready var health_val_label: Label = $Margin/TopLeft/VBox/HealthBar/ValLabel
@onready var fuel_bar: ProgressBar = $Margin/TopLeft/VBox/FuelBar
@onready var fuel_val_label: Label = $Margin/TopLeft/VBox/FuelBar/ValLabel
@onready var prompt_panel: PanelContainer = $Center/PromptPanel
@onready var prompt_label: Label = $Center/PromptPanel/PromptLabel
@onready var alert_label: Label = $TopCenter/AlertLabel
@onready var boss_bar_container: VBoxContainer = $BossBarAnchor/BossBarContainer
@onready var boss_bar: ProgressBar = $BossBarAnchor/BossBarContainer/BossBar
@onready var boss_bar_label: Label = $BossBarAnchor/BossBarContainer/BossBar/BossValLabel
@onready var boss_name_label: Label = $BossBarAnchor/BossBarContainer/BossNameLabel

func _ready() -> void:
	add_to_group("hud")
	prompt_panel.visible = false
	alert_label.modulate.a = 0.0
	boss_bar_container.visible = false

func update_health(current: float, max_val: float) -> void:
	health_bar.max_value = max_val
	health_bar.value = current
	health_val_label.text = "HP: %d / %d" % [int(current), int(max_val)]

func update_fuel(current: float, max_val: float) -> void:
	fuel_bar.max_value = max_val
	fuel_bar.value = current
	fuel_val_label.text = "FUEL: %d%%" % int((current / max_val) * 100.0)

func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_panel.visible = true

func hide_prompt() -> void:
	prompt_panel.visible = false

func show_alert(text: String) -> void:
	alert_label.text = text
	var tween := create_tween()
	tween.tween_property(alert_label, "modulate:a", 1.0, 0.4)
	tween.tween_interval(3.0)
	tween.tween_property(alert_label, "modulate:a", 0.0, 0.8)

func show_boss_bar(boss_name: String) -> void:
	boss_name_label.text = boss_name
	boss_bar_container.visible = true

func update_boss_bar(current: float, max_val: float) -> void:
	boss_bar.max_value = max_val
	boss_bar.value = current
	boss_bar_label.text = "%d / %d" % [int(current), int(max_val)]

func hide_boss_bar() -> void:
	boss_bar_container.visible = false
