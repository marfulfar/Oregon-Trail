extends TextureRect

@onready var is_open = false
@onready var side_panel = $SidePanel
@onready var detail_panel = $DetailPanel

@onready var btn1 = $Button
@onready var btn2 = $Button2
@onready var btn3 = $Button3
@onready var btn4 = $Button4
@onready var btn5 = $Button5

@onready var cursor = $Cursor
@onready var cursor_position = 1

@onready var buttons_array : Array = [btn1, btn2, btn3, btn4, btn5]
@onready var side_panel_cursor_position_x = [50,133,217,300,383]

# Called when the node enters the scene tree for the first time.
func _ready():
	side_panel.hide()
	detail_panel.hide()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _input(event):
	if event.is_action_pressed("crafting_menu"): # Here is where we change the input action to the number 1 key.
		#CLOSED
		if is_open:
			position.x = 210
			is_open = false
			side_panel.hide()
			detail_panel.hide()
			cursor_position = 1
			cursor.position.x = 50
			cursor.position.y = 207
			side_panel.texture = load("res://assets/sprites/UI/side_panel.png")
		#OPENED
		else:
			position.x = 300
			is_open = true

			
	if event.is_action_pressed("menu_down") and is_open:
				if cursor_position < 5:
					cursor_position += 1
				match cursor_position:
					2:
						cursor.position.x = 133
						side_panel.texture = load("res://assets/sprites/UI/side_panel2.png")
					3:
						cursor.position.x = 217
						side_panel.texture = load("res://assets/sprites/UI/side_panel3.png")
					4:
						cursor.position.x = 300
						side_panel.texture = load("res://assets/sprites/UI/side_panel4.png")
					5:
						cursor.position.x = 383
						side_panel.texture = load("res://assets/sprites/UI/side_panel5.png")
			
	if event.is_action_pressed("menu_up") and is_open:
				if cursor_position > 0:
					cursor_position -= 1
				match cursor_position:
					1:
						cursor.position.x = 50
						side_panel.texture = load("res://assets/sprites/UI/side_panel.png")
					2:
						cursor.position.x = 133
						side_panel.texture = load("res://assets/sprites/UI/side_panel2.png")
					3:
						cursor.position.x = 217
						side_panel.texture = load("res://assets/sprites/UI/side_panel3.png")
					4:
						cursor.position.x = 300
						side_panel.texture = load("res://assets/sprites/UI/side_panel4.png")
					5:
						cursor.position.x = 383
						side_panel.texture = load("res://assets/sprites/UI/side_panel5.png")

	if event.is_action_pressed("menu_right") and is_open:
		side_panel.show()
		detail_panel.show()
		cursor.position.y = 81
		cursor.position.x = side_panel_cursor_position_x[cursor_position+1]
		#match cursor_position:
			#1:
				#cursor.position.x = 50
				#detail_panel.show()
				#cursor.position.y = 81
			#2:
				#cursor.position.x = 133
				#cursor.position.y = 81
			#3:
				#cursor.position.x = 217
				#cursor.position.y = 81
			#4:
				#cursor.position.x = 300
				#cursor.position.y = 81
			#5:
				#cursor.position.x = 383
				#cursor.position.y = 81

	if event.is_action_pressed("menu_left") and is_open:
		side_panel.hide()
		detail_panel.hide()
		cursor_position = 1
		cursor.position = Vector2(50,207)







				
