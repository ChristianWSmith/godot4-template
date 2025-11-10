extends Node
class_name AudioUtils

static func percent_to_perceptual(percent: float) -> float:
	return pow(percent, 0.25)
