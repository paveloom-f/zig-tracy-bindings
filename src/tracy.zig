const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const Src = std.builtin.SourceLocation;

/// Is Tracy integration enabled?
pub const enabled = !builtin.is_test and build_options.tracy;

/// Tracy's C header
const c = if (enabled) @cImport({
    @cDefine("TRACY_ENABLE", "");
    @cInclude("TracyC.h");
}) else void;

const has_callstack_support = enabled and @hasDecl(c, "TRACY_HAS_CALLSTACK") and @hasDecl(c, "TRACY_CALLSTACK");
const callstack_enabled: c_int = if (has_callstack_support) c.TRACY_CALLSTACK else 0;

pub const ZoneCtx = struct {
    zone: if (enabled) c.___tracy_c_zone_context else void,
    pub inline fn setText(self: ZoneCtx, text: []const u8) void {
        if (!enabled) return;
        c.___tracy_emit_zone_text(self.zone, text.ptr, text.len);
    }
    pub inline fn setName(self: ZoneCtx, name: []const u8) void {
        if (!enabled) return;
        c.___tracy_emit_zone_name(self.zone, name.ptr, name.len);
    }
    pub inline fn setValue(self: ZoneCtx, val: u64) void {
        if (!enabled) return;
        c.___tracy_emit_zone_value(self.zone, val);
    }
    pub inline fn end(self: ZoneCtx) void {
        if (!enabled) return;
        c.___tracy_emit_zone_end(self.zone);
    }
};

inline fn initZone(comptime src: Src, name: ?[*:0]const u8, color: u32, depth: c_int) ZoneCtx {
    if (!enabled) return ZoneCtx{ .zone = {} };

    const static = struct {
        var loc: c.___tracy_source_location_data = undefined;
    };

    static.loc = .{
        .name = name,
        .function = src.fn_name.ptr,
        .file = src.file.ptr,
        .line = src.line,
        .color = color,
    };

    const zone = if (has_callstack_support)
        c.___tracy_emit_zone_begin_callstack(&static.loc, depth, 1)
    else
        c.___tracy_emit_zone_begin(&static.loc, 1);

    return ZoneCtx{ .zone = zone };
}

pub inline fn initThread() void {
    if (!enabled) return;
    c.___tracy_init_thread();
}

pub inline fn setThreadName(name: [*:0]const u8) void {
    if (!enabled) return;
    c.___tracy_set_thread_name(name);
}

pub inline fn Zone(comptime src: Src) ZoneCtx {
    return initZone(src, null, 0, callstack_enabled);
}

pub inline fn ZoneN(comptime src: Src, name: [*:0]const u8) ZoneCtx {
    return initZone(src, name, 0, callstack_enabled);
}

pub inline fn ZoneC(comptime src: Src, color: u32) ZoneCtx {
    return initZone(src, null, color, callstack_enabled);
}

pub inline fn ZoneNC(comptime src: Src, name: [*:0]const u8, color: u32) ZoneCtx {
    return initZone(src, name, color, callstack_enabled);
}

pub inline fn ZoneS(comptime src: Src, depth: i32) ZoneCtx {
    return initZone(src, null, 0, depth);
}

pub inline fn ZoneNS(comptime src: Src, name: [*:0]const u8, depth: i32) ZoneCtx {
    return initZone(src, name, 0, depth);
}

pub inline fn ZoneCS(comptime src: Src, color: u32, depth: i32) ZoneCtx {
    return initZone(src, null, color, depth);
}

pub inline fn ZoneNCS(comptime src: Src, name: [*:0]const u8, color: u32, depth: i32) ZoneCtx {
    return initZone(src, name, color, depth);
}

pub inline fn alloc(ptr: ?*const anyopaque, size: usize) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_alloc_callstack(ptr, size, callstack_enabled, 0);
    } else {
        c.___tracy_emit_memory_alloc(ptr, size, 0);
    }
}

pub inline fn free(ptr: ?*const anyopaque, size: usize) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_free_callstack(ptr, callstack_enabled, 0);
    } else {
        c.___tracy_emit_memory_free(ptr, size, 0);
    }
}

pub inline fn secureAlloc(ptr: ?*const anyopaque, size: usize) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_alloc_callstack(ptr, size, callstack_enabled, 1);
    } else {
        c.___tracy_emit_memory_alloc(ptr, size, 1);
    }
}

pub inline fn secureFree(ptr: ?*const anyopaque, size: usize) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_free_callstack(ptr, callstack_enabled, 1);
    } else {
        c.___tracy_emit_memory_free(ptr, size, 1);
    }
}

pub inline fn allocS(ptr: ?*const anyopaque, size: usize, depth: c_int) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_alloc_callstack(ptr, size, depth, 0);
    } else {
        c.___tracy_emit_memory_alloc(ptr, size, 0);
    }
}

pub inline fn freeS(ptr: ?*const anyopaque, depth: c_int) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_free_callstack(ptr, depth, 0);
    } else {
        c.___tracy_emit_memory_free(ptr, 0);
    }
}

pub inline fn secureAllocS(ptr: ?*const anyopaque, size: usize, depth: c_int) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_alloc_callstack(ptr, size, depth, 1);
    } else {
        c.___tracy_emit_memory_alloc(ptr, size, 1);
    }
}

pub inline fn SecureFreeS(ptr: ?*const anyopaque, depth: c_int) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_free_callstack(ptr, depth, 1);
    } else {
        c.___tracy_emit_memory_free(ptr, 1);
    }
}

