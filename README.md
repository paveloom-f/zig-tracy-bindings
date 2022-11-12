### Description

This repository provides [Zig](https://ziglang.org) language bindings for the [Tracy Profiler](https://github.com/wolfpld/tracy).

#### Git mirrors
- [Codeberg](https://codeberg.org/paveloom-f/zig-tracy-bindings)
- [GitHub](https://github.com/paveloom-f/zig-tracy-bindings)
- [GitLab](https://gitlab.com/paveloom-g/forks/zig-tracy-bindings)

#### Example

First, make sure you got a copy of the Tracy's [source code](https://github.com/wolfpld/tracy).

Then, run

```bash
zig build run -Dtracy=/path/to/tracy -Drelease-fast
```

to execute the [example program](src/main.zig).

You can also override the default call stack capture depth:

```bash
zig build run -Dtracy=/path/to/tracy -Dtracy-depth=10 -Drelease-fast
```

#### Integrate

To integrate Tracy in your project:
1) Copy the [`tracy.zig`](src/tracy.zig) file to your project;
2) Edit your [build script](build.zig);
3) Add Tracy calls in your source code (see the [example program](src/main.zig));
4) Provide the path to Tracy's source code via a build option (see example above)

#### Acknowledgments

This is mostly a fork of Martin Wickham's [`Zig-Tracy`](https://github.com/SpexGuy/Zig-Tracy) with a bit of extra niceties (like an allocator wrapper) from the [Zig's version](https://github.com/ziglang/zig/blob/master/src/tracy.zig) of the bindings.
