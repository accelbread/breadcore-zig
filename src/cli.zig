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
const Type = std.builtin.Type;

pub const OptionGroup = struct {
    /// Group header
    /// Set to null for no header.
    header: ?[]const u8 = null,
    /// List of options in group
    options: []const Option,
};

pub const Option = struct {
    /// Identifier for option
    id: @Type(.enum_literal),
    /// Long name for option
    long: ?[]const u8 = null,
    /// Char for short option
    short: ?u8 = null,
    /// If set, option takes a value (non-optional)
    /// Value of field is the name of value for help text
    value: ?[]const u8 = null,
    /// Documentation string for help messages
    doc: ?[]const u8 = null,
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
    help_info: HelpInfo = .{},
    option_groups: []const OptionGroup = &.{},
    /// Callback to call when option arg is found
    option_handler: ?*const fn (
        comptime option: @Type(.enum_literal),
        value: ?[:0]u8,
    ) anyerror!void = null,
    /// Callback to call when non-option arg is found
    /// If set to all, non-option args are moved to the end of argv
    non_option_handler: ?union {
        each: *const fn (each: [:0]u8) anyerror!void,
        all: *const fn (args: [][*:0]u8) anyerror!void,
    } = null,
};

test "Args result" {
    const MyArgs = ArgParser{
        .version_info = .{
            .name = "Test App",
            .version = "0.0.0",
            .copyright_year = "2024",
            .copyright_holder = "Fake Name <fake_name@example.com>",
            .license_info = LicenseInfo.@"AGPLv3+",
        },
        .help_info = .{},
        .option_groups = &.{.{ .options = &.{
            .{ .id = .flag_a, .long = "test-flag-a", .short = 'a' },
            .{ .id = .flag_b, .long = "test-flag-b", .value = "file" },
            .{ .id = .c, .short = 'c' },
        } }},
    };
    _ = &MyArgs;
}
