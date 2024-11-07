# game_types.gd
extends Node

class TeaItem:
	var name: String
	var cost: float
	var price: float
	var quality: int
	var unlocked: bool
	var satisfaction: int
	
	func _init(n: String, c: float, p: float, q: int, u: bool, s: int):
		name = n
		cost = c
		price = p
		quality = q
		unlocked = u
		satisfaction = s

class StaffMember:
	var name: String
	var type: String
	var shift: String
	var efficiency: int
	var salary: float
	
	func _init(n: String, t: String, s: String, e: int, sal: float):
		name = n
		type = t
		shift = s
		efficiency = e
		salary = sal
