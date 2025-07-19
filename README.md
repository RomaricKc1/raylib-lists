# Raylib List widget lib
List widget for [Raylib-zig](https://github.com/Not-Nik/raylib-zig).

Example usage here -> [ZISTORY](https://github.com/RomaricKc1/zistory).

Tested on Zig version `0.15.0-dev.936+fc2c1883b`, `0.14.1`.

> [!NOTE]
> This is configured to work on `wayland`. If you are on `x11`, you'll need to change the display `backend`.

In the raylib dependency.

```zig
const raylib_dep = b.dependency("raylib_zig", .{
    .target = target,
    .optimize = optimize,
    .linux_display_backend = .X11,
});
```

# Usage

The project must have been created using `zig init`.

Run this to add it to your `build.zig.zon`:

```
zig fetch --save git+https://github.com/RomaricKc1/raylib-lists/
```

And add these lines to your `build.zig` file:

```zig
const rl_lists_dep = b.dependency("rl_lists", .{
    .target = target,
    .optimize = optimize,
});
const rl_lists = rl_lists_dep.module("raylib_lists"); // lists widget
```
Now add the modules to your target:

```zig
exe.root_module.addImport("rl_lists", rl_lists);
```
you can then import it in your code.

```zig
const rl_lists = @import("rl_lists");
```

# Checkout another widget
- [Raylib-bar_chart](https://github.com/RomaricKc1/raylib-bar_chart)

