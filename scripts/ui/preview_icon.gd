class_name PreviewIcon
extends Control
## A Control that draws a thumbnail through a callback: draw_fn(canvas_item, rect).

var draw_fn: Callable


func _init(fn: Callable = Callable(), min_size: Vector2 = Vector2(96, 96)) -> void:
	draw_fn = fn
	custom_minimum_size = min_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	if draw_fn.is_valid():
		draw_fn.call(self, Rect2(Vector2.ZERO, size))
