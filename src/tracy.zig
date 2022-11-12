//! Zig bindings for the Tracy Profiler
//!
//! Note that these compile down to nothing
//! when the Tracy integration is disabled.

const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const Src = std.builtin.SourceLocation;

/// Is Tracy integration enabled?
pub const enabled = !builtin.is_test and build_options.tracy;

/// Forced call stack capture depth
pub const forced_depth = build_options.tracy_depth;

/// Tracy's C header
const c = if (enabled) @cImport({
    @cDefine("TRACY_ENABLE", "");
    @cInclude("TracyC.h");
}) else void;

/// Set the name of the current thread
pub inline fn setThreadName(name: [*:0]const u8) void {
    if (!enabled) return;
    c.___tracy_set_thread_name(name);
}

/// Zone context
pub const ZoneCtx = struct {
    zone: if (enabled) c.___tracy_c_zone_context else void,
    /// Set the text string of the zone
    pub inline fn setText(self: ZoneCtx, text: []const u8) void {
        if (!enabled) return;
        c.___tracy_emit_zone_text(self.zone, text.ptr, text.len);
    }
    /// Set the name of the zone
    pub inline fn setName(self: ZoneCtx, name: []const u8) void {
        if (!enabled) return;
        c.___tracy_emit_zone_name(self.zone, name.ptr, name.len);
    }
    /// Set the value of the zone
    pub inline fn setValue(self: ZoneCtx, val: u64) void {
        if (!enabled) return;
        c.___tracy_emit_zone_value(self.zone, val);
    }
    // End the zone
    pub inline fn end(self: ZoneCtx) void {
        if (!enabled) return;
        c.___tracy_emit_zone_end(self.zone);
    }
};

/// Initialize a zone context
inline fn initZone(comptime src: Src, name: ?[*:0]const u8, color: u32, depth: c_int) ZoneCtx {
    if (!enabled) return ZoneCtx{ .zone = {} };
    // Tracy uses pointer identity to identify contexts.
    // The `src` parameter being comptime ensures that each
    // zone gets its own unique global location for this struct.
    const static = struct {
        var loc: c.___tracy_source_location_data = undefined;
    };
    // Define source location data
    static.loc = c.___tracy_source_location_data{
        .name = name,
        .function = src.fn_name.ptr,
        .file = src.file.ptr,
        .line = src.line,
        .color = color,
    };
    // Create a zone
    const zone = if (depth != 0)
        c.___tracy_emit_zone_begin_callstack(&static.loc, depth, 1)
    else
        c.___tracy_emit_zone_begin(&static.loc, 1);
    // Return a zone context
    return ZoneCtx{ .zone = zone };
}

/// Mark a zone
pub inline fn Zone(comptime src: Src) ZoneCtx {
    return initZone(src, null, 0, forced_depth);
}

/// Mark a zone with a specific name
pub inline fn ZoneN(comptime src: Src, name: [*:0]const u8) ZoneCtx {
    return initZone(src, name, 0, forced_depth);
}

/// Mark a zone with a specific color
pub inline fn ZoneC(comptime src: Src, color: u32) ZoneCtx {
    return initZone(src, null, color, forced_depth);
}

/// Mark a zone with a specific name and color
pub inline fn ZoneNC(comptime src: Src, name: [*:0]const u8, color: u32) ZoneCtx {
    return initZone(src, name, color, forced_depth);
}

/// Mark a zone with a specific call stack capture depth
pub inline fn ZoneS(comptime src: Src, depth: i32) ZoneCtx {
    return initZone(src, null, 0, depth);
}

/// Mark a zone with a specific name and call stack capture depth
pub inline fn ZoneNS(comptime src: Src, name: [*:0]const u8, depth: i32) ZoneCtx {
    return initZone(src, name, 0, depth);
}

/// Mark a zone with a specific color and call stack capture depth
pub inline fn ZoneCS(comptime src: Src, color: u32, depth: i32) ZoneCtx {
    return initZone(src, null, color, depth);
}

