//! Represents the argument for your command.

const Arg = @This();
const std = @import("std");

const DEFAULT_VALUES_DELIMITER = ",";

pub const Property = enum {
    takes_value,
    takes_multiple_values,
    allow_empty_value,
};

name: []const u8,
description: ?[]const u8,
short_name: ?u8 = null,
long_name: ?[]const u8 = null,
min_values: ?usize = null,
max_values: ?usize = null,
valid_values: ?[]const []const u8 = null,
values_delimiter: ?[]const u8 = null,
index: ?usize = null,
properties: std.EnumSet(Property) = .{},

// # Constructors

/// Creates a new instance of it
pub fn init(name: []const u8, description: ?[]const u8) Arg {
    return Arg{ .name = name, .description = description };
}

/// Creates a boolean option.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
/// try root.addArg(Arg.booleanOption("version", 'v', "Show version number"));
/// ```
pub fn booleanOption(name: []const u8, short_name: ?u8, description: ?[]const u8) Arg {
    var arg = Arg.init(name, description);

    if (short_name) |n| {
        arg.setShortName(n);
    }
    arg.setLongName(name);
    return arg;
}

/// Creates a single argument option.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
/// try root.addArg(Arg.singleArgumentOption("port", 'p', "Port number to bind"));
/// ```
pub fn singleArgumentOption(name: []const u8, short_name: ?u8, description: ?[]const u8) Arg {
    var arg = Arg.init(name, description);

    if (short_name) |n| {
        arg.setShortName(n);
    }
    arg.setLongName(name);
    arg.addProperty(.takes_value);
    return arg;
}

/// Creates a single argument option with valid values which user can pass.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
/// try root.addArg(Arg.singleArgumentOptionWithValidValues(
///     "std", 's', "Language standard", &[_]const u8 { "c99", "c11" },
/// ));
/// ```
pub fn singleArgumentOptionWithValidValues(
    name: []const u8,
    short_name: ?u8,
    description: ?[]const u8,
    values: []const []const u8,
) Arg {
    var arg = Arg.singleArgumentOption(name, short_name, description);
    arg.setValidValues(values);
    return arg;
}

/// Creates a multi arguments option.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
/// try root.addArg(Arg.multiArgumentsOption("nums", 'n', "Numbers to add", 2));
/// ```
pub fn multiArgumentsOption(
    name: []const u8,
    short_name: ?u8,
    description: ?[]const u8,
    max_values: usize,
) Arg {
    var arg = Arg.init(name, description);

    if (short_name) |n| {
        arg.setShortName(n);
    }
    arg.setLongName(name);
    arg.setMinValues(1);
    arg.setMaxValues(max_values);
    arg.setDefaultValuesDelimiter();
    arg.addProperty(.takes_value);
    return arg;
}

/// Creates a multi arguments option with valid values which user can pass.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
/// try root.addArg(Arg.multiArgumentsOptionWithValidValues(
///     "distros", 'd', "Two Fav Distros", 2, &[_]const u8 { "debian", "ubuntu", "arch" },
/// ));
/// ```
pub fn multiArgumentsOptionWithValidValues(
    name: []const u8,
    short_name: ?u8,
    description: ?[]const u8,
    max_values: usize,
    values: []const []const u8,
) Arg {
    var arg = Arg.multiArgumentsOption(name, short_name, description, max_values);
    arg.setValidValues(values);
    return arg;
}

/// Creates a positional argument.
/// The index represents the position of your argument starting from **1**.
///
/// NOTE: Index is optional so by default it will be assigned in order of evalution.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// // Order dependent
/// try root.addArg(Arg.positional("FIRST", null, null));
/// try root.addArg(Arg.positional("SECOND", null, null));
/// try root.addArg(Arg.positional("THIRD", null, null));
///
/// // Equivalent but order independent
/// try root.addArg(Arg.positional("THIRD", null, 3));
/// try root.addArg(Arg.positional("SECOND", null, 2));
/// try root.addArg(Arg.positional("FIRST", null, 1));
/// ```
pub fn positional(name: []const u8, description: ?[]const u8, index: ?usize) Arg {
    var arg = Arg.init(name, description);

    if (index) |i| {
        arg.setIndex(i);
    }
    arg.addProperty(.takes_value);
    return arg;
}

// # Setters

/// Sets the short name of the argument.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var port = Arg.init("port", "Port number to bind");
/// port.setShortName('p');
/// port.addProperty(.takes_value);
///
/// // Equivalent except `singleArgumentOption` sets long name too.
/// var port = Arg.singleArgumentOption("port", 'p', "Port number to bind");
///
/// try root.addArg(port);
/// ```
pub fn setShortName(self: *Arg, short_name: u8) void {
    self.short_name = short_name;
}

/// Sets the long name of the argument.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var port = Arg.init("port", "Port number to bind");
/// port.setLongName('p');
/// port.addProperty(.takes_value);
///
/// // Equivalent
/// var port = Arg.singleArgumentOption("port", null, "Port number to bind");
///
/// try root.addArg(port);
/// ```
pub fn setLongName(self: *Arg, long_name: []const u8) void {
    self.long_name = long_name;
}

