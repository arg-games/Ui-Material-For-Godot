// Umbrella header for the ui_material shader include library.
// Pulls in every module in dependency order. The engine preprocessor skips
// repeated includes of the same file, so mixing this header with direct
// module includes stays safe.

#include "utilities/aspect_ratio.gdshaderinc"
#include "utilities/ease_curves.gdshaderinc"
#include "utilities/pattern.gdshaderinc"
#include "utilities/ping_pong.gdshaderinc"
#include "utilities/pixelate.gdshaderinc"
#include "utilities/random.gdshaderinc"
#include "utilities/remappable_gradient.gdshaderinc"
#include "utilities/stepped_gradient.gdshaderinc"
#include "utilities/weighted_corners.gdshaderinc"

#include "time.gdshaderinc"
#include "distortion.gdshaderinc"
#include "transform.gdshaderinc"
#include "sdf/sdf_shape.gdshaderinc"
#include "sdf/sdf_circle.gdshaderinc"
#include "sdf/sdf_hexagon.gdshaderinc"
#include "sdf/sdf_box.gdshaderinc"
#include "sdf/sdf_triangle.gdshaderinc"
#include "sdf/sdf_wave.gdshaderinc"
#include "sdf/sdf_operation.gdshaderinc"
#include "mask.gdshaderinc"