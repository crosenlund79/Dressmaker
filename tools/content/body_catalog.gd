extends RefCounted
## Authoring source for the 10 body types. Values are model-space pixels.


static func build() -> Array[BodyDefinition]:
	var list: Array[BodyDefinition] = []
	list.append(_body("classic", "Classic", "Balanced, average proportions.", {}))
	list.append(_body("petite", "Petite", "Shorter stature with a compact frame.", {
		"head_radius": 34.0, "head_center_y": -506.0, "neck_hw": 14.0, "shoulder_y": -441.0, "shoulder_hw": 63.0,
		"chest_hw": 51.0, "bust_hw": 56.0, "waist_y": -333.0, "waist_hw": 37.0, "hip_y": -275.0, "hip_hw": 60.0,
		"knee_y": -150.0, "leg_hw_top": 25.0, "leg_hw_knee": 14.0, "leg_hw_ankle": 8.5, "ankle_y": -24.0, "ankle_x": 23.0,
		"arm_length": 200.0, "arm_hw_top": 12.0, "arm_hw_wrist": 7.0, "foot_scale": 0.92,
		"skin_color": Color(0.87, 0.68, 0.52)}))
	list.append(_body("tall_slender", "Tall & Slender", "Long limbs and a narrow, willowy frame.", {
		"head_radius": 35.0, "head_center_y": -628.0, "neck_hw": 13.5, "shoulder_y": -556.0, "shoulder_hw": 67.0,
		"chest_hw": 50.0, "bust_hw": 53.0, "waist_y": -424.0, "waist_hw": 35.0, "hip_y": -352.0, "hip_hw": 55.0,
		"knee_y": -192.0, "leg_hw_top": 23.0, "leg_hw_knee": 13.0, "leg_hw_ankle": 8.0, "ankle_x": 22.0,
		"arm_length": 252.0, "arm_hw_top": 11.5, "arm_hw_wrist": 6.8, "foot_scale": 1.05,
		"skin_color": Color(0.55, 0.38, 0.27)}))
	list.append(_body("hourglass", "Hourglass", "Full bust and hips with a defined waist.", {
		"shoulder_hw": 72.0, "chest_hw": 60.0, "bust_hw": 72.0, "waist_hw": 37.0, "hip_hw": 77.0,
		"leg_hw_top": 30.0, "skin_color": Color(0.98, 0.86, 0.78)}))
	list.append(_body("pear", "Pear", "Narrow shoulders, generous hips and thighs.", {
		"shoulder_hw": 61.0, "chest_hw": 50.0, "bust_hw": 55.0, "waist_hw": 43.0, "hip_y": -298.0, "hip_hw": 84.0,
		"leg_hw_top": 33.0, "leg_hw_knee": 17.0, "ankle_x": 27.0, "arm_hw_top": 12.5,
		"skin_color": Color(0.76, 0.56, 0.4)}))
	list.append(_body("athletic", "Athletic", "Broad shoulders, strong arms, slim hips.", {
		"neck_hw": 17.0, "shoulder_hw": 83.0, "chest_hw": 67.0, "bust_hw": 64.0, "waist_hw": 50.0, "hip_hw": 61.0,
		"leg_hw_top": 28.0, "leg_hw_knee": 17.0, "leg_hw_ankle": 10.0, "arm_hw_top": 15.5, "arm_hw_wrist": 8.5,
		"skin_color": Color(0.42, 0.28, 0.2)}))
	list.append(_body("full_figure", "Full Figure", "Soft, rounded and generous all over.", {
		"head_radius": 38.0, "neck_hw": 19.0, "shoulder_hw": 84.0, "chest_hw": 76.0, "bust_hw": 86.0, "waist_hw": 74.0,
		"hip_hw": 93.0, "leg_hw_top": 37.0, "leg_hw_knee": 22.0, "leg_hw_ankle": 12.0, "ankle_x": 29.0,
		"arm_hw_top": 18.0, "arm_hw_wrist": 10.0, "arm_angle_deg": 20.0,
		"skin_color": Color(0.93, 0.76, 0.62)}))
	list.append(_body("plus_hourglass", "Plus Hourglass", "Curvy with a pronounced waist.", {
		"head_radius": 37.0, "neck_hw": 17.5, "shoulder_hw": 80.0, "chest_hw": 70.0, "bust_hw": 88.0, "waist_hw": 58.0,
		"hip_hw": 99.0, "leg_hw_top": 37.0, "leg_hw_knee": 21.0, "leg_hw_ankle": 11.0, "ankle_x": 29.0,
		"arm_hw_top": 16.5, "arm_hw_wrist": 9.0, "arm_angle_deg": 19.0,
		"skin_color": Color(0.66, 0.47, 0.33)}))
	list.append(_body("long_torso", "Long Torso", "A long waist with shorter legs.", {
		"head_center_y": -572.0, "shoulder_y": -502.0, "waist_y": -348.0, "waist_hw": 41.0, "hip_y": -290.0,
		"knee_y": -158.0, "arm_length": 230.0, "skin_color": Color(0.98, 0.88, 0.8)}))
	list.append(_body("statuesque", "Statuesque", "Tall, broad and commanding.", {
		"head_radius": 38.0, "head_center_y": -642.0, "neck_hw": 17.0, "shoulder_y": -568.0, "shoulder_hw": 81.0,
		"chest_hw": 64.0, "bust_hw": 71.0, "waist_y": -430.0, "waist_hw": 48.0, "hip_y": -356.0, "hip_hw": 75.0,
		"knee_y": -196.0, "leg_hw_top": 30.0, "leg_hw_knee": 17.0, "leg_hw_ankle": 10.0, "ankle_x": 27.0,
		"arm_length": 258.0, "arm_hw_top": 14.0, "arm_hw_wrist": 8.0, "foot_scale": 1.1,
		"skin_color": Color(0.82, 0.62, 0.48)}))
	return list


static func _body(id: String, name: String, desc: String, values: Dictionary) -> BodyDefinition:
	var b := BodyDefinition.new()
	b.id = id
	b.display_name = name
	b.description = desc
	for key in values:
		b.set(key, values[key])
	return b
