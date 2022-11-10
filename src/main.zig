//! This dummy program prints a digit on a line every quarter
//! of a second, then erases all of them, then prints them again.
//! Its point is to demonstrate the Tracy integration.

const std = @import("std");
const Zone = @import("tracy.zig").Zone;

/// Print the current digit
fn print(c: u8) void {
    const zone = Zone(@src());
    defer zone.end();

    std.debug.print("{}", .{c});
}

/// Add a digit to the string, increment the counter
fn increment(c: *u8) void {
    const zone = Zone(@src());
    defer zone.end();

    c.* += 1;
}

/// Reset the counter and the string
fn reset(c: *u8) void {
    const zone = Zone(@src());
    defer zone.end();

    std.debug.print("\r" ++ " " ** 9 ++ "\r", .{});
    c.* = 1;
}

/// Run the program
pub fn main() !void {
    // Prepare counters (we print digits from 1 to 10)
    var i: u64 = 0;
    var c: u8 = 1;
    // For each iteration
    while (i != 20) : (i += 1) {
        // If we've iterated through all the digits
        if (c == 10) {
            // Reset the string and the counter
            reset(&c);
            // Otherwise,
        } else {
            // Print the current digit
            print(c);
            // Increment the counter
            increment(&c);
        }
        // Sleep for 0.25 seconds
        std.time.sleep(250_000_000);
    }
}
