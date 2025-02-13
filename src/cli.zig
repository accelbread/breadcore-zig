// breadcore -- General-purpose utility library
// Copyright (C) 2024 Archit Gupta <archit@accelbread.com>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License as published by the Free
// Software Foundation, either version 3 of the License, or (at your option) any
// later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
// details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: AGPL-3.0-or-later

const std = @import("std");
const core = @import("root.zig");
const string = core.string;
const ascii = core.ascii;

pub const OptionEntry = union(enum) {
    const Option = struct {
        /// Identifier for option
        id: @Type(.enum_literal),
        /// Long name for option
        long: []const u8,
        /// Char for short option
        short: ?u7 = null,
        /// If set, option takes a value (non-optional)
        /// Value of field is the name of value for help text
        value: ?[]const u8 = null,
        /// Documentation string for help messages
        doc: []const u8,
    };

    const GroupHeader = struct {
        /// Set to null for no header.
        header: []const u8,
    };

    option: Option,
    group_header: GroupHeader,

    pub fn opt(
        id: @Type(.enum_literal),
        short: ?u7,
        value: ?[]const u8,
        doc: []const u8,
    ) OptionEntry {
        const flag_name = name: {
            var name: [@tagName(id).len]u8 = @tagName(id).*;
            for (&name) |*c| {
                if (c.* == '_') {
                    c.* = '-';
                }
            }
            break :name name;
        };

        return .{ .option = .{
            .id = id,
            .long = &flag_name,
            .short = short,
            .value = value,
            .doc = doc,
        } };
    }

    pub fn header(name: []const u8) OptionEntry {
        return .{ .group_header = .{ .header = name } };
    }
};

pub const VersionInfo = struct {
    /// Canonical name for the program (not file name)
    name: []const u8,
    /// Package name if program is part of a larger package
    package: ?[]const u8 = null,
    /// Version of the program
    version: []const u8,
    /// Year for version text copyright string
    copyright_year: []const u8,
    /// Copyright holder info for version text copyright string
    copyright_holder: []const u8,
    /// License info
    license_info: LicenseInfo,
};

pub const LicenseInfo = struct {
    /// Short form of license name
    abbrev: []const u8,
    /// Longer form of license name to put after colon
    full_name: ?[]const u8,
    /// URL to license
    link: ?[]const u8,
    /// Text to include after license statement
    extra_text: ?[]const u8,

    pub const @"AGPLv3+": LicenseInfo = .{
        .abbrev = "AGPLv3+",
        .full_name = "GNU AGPL version 3 or later",
        .link = "https://gnu.org/licenses/agpl.html",
        .extra_text =
        \\This is free software: you are free to change and redistribute it.
        \\There is NO WARRANTY, to the extent permitted by law.
        \\
        ,
    };
};

pub const HelpInfo = struct {
    /// Override part of usage string after binary name
    usage: ?[]u8 = null,
    /// Extra text to put in --help output
    help_text: ?[]u8 = null,
    /// Email address for bug reports
    bug_report_address: ?[]u8 = null,
    /// Project home page
    home_page: ?[]u8 = null,
};

const ArgType = enum {
    short_options,
    long_option,
    non_option,
    option_terminator,
};

fn getArgType(arg: [:0]const u8) ArgType {
    if ((arg.len <= 1) or (arg[0] != '-')) {
        return .non_option;
    }
    if (arg[1] != '-') {
        return .short_options;
    }
    if (arg.len == 2) {
        return .option_terminator;
    }
    return .long_option;
}

test getArgType {
    try std.testing.expectEqual(ArgType.non_option, getArgType("hello"));
    try std.testing.expectEqual(ArgType.short_options, getArgType("-abc"));
    try std.testing.expectEqual(ArgType.long_option, getArgType("--world"));
    try std.testing.expectEqual(ArgType.option_terminator, getArgType("--"));
}

fn rotateSlice(T: type, slice: []T) void {
    const last: T = slice[slice.len - 1];
    std.mem.copyBackwards(T, slice[1..slice.len], slice[0 .. slice.len - 1]);
    slice[0] = last;
}

test rotateSlice {
    var input = [_]u8{ 1, 2, 3, 4, 5 };
    const expected = [_]u8{ 5, 1, 2, 3, 4 };
    rotateSlice(u8, &input);
    try std.testing.expectEqualSlices(u8, &expected, &input);
}

pub const ArgParserConfig = struct {
    HandlerCtx: type = void,
    HandlerError: type = anyerror,
    reorder: bool = true,

    fn handler(Ctx: type, Error: type) @This() {
        return .{ .HandlerCtx = Ctx, .HandlerError = Error };
    }
};

