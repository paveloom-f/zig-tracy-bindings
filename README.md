### Description

This repository provides [Zig](https://ziglang.org) language bindings for the [Tracy Profiler](https://github.com/wolfpld/tracy).

#### Git mirrors
- [Codeberg](https://codeberg.org/paveloom-f/zig-tracy-bindings)
- [GitHub](https://github.com/paveloom-f/zig-tracy-bindings)
- [GitLab](https://gitlab.com/paveloom-g/forks/zig-tracy-bindings)

#### Prerequisites

Make sure you have installed [Zigmod](https://github.com/nektro/zigmod).

#### Example

Run

```bash
cd example
zigmod fetch
zig build run -Dtracy -Drelease-fast
```

to execute the [example program](example/src/main.zig).

You can also override the default call stack capture depth:

```bash
zig build run -Dtracy -Dtracy-depth=10 -Drelease-fast
```

#### Integrate

To integrate Tracy in your project:

1) Add this repository as a dependency to your project:

    ```yml
    # <...>
    root_dependencies:
      - src: git https://github.com/paveloom-f/zig-tracy-bindings
    ```

2) Edit your build script (see the [example build script](example/build.zig));
3) Add Tracy calls in your source code (see the [example program](example/src/main.zig));

#### Acknowledgments

This is mostly a fork of [Martin Wickham's version](https://github.com/SpexGuy/Zig-Tracy) with a bit of extra niceties (like an allocator wrapper) from the [Zig's version](https://github.com/ziglang/zig/blob/master/src/tracy.zig) of the bindings. Also, [Meghan's version](https://github.com/nektro/zig-tracy) showed how to integrate with [Zigmod](https://github.com/nektro/zigmod).
