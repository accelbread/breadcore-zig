// bread-lib -- Common library for Zig programs
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
const Type = std.builtin.Type;

pub const OptionGroup = struct {
    /// Group header
    /// Set to null for no header.
    header: ?[]const u8 = null,
    /// List of options in group
    options: []const Option,
};

pub const Option = struct {
    /// Long name for option
    long: ?[:0]const u8 = null,
    /// Char for short option
    short: ?u8 = null,
    /// If set, option takes a value (non-optional)
    value: ?ArgValue = null,
    /// Documentation string for help messages
    doc: ?[]const u8 = null,
    /// Callback to call when option is found
    /// False return will print help text.
    callback: ?*const fn (
        comptime name: [:0]const u8,
        value: anytype,
    ) bool = null,

    const Self = @This();

    fn result_field(comptime self: Self) Type.StructField {
        const FieldType = ?if (self.value) |value| value.Type else void;
        return .{
            .name = self.long orelse &[1:0]u8{self.short orelse
                @compileError("Option must have long and/or short set.")},
            .type = FieldType,
            .default_value = @ptrCast(&@as(FieldType, null)),
            .is_comptime = false,
            .alignment = @alignOf(FieldType),
        };
    }
};

pub const ArgValue = struct {
    /// Name of value for help text
    name: []const u8,
    /// Type of value
    Type: type = [*:0]u8,
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

    const @"AGPLv3+": @This() = .{
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

pub const ArgParser = struct {
    version_info: VersionInfo,
    help_info: HelpInfo,
    option_groups: []const OptionGroup = &.{},
    /// Whether to move non-option args to the end of argv
    reorder_args: bool = true,
    /// If non-null, expected exact number of non-option args
    non_option_args_count: ?usize = 0,
    /// Minimum number of non-option args
    /// Used if non_option_args_count is null.
    non_option_args_min: ?usize = null,
    /// Callback to call when non-option arg is found
    non_option_callack: ?*const fn (value: []u8) bool = null,

    const Self = @This();

    fn ArgParseResult(comptime self: Self) type {
        return @Type(.{ .Struct = .{
            .layout = .auto,
            .fields = fields: {
                var fields: []const Type.StructField = &.{};
                for (self.option_groups) |group| {
                    for (group.options) |option| {
                        fields = fields ++
                            &[1]Type.StructField{option.result_field()};
                    }
                }
                break :fields fields;
            },
            .decls = &.{},
            .is_tuple = false,
        } });
    }
};

test "Args result" {
    const MyArgs = (ArgParser{
        .version_info = .{
            .name = "Test App",
            .version = "0.0.0",
            .copyright_year = "2024",
            .copyright_holder = "Fake Name <fake_name@example.com>",
            .license_info = LicenseInfo.@"AGPLv3+",
        },
        .help_info = .{},
        .option_groups = &.{.{ .options = &.{
            .{ .long = "test-flag-a", .short = 'a' },
            .{ .long = "test-flag-b", .value = .{ .name = "file" } },
            .{ .short = 'c' },
        } }},
    }).ArgParseResult();

    const args: MyArgs = .{};
    try std.testing.expectEqual(?void, @TypeOf(args.@"test-flag-a"));
    try std.testing.expectEqual(?[*:0]u8, @TypeOf(args.@"test-flag-b"));
    try std.testing.expectEqual(?void, @TypeOf(args.c));
}
