const Command = @This();

const std = @import("std");
const help = @import("help.zig");
const Arg = @import("Arg.zig");

const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = mem.Allocator;

pub const Property = enum {
    positional_arg_required,
    subcommand_required,
};

allocator: Allocator,
name: []const u8,
description: ?[]const u8,
positional_args: ArrayList(Arg) = .{},
options: ArrayList(Arg) = .{},
subcommands: ArrayList(Command) = .{},
properties: std.EnumSet(Property) = .{},

/// Creates a new instance of it
pub fn init(allocator: Allocator, name: []const u8, description: ?[]const u8) Command {
    return Command{ .allocator = allocator, .name = name, .description = description };
}

/// Release all allocated memory
pub fn deinit(self: *Command) void {
    self.positional_args.deinit(self.allocator);
    self.options.deinit(self.allocator);

    for (self.subcommands.items) |*subcommand| {
        subcommand.deinit();
    }
    self.subcommands.deinit(self.allocator);
}

/// Appends the new arg into the args list
pub fn addArg(self: *Command, new_arg: Arg) !void {
    // Dang!! This is the reason why i love `mut` keyword and variable shadowing from rust.
    var arg = new_arg;
    const is_positional = (arg.short_name == null) and (arg.long_name == null);

    if (!is_positional) {
        return self.options.append(self.allocator, arg);
    }

    if (arg.index != null) {
        return self.positional_args.append(self.allocator, arg);
    }

    // Index is not set but is a first positional arg.
    if (self.positional_args.items.len == 0) {
        arg.setIndex(1);
        return self.positional_args.append(self.allocator, arg);
    }

    // Index is not set and not a first positional arg.
    var highest_index: usize = 1;

    for (self.positional_args.items) |pos_arg| {
        std.debug.assert(pos_arg.index != null);

        if (pos_arg.index.? > highest_index) {
            highest_index = pos_arg.index.?;
        }
    }
    arg.setIndex(highest_index + 1);
    try self.positional_args.append(self.allocator, arg);
}

/// Appends args into the args list
pub fn addArgs(self: *Command, args: []Arg) !void {
    for (args) |arg| try self.addArg(arg);
}

/// Appends the new subcommand into the subcommands list
pub fn addSubcommand(self: *Command, new_subcommand: Command) !void {
    // Add help option for subcommand
    return self.subcommands.append(self.allocator, new_subcommand);
}

/// Appends the `subcommands` into the subcommands list
pub fn addSubcommands(self: *Command, subcommands: []Command) !void {
    for (subcommands) |subcmd| try self.addSubcommand(subcmd);
}

pub fn addProperty(self: *Command, property: Property) void {
    return self.properties.insert(property);
}

pub fn removeProperty(self: *Command, property: Property) void {
    return self.properties.remove(property);
}

pub fn hasProperty(self: *const Command, property: Property) bool {
    return self.properties.contains(property);
}

pub fn countPositionalArgs(self: *const Command) usize {
    return (self.positional_args.items.len);
}

pub fn countOptions(self: *const Command) usize {
    return (self.options.items.len);
}

pub fn countSubcommands(self: *const Command) usize {
    return (self.subcommands.items.len);
}

/// Linearly searches for a postional argument having given index.
pub fn findPositionalArgByIndex(self: *const Command, index: usize) ?*const Arg {
    for (self.positional_args.items) |*pos_arg| {
        std.debug.assert(pos_arg.index != null);

        if (pos_arg.index.? == index) {
            return pos_arg;
        }
    }
    return null;
}

/// Linearly searches for an argument with short name equals to given `short_name`.
/// Returns a const pointer of a found argument otherwise null.
pub fn findShortOption(self: *const Command, short_name: u8) ?*const Arg {
    for (self.options.items) |*arg| {
        if (arg.short_name) |s| {
            if (s == short_name) return arg;
        }
    }
    return null;
}

/// Linearly searches for an argument with long name equals to given `long_name`.
/// Returns a const pointer of a found argument otherwise null.
pub fn findLongOption(self: *const Command, long_name: []const u8) ?*const Arg {
    for (self.options.items) |*arg| {
        if (arg.long_name) |l| {
            if (mem.eql(u8, l, long_name)) return arg;
        }
    }
    return null;
}

/// Linearly searches a sub-command with name equals to given `subcmd_name`.
/// Returns a const pointer of a found sub-command otherwise null.
pub fn findSubcommand(self: *const Command, provided_subcmd: []const u8) ?*const Command {
    for (self.subcommands.items) |*subcmd| {
        if (std.mem.eql(u8, subcmd.name, provided_subcmd)) {
            return subcmd;
        }
    }

    return null;
}