/// Mark a zone with a specific name, color, and call stack capture depth
pub inline fn ZoneNCS(comptime src: Src, name: [*:0]const u8, color: u32, depth: i32) ZoneCtx {
    return initZone(src, name, color, depth);
}

/// Mark a memory allocation event
pub inline fn alloc(ptr: ?*const anyopaque, size: usize) void {
    if (!enabled) return;
    if (forced_depth != 0) {
        c.___tracy_emit_memory_alloc_callstack(ptr, size, forced_depth, 0);
    } else {
        c.___tracy_emit_memory_alloc(ptr, size, 0);
    }
}

/// Mark a memory deallocation event
pub inline fn free(ptr: ?*const anyopaque) void {
    if (!enabled) return;
    if (forced_depth != 0) {
        c.___tracy_emit_memory_free_callstack(ptr, forced_depth, 0);
    } else {
        c.___tracy_emit_memory_free(ptr, 0);
    }
}

/// Mark a secure memory allocation event
///
/// Won't crash if the profiler was no longer available.
pub inline fn secureAlloc(ptr: ?*const anyopaque, size: usize) void {
    if (!enabled) return;
    if (forced_depth != 0) {
        c.___tracy_emit_memory_alloc_callstack(ptr, size, forced_depth, 1);
    } else {
        c.___tracy_emit_memory_alloc(ptr, size, 1);
    }
}

/// Mark a secure memory deallocation event
///
/// Won't crash if the profiler was no longer available.
pub inline fn secureFree(ptr: ?*const anyopaque, size: usize) void {
    if (!enabled) return;
    if (forced_depth) {
        c.___tracy_emit_memory_free_callstack(ptr, forced_depth, 1);
    } else {
        c.___tracy_emit_memory_free(ptr, size, 1);
    }
}

/// Mark a memory allocation event with a specific call stack capture depth
pub inline fn allocS(ptr: ?*const anyopaque, size: usize, depth: c_int) void {
    if (!enabled) return;
    if (depth != 0) {
        c.___tracy_emit_memory_alloc_callstack(ptr, size, depth, 0);
    } else {
        c.___tracy_emit_memory_alloc(ptr, size, 0);
    }
}

/// Mark a memory deallocation event with a specific call stack capture depth
pub inline fn freeS(ptr: ?*const anyopaque, depth: c_int) void {
    if (!enabled) return;
    if (depth != 0) {
        c.___tracy_emit_memory_free_callstack(ptr, depth, 0);
    } else {
        c.___tracy_emit_memory_free(ptr, 0);
    }
}

/// Mark a secure memory allocation event with a specific call stack capture depth
///
/// Won't crash if the profiler was no longer available.
pub inline fn secureAllocS(ptr: ?*const anyopaque, size: usize, depth: c_int) void {
    if (!enabled) return;
    if (depth != 0) {
        c.___tracy_emit_memory_alloc_callstack(ptr, size, depth, 1);
    } else {
        c.___tracy_emit_memory_alloc(ptr, size, 1);
    }
}

/// Mark a secure memory deallocation event with a specific call stack capture depth
///
/// Won't crash if the profiler was no longer available.
pub inline fn secureFreeS(ptr: ?*const anyopaque, depth: c_int) void {
    if (!enabled) return;
    if (depth != 0) {
        c.___tracy_emit_memory_free_callstack(ptr, depth, 1);
    } else {
        c.___tracy_emit_memory_free(ptr, 1);
    }
}

/// Mark a memory allocation event with a specific name
pub inline fn allocN(ptr: ?*const anyopaque, size: usize, name: [*:0]const u8) void {
    if (!enabled) return;
    if (forced_depth != 0) {
        c.___tracy_emit_memory_alloc_callstack_named(ptr, size, forced_depth, 0, name);
    } else {
        c.___tracy_emit_memory_alloc_named(ptr, size, 0, name);
    }
}