pub fn ArgParser(
    config: ArgParserConfig,
) type {
    return struct {
        const HandlerCtx = config.HandlerCtx;
        const HandlerError = config.HandlerError;

        const NonOptionHandler = if (config.reorder)
            fn (ctx: HandlerCtx, args: [][*:0]const u8) HandlerError!void
        else
            fn (ctx: HandlerCtx, arg: [:0]const u8) HandlerError!void;

        version_info: ?VersionInfo = null,
        help_info: HelpInfo = .{},
        options: []const OptionEntry = &.{},

        /// Callback to call when option arg is found
        option_handler: ?fn (
            ctx: HandlerCtx,
            comptime option: @Type(.enum_literal),
            value: ?[:0]const u8,
        ) HandlerError!void = null,

        /// Callback to call for non-option args
        /// If set to reorder, non-option args are moved to the end of argv and
        /// the callback is called once.
        /// If not reordering, this is called for each non-option arg
        /// encountered.
        non_option_handler: ?NonOptionHandler = null,

        pub fn validate(comptime self: @This()) void {
            if (self.options.len > 0) {
                core.assert(
                    self.option_handler != null,
                    "option_handler must be specified",
                );
            }

            for (self.options) |entry| {
                if (entry == .option) {
                    if (entry.option.short) |c| {
                        core.assert(
                            ascii.isAlphaNum(c),
                            "short options must be alphanumeric",
                        );
                    }
                }
            }
        }

        inline fn shouldReorder(comptime self: @This()) bool {
            return config.reorder and (self.non_option_handler != null);
        }

        fn ParseState(comptime self: @This()) type {
            return struct {
                argv: [][*:0]const u8,
                idx: usize = 0,
                prev_non_opts: if (self.shouldReorder()) usize else void =
                    if (self.shouldReorder()) 0 else {},

                fn maybeRotateArgs(state: *@This()) void {
                    if (self.shouldReorder()) {
                        core.assume(state.idx < state.argv.len);

                        if (state.prev_non_opts > 0) {
                            const start = state.idx - state.prev_non_opts;
                            const end = state.idx + 1;
                            rotateSlice([*:0]const u8, state.argv[start..end]);
                        }
                    }
                }

                fn nextArg(state: *@This()) ?[*:0]const u8 {
                    return if (state.idx < state.argv.len - 1)
                        state.argv[state.idx + 1]
                    else
                        null;
                }
            };
        }

        fn handleNonOption(
            comptime self: @This(),
            state: *self.ParseState(),
            ctx: HandlerCtx,
            arg: [:0]const u8,
        ) !void {
            if (self.non_option_handler) |handler| {
                if (config.reorder) {
                    state.prev_non_opts += 1;
                } else {
                    handler(ctx, arg);
                }
            } else {
                return error.InvalidArg;
            }
        }

        fn handleOptionTerminator(
            comptime self: @This(),
            state: *self.ParseState(),
            ctx: HandlerCtx,
        ) !void {
            core.assume(state.idx < state.argv.len);

            const rest = state.argv[state.idx + 1 ..];

            if (rest.len > 0) {
                if (self.non_option_handler) |handler| {
                    state.idx = state.argv.len - 1;
                    if (config.reorder) {
                        state.prev_non_opts += rest.len;
                    } else for (rest) |a| {
                        handler(ctx, std.mem.span(a));
                    }
                } else {
                    return error.InvalidArg;
                }
            }
        }

        fn handleLongOpt(
            comptime self: @This(),
            state: *self.ParseState(),
            ctx: HandlerCtx,
            opt: []const u8,
            value: ?[:0]const u8,
        ) !void {
            core.assume(state.idx < state.argv.len);

            const next = state.nextArg();
            var used_next = false;

            try self.dispatchOpt(.long, ctx, opt, value, next, &used_next);

            if (used_next) {
                state.idx += 1;
                state.maybeRotateArgs();
            }
        }

        fn handleShortOpts(
            comptime self: @This(),
            state: *self.ParseState(),
            ctx: HandlerCtx,
            opts: []const u8,
            value: ?[:0]const u8,
        ) !void {
            core.assume(state.idx < state.argv.len);
            core.assume(opts.len >= 1);

            var rest = opts;

            while (rest.len > 1) {
                const s = rest[0];
                rest = rest[1..];

                var next: ?[*:0]const u8 = null;
                if (value == null) {
                    next = @as([:0]const u8, @ptrCast(rest));
                }
                var used_next = false;

                try self.dispatchOpt(.short, ctx, s, value, next, &used_next);

                if (used_next) {
                    return;
                }
            }

            const s = rest[0];
            const next = state.nextArg();
            var used_next = false;

            try self.dispatchOpt(.short, ctx, s, value, next, &used_next);

            if (used_next) {
                state.idx += 1;
                state.maybeRotateArgs();
            }
        }

        fn dispatchOpt(
            comptime self: @This(),
            comptime t: enum { long, short },
            ctx: HandlerCtx,
            opt: if (t == .long) []const u8 else u8,
            value: ?[:0]const u8,
            next: ?[*:0]const u8,
            used_next: *bool,
        ) !void {
            inline for (self.options) |entry| {
                if (entry == .option) {
                    const e = comptime entry.option;
                    const matches = match: {
                        if (t == .long) {
                            break :match string.equal(e.long, opt);
                        } else if (e.short) |s| {
                            break :match s == opt;
                        } else {
                            break :match false;
                        }
                    };
                    if (matches) {
                        if (e.value == null) {
                            if (value == null) {
                                return self.option_handler.?(ctx, e.id, null);
                            } else {
                                return error.InvalidOptionValue;
                            }
                        } else {
                            if (value) |v| {
                                return self.option_handler.?(ctx, e.id, v);
                            } else if (next) |n| {
                                used_next.* = true;
                                const v = std.mem.span(n);
                                return self.option_handler.?(ctx, e.id, v);
                            } else {
                                return error.MissingOptionValue;
                            }
                        }
                    }
                }
            }
            return error.InvalidOption;
        }

        fn handleCurrentArg(
            comptime self: @This(),
            state: *self.ParseState(),
            ctx: HandlerCtx,
        ) !void {
            core.assume(state.idx < state.argv.len);

            const arg: [:0]const u8 = std.mem.span(state.argv[state.idx]);
            const arg_type = getArgType(arg);

            if (arg_type == .non_option) {
                return self.handleNonOption(state, ctx, arg);
            }

            state.maybeRotateArgs();

            if (arg_type == .option_terminator) {
                return self.handleOptionTerminator(state, ctx);
            }

            const opt: []const u8, const value: ?[:0]const u8 = split: {
                const post_dash = switch (arg_type) {
                    .long_option => arg[2..],
                    .short_options => arg[1..],
                    else => unreachable,
                };

                for (post_dash[1..], 1..) |c, i| {
                    if (c == '=') {
                        break :split .{ post_dash[0..i], post_dash[i + 1 ..] };
                    }
                }
                break :split .{ post_dash, null };
            };

            return switch (arg_type) {
                .long_option => self.handleLongOpt(state, ctx, opt, value),
                .short_options => self.handleShortOpts(state, ctx, opt, value),
                else => unreachable,
            };
        }

        pub fn parseArgs(
            comptime self: @This(),
            argv: [][*:0]const u8,
            ctx: HandlerCtx,
        ) !void {
            comptime self.validate();

            var state: self.ParseState() = .{ .argv = argv };
            while (state.idx < argv.len) : (state.idx += 1) {
                try self.handleCurrentArg(&state, ctx);
            }

            if (config.reorder) {
                if (self.non_option_handler) |handler| {
                    try handler(ctx, argv[argv.len - state.prev_non_opts ..]);
                }
            }
        }
    };
}

