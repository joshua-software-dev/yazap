//! Help message writer
const Help = @This();

const std = @import("std");
const Command = @import("Command.zig");
const Braces = std.meta.Tuple(&[2]type{ u8, u8 });

pub const Options = struct {
    include_args: bool = false,
    include_subcmds: bool = false,
    include_flags: bool = false,
};

cmd: *const Command,
options: Options,

pub fn init(cmd: *const Command, opt: Options) Help {
    return Help{ .cmd = cmd, .options = opt };
}

// Help message is divided into 3 sections:  Header, Commands and Options.
// For each section there is a seperate functions for writing contents of them.
//
//  _________________________
// /                         \
// | Usage: <cmd name> ...   |
// |                         |
// | DESCRIPTION:            |
// | ...                     |
// |_________________________|
// |                         |
// | COMMANDS:               |
// | ...                     |
// |_________________________|
// |                         |
// | OPTIONS:                |
// | ...                     |
// \_________________________/

pub fn writeAll(self: *Help) !void {
    var buffer = std.io.bufferedWriter(std.io.getStdOut().writer());
    var writer = buffer.writer();

    try self.writeHeader(writer);
    try self.writeCommands(writer);
    try self.writeOptions(writer);

    if (self.options.include_subcmds) {
        try writer.writeAll(
            \\ 
            \\Note:
            \\ Use cmd -h or --help to get help for specific command
            \\
        );
    }
    try buffer.flush();
}

fn writeHeader(self: *Help, writer: anytype) !void {
    try writer.print("Usage: {s} ", .{self.cmd.name});

    if (self.options.include_args) {
        const braces = getBraces(self.cmd.setting.arg_required);

        for (self.cmd.args.items) |arg| {
            if ((arg.short_name == null) and (arg.long_name == null)) {
                try writer.print("{c}{s}{c} ", .{ braces.@"0", arg.name, braces.@"1" });
            }
        }
    }

    if (self.options.include_flags) try writer.writeAll("[OPTIONS] ");

    if (self.cmd.countSubcommands() >= 1) {
        self.options.include_subcmds = true;
        const braces = getBraces(self.cmd.setting.subcommand_required);

        try writer.print("{c}COMMAND{c}\n", .{ braces.@"0", braces.@"1" });
    }

    if (self.cmd.description) |des| {
        try writer.writeAll("\nDescription:\n");
        try writer.print(" {s}\n", .{des});
    }
    try writer.writeAll("\n");
}

fn getBraces(required: bool) Braces {
    return if (required) .{ '<', '>' } else .{ '[', ']' };
}

fn writeCommands(self: *Help, writer: anytype) !void {
    if (!(self.options.include_subcmds)) return;

    try writer.writeAll("Commands:\n");

    for (self.cmd.subcommands.items) |subcmd| {
        try writer.print(" {s}\t", .{subcmd.name});
        if (subcmd.description) |d| try writer.print("{s}", .{d});
        try writer.writeAll("\n");
    }
    try writer.writeAll("\n");
}

fn writeOptions(self: *Help, writer: anytype) !void {
    if (self.options.include_flags) {
        try writer.writeAll("Options:\n");

        for (self.cmd.args.items) |arg| {
            if ((arg.short_name == null) and (arg.long_name == null)) continue;

            if (arg.short_name) |short_name|
                try writer.print(" -{c},", .{short_name});
            if (arg.long_name) |long_name|
                try writer.print(" --{s} ", .{long_name});

            if (arg.settings.takes_value) {
                // TODO: Add new `Arg.placeholderName()` to display proper placeholder

                // Required options: <A | B | C>
                if (arg.allowed_values) |values| {
                    try writer.writeByte('<');

                    for (values) |value, idx| {
                        try writer.print("{s}", .{value});

                        // Only print '|' till second last option
                        if (idx < (values.len - 1)) {
                            try writer.writeAll(" | ");
                        }
                    }
                    try writer.writeByte('>');
                } else {
                    // TODO: Find a better way to make UPPERCASE
                    var buff: [100]u8 = undefined;
                    try writer.print("<{s}>", .{std.ascii.upperString(&buff, arg.name)});
                }
            }

            if (arg.description) |des_txt| {
                try writer.print("\n\t{s}\n", .{des_txt});
            }
            try writer.writeAll("\n");
        }
    }
    try writer.writeAll(" -h, --help\n\tPrint this help and exit\n");
}
