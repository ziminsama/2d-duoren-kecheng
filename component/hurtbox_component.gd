class_name HurtboxComponent
extends Area2D

signal hit_by_hitbox
#受击组件导入生命组件，有个碰撞体被区域进入触发的函数（只在服务器权威，进入的区域要是攻击组件才运行）
@export var health_component: HealthComponent


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _handle_hit(hitbox_component: HitboxComponent):
	hitbox_component.register_hurtbox_hit(self)
	health_component.damage(hitbox_component.damage)
	hit_by_hitbox.emit()


func _on_area_entered(other_area: Area2D):
	if !is_multiplayer_authority() or other_area is not HitboxComponent:
		return
	
	_handle_hit.call_deferred(other_area)
