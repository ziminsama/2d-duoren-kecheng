class_name HitboxComponent
extends Area2D

signal hit_hurtbox(hurtbox_component: HurtboxComponent)

var damage: int = 1


func register_hurtbox_hit(hurbox_component: HurtboxComponent):
	hit_hurtbox.emit(hurbox_component)