pub inline fn allocN(ptr: ?*const anyopaque, size: usize, name: [*:0]const u8) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_alloc_callstack_named(ptr, size, callstack_enabled, 0, name);
    } else {
        c.___tracy_emit_memory_alloc_named(ptr, size, 0, name);
    }
}

pub inline fn freeN(ptr: ?*const anyopaque, name: [*:0]const u8) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_free_callstack_named(ptr, callstack_enabled, 0, name);
    } else {
        c.___tracy_emit_memory_free_named(ptr, 0, name);
    }
}

pub inline fn secureAllocN(ptr: ?*const anyopaque, size: usize, name: [*:0]const u8) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_alloc_callstack_named(ptr, size, callstack_enabled, 1, name);
    } else {
        c.___tracy_emit_memory_alloc_named(ptr, size, 1, name);
    }
}

pub inline fn secureFreeN(ptr: ?*const anyopaque, name: [*:0]const u8) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_free_callstack_named(ptr, callstack_enabled, 1, name);
    } else {
        c.___tracy_emit_memory_free_named(ptr, 1, name);
    }
}

pub inline fn allocNS(ptr: ?*const anyopaque, size: usize, depth: c_int, name: [*:0]const u8) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, 0, name);
    } else {
        c.___tracy_emit_memory_alloc_named(ptr, size, 0, name);
    }
}

pub inline fn freeNS(ptr: ?*const anyopaque, depth: c_int, name: [*:0]const u8) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_free_callstack_named(ptr, depth, 0, name);
    } else {
        c.___tracy_emit_memory_free_named(ptr, 0, name);
    }
}

pub inline fn secureAllocNS(ptr: ?*const anyopaque, size: usize, depth: c_int, name: [*:0]const u8) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, 1, name);
    } else {
        c.___tracy_emit_memory_alloc_named(ptr, size, 1, name);
    }
}

pub inline fn secureFreeNS(ptr: ?*const anyopaque, depth: c_int, name: [*:0]const u8) void {
    if (!enabled) return;
    if (has_callstack_support) {
        c.___tracy_emit_memory_free_callstack_named(ptr, depth, 1, name);
    } else {
        c.___tracy_emit_memory_free_named(ptr, 1, name);
    }
}

pub inline fn message(text: []const u8) void {
    if (!enabled) return;
    c.___tracy_emit_message(text.ptr, text.len, callstack_enabled);
}

pub inline fn messageL(text: [*:0]const u8, color: u32) void {
    if (!enabled) return;
    c.___tracy_emit_messageL(text, color, callstack_enabled);
}

pub inline fn messageC(text: []const u8, color: u32) void {
    if (!enabled) return;
    c.___tracy_emit_messageC(text.ptr, text.len, color, callstack_enabled);
}
pub inline fn messageLC(text: [*:0]const u8, color: u32) void {
    if (!enabled) return;
    c.___tracy_emit_messageLC(text, color, callstack_enabled);
}

pub inline fn messageS(text: []const u8, depth: c_int) void {
    if (!enabled) return;
    const inner_depth: c_int = if (has_callstack_support) depth else 0;
    c.___tracy_emit_message(text.ptr, text.len, inner_depth);
}
pub inline fn messageLS(text: [*:0]const u8, depth: c_int) void {
    if (!enabled) return;
    const inner_depth: c_int = if (has_callstack_support) depth else 0;
    c.___tracy_emit_messageL(text, inner_depth);
}

pub inline fn messageCS(text: []const u8, color: u32, depth: c_int) void {
    if (!enabled) return;
    const inner_depth: c_int = if (has_callstack_support) depth else 0;
    c.___tracy_emit_messageC(text.ptr, text.len, color, inner_depth);
}

pub inline fn messageLCS(text: [*:0]const u8, color: u32, depth: c_int) void {
    if (!enabled) return;
    const inner_depth: c_int = if (has_callstack_support) depth else 0;
    c.___tracy_emit_messageLC(text, color, inner_depth);
}

pub inline fn frameMark() void {
    if (!enabled) return;
    c.___tracy_emit_frame_mark(null);
}

pub inline fn frameMarkNamed(name: [*:0]const u8) void {
    if (!enabled) return;
    c.___tracy_emit_frame_mark(name);
}

pub inline fn frameMarkStart(name: [*:0]const u8) void {
    if (!enabled) return;
    c.___tracy_emit_frame_mark_start(name);
}

pub inline fn frameMarkEnd(name: [*:0]const u8) void {
    if (!enabled) return;
    c.___tracy_emit_frame_mark_end(name);
}

pub inline fn frameImage(image: ?*const anyopaque, width: u16, height: u16, offset: u8, flip: c_int) void {
    if (!enabled) return;
    c.___tracy_emit_frame_image(image, width, height, offset, flip);
}

pub inline fn plotF(name: [*:0]const u8, val: f64) void {
    if (!enabled) return;
    c.___tracy_emit_plot(name, val);
}

pub inline fn plotU(name: [*:0]const u8, val: u64) void {
    if (!enabled) return;
    c.___tracy_emit_plot(name, @intToFloat(f64, val));
}

pub inline fn plotI(name: [*:0]const u8, val: i64) void {
    if (!enabled) return;
    c.___tracy_emit_plot(name, @intToFloat(f64, val));
}

pub inline fn appInfo(text: []const u8) void {
    if (!enabled) return;
    c.___tracy_emit_message_appinfo(text.ptr, text.len);
}
