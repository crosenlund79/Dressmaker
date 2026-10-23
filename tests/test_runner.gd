extends Node
## Minimal test runner. Run headless:
##   godot --headless --path . tests/test_runner.tscn
## Every method named test_* in the suites below is executed; the process exits
## with code 1 if any assertion fails.

const SUITES := [
	"res://tests/test_deformer.gd",
	"res://tests/test_body.gd",
	"res://tests/test_content.gd",
	"res://tests/test_garment_shape.gd",
	"res://tests/test_body_fit.gd",
	"res://tests/test_persistence.gd",
	"res://tests/test_editor.gd",
	"res://tests/test_integration.gd",
]

var total := 0
var failed := 0


func _ready() -> void:
	for path in SUITES:
		var suite: TestCase = load(path).new()
		suite.runner = self
		add_child(suite)
		for m in suite.get_method_list():
			var mname: String = m["name"]
			if not mname.begins_with("test_"):
				continue
			total += 1
			suite.current_failures = 0
			suite.finished = false
			await suite.call(mname)
			if not suite.finished:
				suite.fail("test aborted before completion (script error?)")
			if suite.current_failures > 0:
				failed += 1
				print("  FAIL  %s :: %s" % [path.get_file(), mname])
			else:
				print("  ok    %s :: %s" % [path.get_file(), mname])
		suite.queue_free()
	print("\n%d tests, %d failed" % [total, failed])
	get_tree().quit(1 if failed > 0 else 0)
