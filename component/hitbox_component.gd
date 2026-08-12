class_name HitboxComponent
extends Area2D
#攻击组件有个攻击受击组件的信号，有个伤害属性
signal hit_hurtbox(hurtbox_component: HurtboxComponent)

var damage: int = 1
var source_peer_id: int


func register_hurtbox_hit(hurbox_component: HurtboxComponent):
	hit_hurtbox.emit(hurbox_component)