test ArgParser {
    const Settings = struct {
        a: bool = false,
        b: ?[]const u8 = null,
        arg_count: u16 = 0,
    };

    const Handlers = struct {
        fn option_handler(
            ctx: *Settings,
            comptime option: @Type(.enum_literal),
            value: ?[:0]const u8,
        ) error{}!void {
            switch (option) {
                .flag_a => {
                    ctx.a = true;
                },
                .flag_b => {
                    ctx.b = value.?;
                },
                else => unreachable,
            }
        }
        fn non_option_handler(
            ctx: *Settings,
            args: [][*:0]const u8,
        ) error{}!void {
            for (args) |_| {
                ctx.arg_count += 1;
            }
        }
    };

    const MyArgs = ArgParser(.handler(*Settings, error{})){
        .options = &.{
            .opt(.flag_a, 'a', null, ""),
            .opt(.flag_b, null, "thing", ""),
        },
        .option_handler = Handlers.option_handler,
        .non_option_handler = Handlers.non_option_handler,
    };

    // args will likely be `std.os.argv`
    var args = [_][*:0]const u8{ "-a", "hello", "--flag-b", "meow" };
    var settings: Settings = .{};

    const expected = [_][*:0]const u8{ args[0], args[2], args[3], args[1] };

    try MyArgs.parseArgs(&args, &settings);

    try std.testing.expectEqualSlices([*:0]const u8, &expected, &args);
}

test {
    _ = @import("cli_tests.zig");
}
