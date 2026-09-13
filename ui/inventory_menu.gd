extends CanvasLayer

## Simple Inventory & Gear Menu for EGG: RECKONING.
## Displays burner status, fuel, torch, consumables (Medkits/Fuel Canisters), and key story documents.

signal item_used(item_type: String)

@onready var panel_container: PanelContainer = $Center/PanelContainer
@onready var close_btn: Button = $Center/PanelContainer/Margin/VBox/BottomBar/CloseBtn

# Equipment nodes
@onready var burner_status_label: Label = $Center/PanelContainer/Margin/VBox/ContentHBox/EquipVBox/BurnerCard/Margin/HBox/VBox/StatusLabel
@onready var burner_fuel_bar: ProgressBar = $Center/PanelContainer/Margin/VBox/ContentHBox/EquipVBox/BurnerCard/Margin/HBox/VBox/FuelBar
@onready var burner_fuel_label: Label = $Center/PanelContainer/Margin/VBox/ContentHBox/EquipVBox/BurnerCard/Margin/HBox/VBox/FuelBar/FuelLabel

@onready var torch_status_label: Label = $Center/PanelContainer/Margin/VBox/ContentHBox/EquipVBox/TorchCard/Margin/HBox/VBox/StatusLabel
@onready var torch_toggle_btn: Button = $Center/PanelContainer/Margin/VBox/ContentHBox/EquipVBox/TorchCard/Margin/HBox/TorchToggleBtn

# Consumables
@onready var medkit_count_label: Label = $Center/PanelContainer/Margin/VBox/ContentHBox/SuppliesVBox/MedkitCard/Margin/HBox/CountLabel
@onready var medkit_use_btn: Button = $Center/PanelContainer/Margin/VBox/ContentHBox/SuppliesVBox/MedkitCard/Margin/HBox/UseMedkitBtn

@onready var fuel_count_label: Label = $Center/PanelContainer/Margin/VBox/ContentHBox/SuppliesVBox/FuelCanCard/Margin/HBox/CountLabel
@onready var fuel_refuel_btn: Button = $Center/PanelContainer/Margin/VBox/ContentHBox/SuppliesVBox/FuelCanCard/Margin/HBox/RefuelBtn

# Key Documents Container
@onready var docs_container: VBoxContainer = $Center/PanelContainer/Margin/VBox/ContentHBox/SuppliesVBox/DocsCard/Margin/VBox/DocsList

var is_open: bool = false

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_inventory)
	torch_toggle_btn.pressed.connect(_on_toggle_torch)
	medkit_use_btn.pressed.connect(_on_use_medkit)
	fuel_refuel_btn.pressed.connect(_on_use_fuel)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and (event.keycode == KEY_TAB or event.keycode == KEY_I or event.keycode == KEY_ESCAPE)):
		if is_open:
			get_viewport().set_input_as_handled()
			close_inventory()
		elif event.keycode == KEY_TAB or event.keycode == KEY_I:
			get_viewport().set_input_as_handled()
			open_inventory()

func open_inventory() -> void:
	is_open = true
	refresh_inventory()
	visible = true
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_clue_open"):
		sm.play_clue_open()

func close_inventory() -> void:
	is_open = false
	visible = false
	var sm := get_node_or_null("/root/SoundManager")
	if sm and sm.has_method("play_clue_open"):
		sm.play_clue_open()

func toggle_inventory() -> void:
	if is_open:
		close_inventory()
	else:
		open_inventory()

func refresh_inventory() -> void:
	var gs := get_node_or_null("/root/GameState")
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	
	var has_burner: bool = gs.has_burner if (gs and "has_burner" in gs) else false
	var has_torch: bool = gs.has_torch if (gs and "has_torch" in gs) else false
	var torch_on: bool = gs.torch_enabled if (gs and "torch_enabled" in gs) else true
	var medkits: int = gs.medkits if (gs and "medkits" in gs) else 0
	var fuel_cans: int = gs.fuel_canisters if (gs and "fuel_canisters" in gs) else 0
	
	# Update Burner
	if has_burner:
		burner_status_label.text = "[ READY ] - Incendiary Burner"
		burner_status_label.modulate = Color(1.0, 0.7, 0.2, 1.0)
		var current_fuel: float = player.fuel if player else 100.0
		var max_fuel: float = player.max_fuel if player else 100.0
		burner_fuel_bar.value = current_fuel
		burner_fuel_bar.max_value = max_fuel
		burner_fuel_label.text = "Tank: %d%%" % int((current_fuel / max_fuel) * 100.0)
		burner_fuel_bar.visible = true
	else:
		burner_status_label.text = "[ NOT ACQUIRED ]"
		burner_status_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		burner_fuel_bar.visible = false
		
	# Update Torch
	if has_torch:
		torch_status_label.text = "[ ACQUIRED ] - Tactical Torch"
		torch_status_label.modulate = Color(0.4, 0.9, 0.5, 1.0)
		torch_toggle_btn.disabled = false
		torch_toggle_btn.text = "Toggle [F] (ON)" if torch_on else "Toggle [F] (OFF)"
	else:
		torch_status_label.text = "[ NOT ACQUIRED ]"
		torch_status_label.modulate = Color(0.6, 0.6, 0.6, 1.0)
		torch_toggle_btn.disabled = true
		torch_toggle_btn.text = "Locked"
		
	# Update Consumables
	medkit_count_label.text = "Carrying: %d" % medkits
	medkit_use_btn.disabled = medkits <= 0 or (player != null and player.health >= player.max_health)
	
	fuel_count_label.text = "Carrying: %d" % fuel_cans
	fuel_refuel_btn.disabled = fuel_cans <= 0 or not has_burner or (player != null and player.fuel >= player.max_fuel)
	
	# Populate Documents List
	_populate_docs()

func _populate_docs() -> void:
	for c in docs_container.get_children():
		c.queue_free()
		
	var gs := get_node_or_null("/root/GameState")
	var key_items: Array = gs.key_items if (gs and "key_items" in gs) else []
	
	if key_items.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No documents collected yet."
		empty_lbl.modulate = Color(0.6, 0.6, 0.6, 0.8)
		docs_container.add_child(empty_lbl)
		return
		
	for doc_title in key_items:
		var btn := Button.new()
		btn.text = "📄 " + doc_title
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_doc_clicked.bind(doc_title))
		docs_container.add_child(btn)

func _on_toggle_torch() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("toggle_torch"):
		player.toggle_torch()
	refresh_inventory()

func _on_use_medkit() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var gs := get_node_or_null("/root/GameState")
	if player and gs and gs.medkits > 0:
		if player.heal(35.0):
			gs.medkits -= 1
			var sm := get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play_pickup"):
				sm.play_pickup()
			refresh_inventory()

func _on_use_fuel() -> void:
	var player := get_tree().get_first_node_in_group("player")
	var gs := get_node_or_null("/root/GameState")
	if player and gs and gs.fuel_canisters > 0:
		if player.add_fuel(45.0):
			gs.fuel_canisters -= 1
			var sm := get_node_or_null("/root/SoundManager")
			if sm and sm.has_method("play_pickup"):
				sm.play_pickup()
			refresh_inventory()

func _on_doc_clicked(doc_title: String) -> void:
	var modal := get_tree().get_first_node_in_group("investigation_modal")
	if not modal:
		modal = get_parent().get_node_or_null("InvestigationModal")
	if modal and modal.has_method("open_key_document"):
		close_inventory()
		modal.open_key_document(doc_title)
