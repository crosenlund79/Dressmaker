class_name TestCase
extends Node
## Base class for test suites: small assertion helpers.

var runner: Node
var current_failures := 0
var finished := false


## Every test ends with done(); a test that never reaches it (e.g. aborted by a
## script error) is reported as failed.
func done() -> void:
	finished = true


func fail(msg: String) -> void:
	current_failures += 1
	printerr("        assertion failed: ", msg)


func check(cond: bool, msg: String) -> void:
	if not cond:
		fail(msg)


func check_eq(a: Variant, b: Variant, msg: String) -> void:
	if a != b:
		fail("%s (got %s, expected %s)" % [msg, str(a), str(b)])


func check_near(a: float, b: float, tol: float, msg: String) -> void:
	if absf(a - b) > tol:
		fail("%s (got %f, expected %f ± %f)" % [msg, a, b, tol])


func check_vec_near(a: Vector2, b: Vector2, tol: float, msg: String) -> void:
	if a.distance_to(b) > tol:
		fail("%s (got %s, expected %s ± %f)" % [msg, str(a), str(b), tol])
