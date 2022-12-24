//! This dummy program prints a digit on a line every quarter
//! of a second, then erases all of them, then prints them again.
//!
//! We do many unnecessary things here just to demonstrate the Tracy integration.

const std = @import("std");
const tracy = @import("tracy");

/// Print the current digit
fn print(c: u8) void {
    const zone = tracy.ZoneN(@src(), "print");
    defer zone.end();

    std.debug.print("{}", .{c});
    tracy.plotInt("Counter", c);
}

/// Add a digit to the string and the list, increment the counter
fn increment(c: *u8) void {
    const zone = tracy.ZoneNS(@src(), "increment", 5);
    defer zone.end();

    c.* += 1;

    tracy.messageC("Counter incremented!", 0x00FF00);
}

/// Append to the list
fn append(list: *std.ArrayList(u8), c: u8) !void {
    const zone = tracy.Zone(@src());
    defer zone.end();

    try list.append(c);

    tracy.messageC("Appended to the list!", 0x0000FF);
}

/// Reset the counter, the string, and the list
fn reset(c: *u8, list: *std.ArrayList(u8)) void {
    const zone = tracy.Zone(@src());
    defer zone.end();

    std.debug.print("\r" ++ " " ** 9 ++ "\r", .{});
    c.* = 1;

    tracy.messageC("Counter reset!", 0xFF0000);
    tracy.plotInt("Counter", c.*);
    list.clearRetainingCapacity();
}

/// Run the program
pub fn main() !void {
    // Mark the main function as a fiber
    tracy.FiberEnter("Main");
    defer tracy.FiberLeave();
    // Send some application information
    tracy.appInfo("Profiling the example function");
    // Prepare an array list, so we can demonstrate the allocator wrapper
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var t_fba = tracy.TracyAllocator(null, 5).init(fba.allocator());
    var list = std.ArrayList(u8).init(t_fba.allocator());
    defer list.deinit();
    // Prepare counters (we print digits from 1 to 10)
    var i: u64 = 0;
    var c: u8 = 1;
    // For each iteration
    while (i != 20) : (i += 1) {
        // If we've iterated through all the digits
        if (c == 10) {
            // Reset the counter, the string, and the list
            reset(&c, &list);
            // Otherwise,
        } else {
            // Print the current digit
            print(c);
            // Increment the counter
            increment(&c);
            // Append to the list
            try append(&list, c);
        }
        // Sleep for 0.25 seconds
        std.time.sleep(250_000_000);
        // We don't really have frames here, but
        // we will use this loop to imitate them
        tracy.frameMarkNamed("Iteration");
    }
}
