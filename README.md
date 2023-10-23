# TileMap Merger for Godot 4
TileMap Merger is an addon for Godot 4 that TileMap Merge Editor.
In this add-on, the following features are provided.

* Merge: Pasting TileMap data onto another TileMap data is possible.
* Rotate: Rotating isometric tilemaps is supported.
  * Only support diamond down isometric TileMap
* Snap: Snapping to a specified size is available.

![screenshot](https://github.com/airreader/tilemap-merger/assets/1519933/8e5da14d-e81e-46d3-a6c1-b051eb72e9fd)

[YouTube](https://youtu.be/WlJdffz9FwU)

# How to Install
* Asset Library: https://godotengine.org/asset-library/asset/2282
* https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html

# How to use
* Left click
  * set tilemap
* Right click
  * erase tilemap
* Wheel button dragging
  * scroll main screen
* Wheel up / Wheel down
  * rotate tilemap
* Shift + ( Wheel up / Wheel down )
  * zoom in/out main screen

## Rotateing tile
If the tiles are directional, such as on a wall or corner of a house, the tiles themselves must be changed, not just repositioned. In such cases, the following custom data layers control this.
* `tile_name`
* `order_id`

For `tile_name`, give the same name to tiles that are oriented differently but the same. The tiles will change as the tile map rotates.
If tiles with tile_name are arranged clockwise, ｀order_id｀ need not be used. If they are not clockwise, put `order_id` so that they are clockwise.

Rotation will not work correctly in the following cases
* There are more than 4 tiles with the same `tile_name`.
* There are 3 tiles with the same `tile_name`.
* Tiles with the same `tile_name` have `order_id` or not.