/// Mark a memory deallocation event with a specific name
pub inline fn freeN(ptr: ?*const anyopaque, name: [*:0]const u8) void {
    if (!enabled) return;
    if (forced_depth != 0) {
        c.___tracy_emit_memory_free_callstack_named(ptr, forced_depth, 0, name);
    } else {
        c.___tracy_emit_memory_free_named(ptr, 0, name);
    }
}

/// Mark a secure memory allocation event with a specific name
///
/// Won't crash if the profiler was no longer available.
pub inline fn secureAllocN(ptr: ?*const anyopaque, size: usize, name: [*:0]const u8) void {
    if (!enabled) return;
    if (forced_depth != 0) {
        c.___tracy_emit_memory_alloc_callstack_named(ptr, size, forced_depth, 1, name);
    } else {
        c.___tracy_emit_memory_alloc_named(ptr, size, 1, name);
    }
}

/// Mark a secure memory deallocation event with a specific name
///
/// Won't crash if the profiler was no longer available.
pub inline fn secureFreeN(ptr: ?*const anyopaque, name: [*:0]const u8) void {
    if (!enabled) return;
    if (forced_depth != 0) {
        c.___tracy_emit_memory_free_callstack_named(ptr, forced_depth, 1, name);
    } else {
        c.___tracy_emit_memory_free_named(ptr, 1, name);
    }
}

/// Mark a memory allocation event with a specific name and call stack capture depth
pub inline fn allocNS(ptr: ?*const anyopaque, size: usize, depth: c_int, name: [*:0]const u8) void {
    if (!enabled) return;
    if (depth != 0) {
        c.___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, 0, name);
    } else {
        c.___tracy_emit_memory_alloc_named(ptr, size, 0, name);
    }
}

/// Mark a memory deallocation event with a specific name and call stack capture depth
pub inline fn freeNS(ptr: ?*const anyopaque, depth: c_int, name: [*:0]const u8) void {
    if (!enabled) return;
    if (depth != 0) {
        c.___tracy_emit_memory_free_callstack_named(ptr, depth, 0, name);
    } else {
        c.___tracy_emit_memory_free_named(ptr, 0, name);
    }
}

/// Mark a secure memory allocation event with a specific name and call stack capture depth
///
/// Won't crash if the profiler was no longer available.
pub inline fn secureAllocNS(ptr: ?*const anyopaque, size: usize, depth: c_int, name: [*:0]const u8) void {
    if (!enabled) return;
    if (depth != 0) {
        c.___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, 1, name);
    } else {
        c.___tracy_emit_memory_alloc_named(ptr, size, 1, name);
    }
}

/// Mark a secure memory deallocation event with a specific name and call stack capture depth
///
/// Won't crash if the profiler was no longer available.
pub inline fn secureFreeNS(ptr: ?*const anyopaque, depth: c_int, name: [*:0]const u8) void {
    if (!enabled) return;
    if (depth != 0) {
        c.___tracy_emit_memory_free_callstack_named(ptr, depth, 1, name);
    } else {
        c.___tracy_emit_memory_free_named(ptr, 1, name);
    }
}

/// Send a message
pub inline fn message(text: [:0]const u8) void {
    if (!enabled) return;
    c.___tracy_emit_message(text.ptr, text.len, forced_depth);
}

/// Send a message with a specific call stack capture depth
pub inline fn messageS(text: [:0]const u8, depth: c_int) void {
    if (!enabled) return;
    c.___tracy_emit_message(text.ptr, text.len, depth);
}

/// Send a message with a specific color
pub inline fn messageC(text: [:0]const u8, color: u32) void {
    if (!enabled) return;
    c.___tracy_emit_messageC(text.ptr, text.len, color, forced_depth);
}

/// Send a message with a specific color and call stack capture depth
pub inline fn messageCS(text: [:0]const u8, color: u32, depth: c_int) void {
    if (!enabled) return;
    c.___tracy_emit_messageC(text.ptr, text.len, color, depth);
}

/// Send additional information about the profiled application
pub inline fn appInfo(text: [:0]const u8) void {
    if (!enabled) return;
    c.___tracy_emit_message_appinfo(text.ptr, text.len);
}

