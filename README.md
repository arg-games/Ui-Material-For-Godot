# UI Material for Godot

A reusable Godot 4.7 `canvas_item` shader include library for procedural UI materials.

## Install as a submodule

From the root of a Godot project, add this repository at the standard addon path:

```powershell
git submodule add https://github.com/arg-games/Ui-Material-For-Godot.git addons/ui_material
```

Then include the umbrella header in a 2D shader:

```glsl
shader_type canvas_item;

#include "res://addons/ui_material/ui_material.gdshaderinc"
```

To clone a project with all submodules, use `git clone --recurse-submodules`.

## Install by copying

Copy the contents of this repository into `addons/ui_material` in a Godot project. Do not add the repository's parent directory as an extra folder.

The library contains helpers for UV transforms, gradients, time, SDF shapes, masks, patterns, and distortions. The `.uid` files belong with their matching include files.

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
