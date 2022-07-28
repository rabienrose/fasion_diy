extends Spatial


# Control variables
export var maxPitch : float = 45
export var minPitch : float = -45
export var maxZoom : float = 20
export var minZoom : float = 4
export var zoomStep : float = 2
export var zoomYStep : float = 0.15
export var verticalSensitivity : float = 0.002
export var horizontalSensitivity : float = 0.002
export var camYOffset : float = 4.0
export var camLerpSpeed : float = 16.0
export(NodePath) var target=null

# Private variables
var _camTarget : Spatial = null
var _cam : ClippedCamera
var _curZoom : float = 0.0
var pressed=false

func _ready() -> void:
    if target!=null:
        _camTarget = get_node(target)
    else:
        _camTarget=Position3D.new()
        add_child(_camTarget)
    _cam = get_node("ClippedCamera")
    _cam.translate(Vector3(0,camYOffset,maxZoom))
    _curZoom = maxZoom

func _input(event) -> void:
    if event is InputEventMouseMotion:
        if pressed:
            rotate_y(-event.relative.x * horizontalSensitivity)
            rotation.x = clamp(rotation.x - event.relative.y * verticalSensitivity, deg2rad(minPitch), deg2rad(maxPitch))
            orthonormalize()
        
    if event is InputEventMouseButton:
        # Change zoom level on mouse wheel rotation
        if event.is_pressed():
            if event.button_index ==BUTTON_LEFT:
                pressed=true
            if event.button_index == BUTTON_WHEEL_UP and _curZoom > minZoom:
                _curZoom -= zoomStep
                camYOffset -= zoomYStep
            if event.button_index == BUTTON_WHEEL_DOWN and _curZoom < maxZoom:
                _curZoom += zoomStep
                camYOffset += zoomYStep
        else:
            if event.button_index ==BUTTON_LEFT:
                pressed=false

func _process(delta) -> void:
    _cam.set_translation(_cam.translation.linear_interpolate(Vector3(0,camYOffset,_curZoom),delta * camLerpSpeed))
    set_translation(_camTarget.global_transform.origin)
