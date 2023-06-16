[![test](https://github.com/PrajwalCH/yazap/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/PrajwalCH/yazap/actions/workflows/test.yml)
[![pages-build-deployment](https://github.com/PrajwalCH/yazap/actions/workflows/pages/pages-build-deployment/badge.svg)](https://github.com/PrajwalCH/yazap/actions/workflows/pages/pages-build-deployment)

# Yazap

> **Note**
> This branch targets the [master branch of zig](https://github.com/ziglang/zig).
> Use [v0.9.x-v0.10.x](https://github.com/PrajwalCH/yazap/tree/v0.9.x-v0.10.x) branch
> if you're using an older versions.

The ultimate [zig](https://ziglang.org) library for seamless command-line parsing.
Effortlessly handle flags, subcommands, and custom arguments with ease.

Inspired by [clap-rs](https://github.com/clap-rs/clap) and [andrewrk/ziglang: src-self-hosted/arg.zig](https://git.sr.ht/~andrewrk/ziglang/tree/725b6ee634f01355da4a6badc5675751b85f0bf0/src-self-hosted/arg.zig)

## Key Features:

- **Options (short and long)**:
  - Providing values with `=`, space, or no space (`-f=value`, `-f value`, `-fvalue`).
  - Supports delimiter-separated values with `=` or without space (`-f=v1,v2,v3`, `-fv1:v2:v3`).
  - Chaining multiple short boolean options (`-abc`).
  - Providing values and delimiter-separated values for multiple chained options using `=` (`-abc=val`, `-abc=v1,v2,v3`).
  - Specifying an option multiple times (`-a 1 -a 2 -a 3`).

- **Positional arguments**:
  - Supports positional arguments alongside options for more flexible command-line inputs. For example:
    - `command <positional_arg>`
    - `command <arg1> <arg2> <arg3>`

- **Nested subcommands**:
  - Organize commands with nested subcommands for a structured command-line interface. For example:
    - `command subcommand`
    - `command subcommand subsubcommand`

- **Automatic help handling and generation**

- **Custom Argument definition**:
  - Define custom [Argument](https://prajwalch.github.io/yazap/#A;lib:Arg) types for specific application requirements.

## Limitations:

- Does not support delimiter-separated values using space (`-f v1,v2,v3`).
- Does not support providing value and comma-separated values for multiple
chained options using space (`-abc value, -abc v1,v2,v3`).

## Installing

Requires [zig v0.11.x](https://ziglang.org)

1. Initialize your project as repository (if not initialized already) by running `git init`.
2. On your root project make a directory named `libs`.
3. Run `git submodule add https://github.com/PrajwalCH/yazap libs/yazap`.
4. After above step is completed add the following code snippet on your `build.zig` file:
    ```zig
    exe.addAnonymousModule("yazap", .{
        .source_file = .{ .path = "libs/yazap/src/lib.zig" },
    });
    ```
5. Now you can import this library on your src file as:
    ```zig
    const yazap = @import("yazap");
    ```
## Docs

Visit [here](https://prajwalch.github.io/yazap/) for complete documentation

## Building and running examples

The examples are present [here](/examples) and to build all of them run:
```bash
$ zig build examples
```
Then after the compilation finishes, you can run them as:
```bash
$ ./zig-out/bin/example_name
```

## Usage

### Initializing the yazap

The first step in using the `yazap` is making an instance of [App](https://prajwalch.github.io/yazap/#A;lib:App)
by calling `App.init(allocator, "Your app name", "optional description")` which internally creates a root command for
your app.

```zig
var app = App.init(allocator, "myls", "My custom ls");
defer app.deinit();
```

### Getting a root command

[App](https://prajwalch.github.io/yazap/#A;lib:App) itself don't provide any methods to add arguments for your command.
Its only purpose is to initialize the library, invoking parser and freeing all the structures.
Therefore, you must have to use root command to add arguments and subcommands.
You can simply get it by calling `App.rootCommand` which returns a pointer to it.

```zig
var myls = app.rootCommand();
```

### Adding arguments

After you get the root command, you can start adding [Argument](https://prajwalch.github.io/yazap/#A;lib:Arg)s using the appropriate methods provided by the `Command`.
See [Command](https://prajwalch.github.io/yazap/#root;Command) to see all the available API.

```zig
try myls.addArg(Arg.positional("FILE", null, null));
try myls.addArg(Arg.booleanOption("all", 'a', "Don't ignore the hidden directories"));
try myls.addArg(Arg.booleanOption("recursive", 'R', "List subdirectories recursively"));
try myls.addArg(Arg.booleanOption("one-line", '1', null));
try myls.addArg(Arg.booleanOption("size", 's', null));
try myls.addArg(Arg.booleanOption("version", null, null));

try myls.addArg(Arg.singleArgumentOption("ignore", 'I', null));
try myls.addArg(Arg.singleArgumentOption("hide", null, null));

try myls.addArg(Arg.singleArgumentOptionWithValidValues("color", 'C', null, &[_][]const u8{
    "always",
    "auto",
    "never",
}));
```

### Adding subcommands

Use `App.createCommand("name", "Subcommand description")` or `App.createCommand("name", null)` to create a subcommand.
Once you create a subcommand, you can add its own arguments and subcommands just like root command.

```zig
var update_cmd = app.createCommand("update", "Update the app or check for new updates");
try update_cmd.addArg(Arg.booleanOption("check-only", null, "Only check for new update"));
try update_cmd.addArg(Arg.singleArgumentOptionWithValidValues("branch", 'b', "Branch to update", &[_][]const u8{ 
    "stable",
    "nightly",
    "beta"
}));

try myls.addSubcommand(update_cmd);
```


### Parsing arguments

Once you're done adding arguments and subcommands call `app.parseProcess` to starts parsing.
It internally calls [`std.process.argsAlloc`](https://ziglang.org/documentation/master/std/#A;std:process.argsAlloc) to
obtain the raw arguments, or you can call `app.parseFrom` by passing your own raw arguments which can be useful on test.
Both functions return a constant pointer to [ArgMatches](https://prajwalch.github.io/yazap/#A;lib:ArgMatches).

```zig
const matches = try app.parseProcess();

if (matches.isPresent("version")) {
    log.info("v0.1.0", .{});
    return;
}

if (matches.valueOf("FILE")) |f| {
    log.info("List contents of {f}");
    return;
}

if (matches.subcommandMatches("update")) |update_cmd_matches| {
    if (update_cmd_matches.isPresent("check-only")) {
        std.log.info("Check and report new update", .{});
        return;
    }

    if (update_cmd_matches.valueOf("branch")) |branch| {
        std.log.info("Branch to update: {s}", .{branch});
        return;
    }
    return;
}

if (matches.isPresent("all")) {
    log.info("show all", .{});
    return;
}

if (matches.isPresent("recursive")) {
    log.info("show recursive", .{});
    return;
}

if (matches.valueOf("ignore")) |pattern| {
    log.info("ignore pattern = {s}", .{pattern});
    return;
}

if (matches.isPresent("color")) {
    const when = matches.valueOf("color").?;

    log.info("color={s}", .{when});
    return;
}
```

### Handling help

Handling `-h` or `--help` and displaying usage is done automatically, but if you want to display help manually, there
are two functions which you can use i.e. `App.displayHelp` and `App.displaySubcommandHelp`.
`displayHelp` is simple it just prints the root level help but the `displaySubcommandHelp` is a bit different,
it queries for the subcommand which was present on the command line and displays its usage.

```zig
if (!matches.hasArgs()) {
    try app.displayHelp();
    return;
}

if (matches.subcommandMatches("update")) |update_cmd_matches| {
    if (!update_cmd_matches.hasArgs()) {
        try app.displaySubcommandHelp();
        return;
    }
}
```

### Putting it all together

```zig
const std = @import("std");
const yazap = @import("yazap");

const allocator = std.heap.page_allocator;
const log = std.log;
const App = yazap.App;
const Arg = yazap.Arg;

pub fn main() anyerror!void {
    var app = App.init(allocator, "myls", "My custom ls");
    defer app.deinit();

    var myls = app.rootCommand();

    var update_cmd = app.createCommand("update", "Update the app or check for new updates");
    try update_cmd.addArg(Arg.booleanOption("check-only", null, "Only check for new update"));
    try update_cmd.addArg(Arg.singleArgumentOptionWithValidValues("branch", 'b', "Branch to update", &[_][]const u8{
        "stable",
        "nightly",
        "beta"
    }));

    try myls.addSubcommand(update_cmd);

    try myls.addArg(Arg.positional("FILE", null, null));
    try myls.addArg(Arg.booleanOption("all", 'a', "Don't ignore the hidden directories"));
    try myls.addArg(Arg.booleanOption("recursive", 'R', "List subdirectories recursively"));
    try myls.addArg(Arg.booleanOption("one-line", '1', null));
    try myls.addArg(Arg.booleanOption("size", 's', null));
    try myls.addArg(Arg.booleanOption("version", null, null));
    try myls.addArg(Arg.singleArgumentOption("ignore", 'I', null));
    try myls.addArg(Arg.singleArgumentOption("hide", null, null));

    try myls.addArg(Arg.singleArgumentOptionWithValidValues("color", 'C', null, &[_][]const u8{
        "always",
        "auto",
        "never",
    }));

    const matches = try app.parseProcess();
    
    if (!matches.hasArgs()) {
        try app.displayHelp();
        return;
    }

    if (matches.isPresent("version")) {
        log.info("v0.1.0", .{});
        return;
    }

    if (matches.valueOf("FILE")) |f| {
        log.info("List contents of {f}");
        return;
    }

    if (matches.subcommandMatches("update")) |update_cmd_matches| {
        if (!update_cmd_matches.hasArgs()) {
            try app.displaySubcommandHelp();
            return;
        }

        if (update_cmd_matches.isPresent("check-only")) {
            std.log.info("Check and report new update", .{});
            return;
        }
        if (update_cmd_matches.valueOf("branch")) |branch| {
            std.log.info("Branch to update: {s}", .{branch});
            return;
        }
        return;
    }

    if (matches.isPresent("all")) {
        log.info("show all", .{});
        return;
    }

    if (matches.isPresent("recursive")) {
        log.info("show recursive", .{});
        return;
    }

    if (matches.valueOf("ignore")) |pattern| {
        log.info("ignore pattern = {s}", .{pattern});
        return;
    }

    if (matches.isPresent("color")) {
        const when = matches.valueOf("color").?;

        log.info("color={s}", .{when});
        return;
    }
}
```

## Alternate Parsers
- [Hejsil/zig-clap](https://github.com/Hejsil/zig-clap) - Simple command line argument parsing library
- [winksaville/zig-parse-args](https://github.com/winksaville/zig-parse-args) - Parse command line arguments
- [MasterQ32/zig-args](https://github.com/MasterQ32/zig-args) - Simple-to-use argument parser with struct-based config

