extends CharacterBody2D

# --- VARIÁVEIS DE MOVIMENTO ---
@export var speed: float = 200.0
@onready var texto_inventario: Label = $CanvasLayer/TextoInventario
# --- CARREGAR OS FRAME DE CADA MUNDO ---
var frames_mundo_1 = preload("res://nootnoot/frames_mundo1.tres")
var frames_mundo_2 = preload("res://nootnoot/frames_mundo2.tres")

# --- REFERÊNCIA DA ANIMAÇÃO ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# --- SISTEMA DE MUNDOS ---
var current_world: int = 1

# --- SISTEMA DE INTERAÇÃO ---
var interactable_object = null

func _physics_process(_delta: float) -> void:
	# 1. Movimentação Topdown básica
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		
		# 2. SISTEMA DE ANIMAÇÃO BASEADO NA DIREÇÃO
		# Prioriza a direção com maior força no movimento
		if abs(direction.x) > abs(direction.y):
			# Movimento horizontal
			if direction.x > 0:
				animated_sprite.play("move_right")
			else:
				animated_sprite.play("move_left")
		else:
			# Movimento vertical
			if direction.y > 0:
				animated_sprite.play("move_down")
			else:
				animated_sprite.play("move_up")
				
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed)
		
		# 3. PARADO (IDLE)
		# Quando o jogador para, manter o frame parado olhando para a última direção,
		# ou simplesmente parar a animação atual no primeiro quadro (frame 0)
		animated_sprite.stop()
		animated_sprite.frame = 0 # Mantém o sprite de pé, sem caminhar

	move_and_slide()

func _ready() -> void:
	atualizar_ui_inventario()


func _unhandled_input(event: InputEvent) -> void:
	# 1. Detecta o comando de interagir
	if event.is_action_pressed("interact"):
		try_to_interact()
		
	# 2. Detecta o comando de trocar de mundo
	if event.is_action_pressed("switch_world"):
		toggle_world()
		
	# 3. ALTERNAR INVENTÁRIO (Aperta uma vez abre, aperta de novo fecha)
	if event.is_action_pressed("show_inventory"):
		if texto_inventario.visible:
			texto_inventario.hide() # Se já estava na tela, esconde
		else:
			atualizar_ui_inventario() # Atualiza os itens antes de mostrar
			texto_inventario.show()   # Se estava escondido, mostraasd

# --- FUNÇÕES AUXILIARES ---

# Função para tentar interagir com algo próximo
func try_to_interact() -> void:
	if interactable_object != null:
		if interactable_object.has_method("interact"):
			interactable_object.interact()
		else:
			print("O objeto tem área de interação, mas não tem a função 'interact()'")
	else:
		print("Nada para interagir por perto.")


# --- FUNÇÃO DE TRANSIÇÃO DE MUNDO ---
func toggle_world() -> void:
	if current_world == 1:
		current_world = 2
		print("Viajou para o Mundo 2!")
		
		# Troca todo o conjunto de animações para as sprites do Mundo 2
		animated_sprite.sprite_frames = frames_mundo_2
		
	else:
		current_world = 1
		print("Retornou para o Mundo 1!")
		
		# Retorna para as animações originais do Mundo 1
		animated_sprite.sprite_frames = frames_mundo_1
	change_world_visuals(Color(1.0, 1.0, 1.0)) 
	# Avisa os objetos interativos para sumirem/aparecerem
	get_tree().call_group("world_elements", "on_world_switched", current_world)

# Apenas um efeito visual simples de demonstração no jogador
func change_world_visuals(new_color: Color) -> void:
	modulate = new_color
	
func _on_interaction_zone_area_entered(area: Area2D) -> void:
	print("Encontrei alguma área! Nome: ", area.name)
	
	# Verifica diretamente se o objeto colidido é do tipo Interactable
	if area is Interactable:
		print("E ela é um objeto interativo válido!")
		interactable_object = area

func _on_interaction_zone_area_exited(area: Area2D) -> void:
	# Se a área que saiu for o nosso objeto atual, limpa a referência
	if area == interactable_object:
		interactable_object = null
		
func atualizar_ui_inventario() -> void:
	if Inventario.itens.size() == 0:
		texto_inventario.text = "Inventario: Vazio"
	else:
		var lista_formatada = ", ".join(Inventario.itens)
		texto_inventario.text = "Inventario: " + lista_formatada
