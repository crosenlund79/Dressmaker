class_name BodyDefinition
extends Resource
## Data-driven body type. All measurements are in model-space pixels.
## Model space: origin at the floor between the feet, +x to screen right, -y up.
##
## Garments are authored in normalized frames that are mapped through the
## body (see bodice_to_model / skirt_to_model / arm_to_model), so the same
## garment adapts automatically to every body type.

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export_group("Head")
@export var head_radius: float = 36.0
@export var head_center_y: float = -560.0
@export var neck_hw: float = 15.0

@export_group("Torso")
@export var shoulder_y: float = -490.0
@export var shoulder_hw: float = 70.0
@export var chest_hw: float = 56.0
@export var bust_hw: float = 60.0
@export var waist_y: float = -370.0
@export var waist_hw: float = 40.0
@export var hip_y: float = -305.0
@export var hip_hw: float = 64.0

@export_group("Legs")
@export var knee_y: float = -165.0
@export var leg_hw_top: float = 27.0
@export var leg_hw_knee: float = 15.0
@export var leg_hw_ankle: float = 9.0
@export var ankle_y: float = -26.0
@export var ankle_x: float = 25.0
@export var foot_scale: float = 1.0

@export_group("Arms")
@export var arm_length: float = 225.0
@export var arm_hw_top: float = 13.0
@export var arm_hw_wrist: float = 7.5
@export var arm_angle_deg: float = 16.0

@export_group("Look")
@export var skin_color: Color = Color(0.96, 0.82, 0.72)

const CHEST_V := 0.22
const BUST_V := 0.40
const SHOULDER_ANCHOR := Vector2(0.9, 0.05)  # in bodice frame


func torso_length() -> float:
	return waist_y - shoulder_y


func skirt_length() -> float:
	return ankle_y - waist_y


## Half width of the body silhouette at a model-space height.
## Shared by the bodice and skirt frames so both agree at the waist seam.
func silhouette_hw(y: float) -> float:
	var d := torso_length()
	var ys := PackedFloat32Array([shoulder_y, shoulder_y + CHEST_V * d, shoulder_y + BUST_V * d, waist_y, hip_y])
	var ws := PackedFloat32Array([shoulder_hw, chest_hw, bust_hw, waist_hw, hip_hw])
	if y <= ys[0]:
		return ws[0]
	if y >= ys[4]:
		return ws[4]
	for i in range(4):
		if y <= ys[i + 1]:
			var t := (y - ys[i]) / maxf(ys[i + 1] - ys[i], 0.001)
			# Catmull-Rom style tangents for a smooth silhouette.
			var w0 := ws[maxi(i - 1, 0)]
			var w1 := ws[i]
			var w2 := ws[i + 1]
			var w3 := ws[mini(i + 2, 4)]
			var m1 := (w2 - w0) * 0.5
			var m2 := (w3 - w1) * 0.5
			if i == 0:
				m1 = 0.0
			if i == 3:
				m2 = 0.0
			var t2 := t * t
			var t3 := t2 * t
			return (2.0 * t3 - 3.0 * t2 + 1.0) * w1 + (t3 - 2.0 * t2 + t) * m1 \
				+ (-2.0 * t3 + 3.0 * t2) * w2 + (t3 - t2) * m2
	return ws[4]


## Bodice frame: v = 0 at the shoulder line, v = 1 at the waist; u = +-1 at the body edge.
func bodice_to_model(p: Vector2) -> Vector2:
	var y := shoulder_y + p.y * torso_length()
	return Vector2(p.x * silhouette_hw(y), y)


## Skirt frame: v = 0 at the waist, v = 1 at the ankle; u = +-1 at the body edge (hip width below the hips).
func skirt_to_model(p: Vector2) -> Vector2:
	var y := waist_y + p.y * skirt_length()
	return Vector2(p.x * silhouette_hw(y), y)


func shoulder_point(side: int) -> Vector2:
	return bodice_to_model(Vector2(SHOULDER_ANCHOR.x * side, SHOULDER_ANCHOR.y))


func arm_direction(side: int) -> Vector2:
	var a := deg_to_rad(arm_angle_deg)
	return Vector2(side * sin(a), cos(a))


func arm_outward_normal(side: int) -> Vector2:
	var a := deg_to_rad(arm_angle_deg)
	return Vector2(side * cos(a), -sin(a))


func arm_hw(t: float) -> float:
	var tc := clampf(t, 0.0, 1.0)
	# Slight bicep bulge, tapering to the wrist.
	return lerpf(arm_hw_top, arm_hw_wrist, tc) + sin(tc * PI) * 1.5


## Sleeve frame: x = s across the arm (+1 outer edge, -1 inner edge), y = t along the arm
## (0 at the shoulder anchor, 1 at the wrist). side = -1 for screen-left, +1 for screen-right.
func arm_to_model(p: Vector2, side: int) -> Vector2:
	var origin := shoulder_point(side)
	return origin + arm_direction(side) * (p.y * arm_length) + arm_outward_normal(side) * (p.x * arm_hw(p.y))


func wrist_point(side: int) -> Vector2:
	return arm_to_model(Vector2(0.0, 1.0), side)


func ankle_point(side: int) -> Vector2:
	return Vector2(side * ankle_x, ankle_y)


func leg_hw(y: float) -> float:
	if y < knee_y:
		var t := clampf((y - hip_y) / (knee_y - hip_y), 0.0, 1.0)
		return lerpf(leg_hw_top, leg_hw_knee, t)
	var t2 := clampf((y - knee_y) / (ankle_y - knee_y), 0.0, 1.0)
	return lerpf(leg_hw_knee, leg_hw_ankle, t2)


func head_center() -> Vector2:
	return Vector2(0.0, head_center_y)


func ear_point(side: int) -> Vector2:
	return head_center() + Vector2(side * head_radius * 0.98, head_radius * 0.18)


func neck_base() -> Vector2:
	return Vector2(0.0, shoulder_y - torso_length() * 0.1)


## Named attachment anchors used by garments, shoes and jewelry.
func get_anchor(anchor_name: String) -> Vector2:
	match anchor_name:
		"neck":
			return neck_base()
		"shoulder_left":
			return shoulder_point(-1)
		"shoulder_right":
			return shoulder_point(1)
		"armpit_left":
			return bodice_to_model(Vector2(-1.0, CHEST_V))
		"armpit_right":
			return bodice_to_model(Vector2(1.0, CHEST_V))
		"waist":
			return Vector2(0.0, waist_y)
		"hip_left":
			return Vector2(-hip_hw, hip_y)
		"hip_right":
			return Vector2(hip_hw, hip_y)
		"wrist_left":
			return wrist_point(-1)
		"wrist_right":
			return wrist_point(1)
		"ankle_left":
			return ankle_point(-1)
		"ankle_right":
			return ankle_point(1)
		"ear_left":
			return ear_point(-1)
		"ear_right":
			return ear_point(1)
		"head":
			return head_center()
		"crown":
			return head_center() + Vector2(0.0, -head_radius * 1.15)
	push_warning("Unknown anchor '%s'" % anchor_name)
	return Vector2.ZERO


const ANCHOR_NAMES := [
	"neck", "shoulder_left", "shoulder_right", "armpit_left", "armpit_right",
	"waist", "hip_left", "hip_right", "wrist_left", "wrist_right",
	"ankle_left", "ankle_right", "ear_left", "ear_right", "head", "crown",
]