/// Sets the minimum number of values required to provide for an argument.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var nums = Arg.init("nums", "Numbers to add");
/// nums.setShortName("n");
/// nums.setMinValues(2);
/// nums.addProperty(.takes_value);
///
/// try root.addArg(nums);
/// ```
pub fn setMinValues(self: *Arg, num: usize) void {
    self.min_values = if (num >= 1) num else null;
}

/// Sets the maximum number of values an argument can take.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var nums = Arg.init("nums", "Numbers to add");
/// nums.setShortName("n");
/// nums.setLongName("nums");
/// nums.setMinValues(2);
/// nums.setMaxValues(5);
/// nums.addProperty(.takes_value);
///
/// try root.addArg(nums);
/// ```
pub fn setMaxValues(self: *Arg, num: usize) void {
    self.max_values = if (num >= 1) num else null;
}

/// Sets the valid values for an argument.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var distros = Arg.init("distros", "Two Fav Distros");
/// distros.setShortName('d');
/// distros.setLongName("distros");
/// distros.setMinValues(1);
/// distros.setMaxValues(2);
/// distros.setValidValues(&[_][]const u8{
///     "debian",
///     "ubuntu",
///     "arch",
/// });
/// distros.addProperty(.takes_value);
///
/// // Equivalent
/// var distros = Arg.multiArgumentsOptionWithValidValues(
///     "distros", 'd', "Two Fav Distros", 2, &[_]const u8 { "debian", "ubuntu", "arch" },
/// );
///
/// try root.addArg(distros);
/// ```
pub fn setValidValues(self: *Arg, values: []const []const u8) void {
    self.valid_values = values;
}

/// Sets the default separator between the values of an argument.
/// Use `Arg.setValuesDelimiter` if you want to set custom delimiter.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var nums = Arg.init("nums", "Numbers to add");
/// nums.setShortName("n");
/// nums.setLongName("nums");
/// nums.setMinValues(2);
/// nums.setDefaultValuesDelimiter();
/// nums.addProperty(.takes_value);
///
/// try root.addArg(nums);
///
/// // From command line: myapp --nums 1,2
/// ```
pub fn setDefaultValuesDelimiter(self: *Arg) void {
    self.setValuesDelimiter(DEFAULT_VALUES_DELIMITER);
}

/// Sets separator between the values of an argument.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var nums = Arg.init("nums", "Numbers to add");
/// nums.setShortName("n");
/// nums.setLongName("nums");
/// nums.setMinValues(2);
/// nums.setValuesDelimiter(":");
/// nums.addProperty(.takes_value);
///
/// try root.addArg(nums);
///
/// // From command line: myapp --nums 1:2
/// ```
pub fn setValuesDelimiter(self: *Arg, delimiter: []const u8) void {
    self.values_delimiter = delimiter;
}

/// Sets the index of a positional argument starting with **1**.
/// It is optional so by default it will be assigned based on order of defining argument.
///
/// Note: Setting index for options will not take any effect and it will be sliently ignored.
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var second = Arg.init("SECOND", "Second positional arg");
/// second.setIndex(2);
/// second.addProperty(.takes_value);
///
/// // Equivalent
/// var second = Arg.positional("SECOND", "Second positional arg", 2);
///
/// var first = Arg.init("FIRST", "First positional arg");
/// first.setIndex(1);
/// first.addProperty(.takes_value);
///
/// // Equivalent
/// var first = Arg.positional("FIRST", "First positional arg", 2);
///
/// // No effect on this
/// var option = Arg.singleArgumentOption("option", 'o', "Some description");
/// option.setIndex(3);
///
/// try root.addArg(first);
/// try root.addArg(second);
/// try root.addArg(option);
///
/// // From command line:
/// //  myapp firstvalue secondvalue
/// //  myapp firstvalue secondvalue --option optionvalue
/// //  myapp --option optionvalue firstvalue secondvalue
/// ```
pub fn setIndex(self: *Arg, index: usize) void {
    self.index = index;
}

/// Adds a property to the argument, specifying how it should be parsed and processed.
///
/// ## Examples
///
/// Setting a property to indicate that the argument takes a value from the command line:
///
/// ```zig
/// var app = App.init(allocator, "myapp", "My app description");
/// defer app.deinit();
///
/// var root = app.rootCommand();
///
/// var name = Arg.init("name", "Person to greet");
/// name.setShortName('n');
/// name.addProperty(.takes_value);
///
/// try root.addArg(name);
///
/// // Command line input: myapp -n foo
/// ```
pub fn addProperty(self: *Arg, property: Property) void {
    return self.properties.insert(property);
}

pub fn removeProperty(self: *Arg, property: Property) void {
    return self.properties.remove(property);
}

// # Getters

pub fn hasProperty(self: *const Arg, property: Property) bool {
    return self.properties.contains(property);
}

pub fn isValidValue(self: *const Arg, value_to_check: []const u8) bool {
    if (self.valid_values) |values| {
        for (values) |value| {
            if (std.mem.eql(u8, value, value_to_check)) return true;
        }
        return false;
    }
    return true;
}