/// Mark a frame
pub inline fn frameMark() void {
    if (!enabled) return;
    c.___tracy_emit_frame_mark(null);
}

/// Mark a frame with a specific name
pub inline fn frameMarkNamed(name: [*:0]const u8) void {
    if (!enabled) return;
    c.___tracy_emit_frame_mark(name);
}

/// Mark the beginning of a discontinuous frame with a specific name
pub inline fn frameMarkStart(name: [*:0]const u8) void {
    if (!enabled) return;
    c.___tracy_emit_frame_mark_start(name);
}

/// Mark the end of a discontinuous frame with a specific name
pub inline fn frameMarkEnd(name: [*:0]const u8) void {
    if (!enabled) return;
    c.___tracy_emit_frame_mark_end(name);
}

/// Send a frame image
pub inline fn frameImage(image: ?*const anyopaque, width: u16, height: u16, offset: u8, flip: c_int) void {
    if (!enabled) return;
    c.___tracy_emit_frame_image(image, width, height, offset, flip);
}

/// Plot a double-precision floating-point value
pub inline fn plot(name: [*:0]const u8, val: f64) void {
    if (!enabled) return;
    c.___tracy_emit_plot(name, val);
}

/// Plot a single-precision floating-point value
pub inline fn plotFloat(name: [*:0]const u8, val: f32) void {
    if (!enabled) return;
    c.___tracy_emit_plot_float(name, val);
}

/// Plot a 64-bit signed integer
pub inline fn plotInt(name: [*:0]const u8, val: i64) void {
    if (!enabled) return;
    c.___tracy_emit_plot_int(name, val);
}

/// A wrapper around the allocator which traces when memory is allocated and freed.
/// Providing a name will make Tracy mark these operations with this name.
pub fn TracyAllocator(comptime name_opt: ?[:0]const u8) type {
    return struct {
        /// Underlying allocator
        parent_allocator: std.mem.Allocator,
        const Self = @This();
        /// Initialize the wrapper
        pub fn init(parent_allocator: std.mem.Allocator) Self {
            return .{
                .parent_allocator = parent_allocator,
            };
        }
        /// Initialize the allocator
        pub fn allocator(self: *Self) std.mem.Allocator {
            return std.mem.Allocator.init(self, allocFn, resizeFn, freeFn);
        }
        /// Allocate the memory
        fn allocFn(self: *Self, len: usize, ptr_align: u29, len_align: u29, ret_addr: usize) std.mem.Allocator.Error![]u8 {
            const result = self.parent_allocator.rawAlloc(len, ptr_align, len_align, ret_addr);
            if (result) |data| {
                if (data.len != 0) {
                    if (name_opt) |name| {
                        allocN(data.ptr, data.len, name);
                    } else {
                        alloc(data.ptr, data.len);
                    }
                }
            } else |_| {
                messageC("allocation failed", 0xFF0000);
            }
            return result;
        }
        /// Resize the memory
        fn resizeFn(self: *Self, buf: []u8, buf_align: u29, new_len: usize, len_align: u29, ret_addr: usize) ?usize {
            if (self.parent_allocator.rawResize(buf, buf_align, new_len, len_align, ret_addr)) |resized_len| {
                if (name_opt) |name| {
                    freeN(buf.ptr, name);
                    allocN(buf.ptr, resized_len, name);
                } else {
                    free(buf.ptr);
                    alloc(buf.ptr, resized_len);
                }
                return resized_len;
            }
            return null;
        }
        /// Free the memory
        fn freeFn(self: *Self, buf: []u8, buf_align: u29, ret_addr: usize) void {
            self.parent_allocator.rawFree(buf, buf_align, ret_addr);
            // This condition is to handle free being called on an empty slice that was never even allocated
            // (example case: `std.process.getSelfExeSharedLibPaths` can return `&[_][:0]u8{}`)
            if (buf.len != 0) {
                if (name_opt) |name| {
                    freeN(buf.ptr, name);
                } else {
                    free(buf.ptr);
                }
            }
        }
    };
}
