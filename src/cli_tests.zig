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
const cli = @import("cli.zig");
const EnumLiteral = @Type(.enum_literal);

const TestArgsMin = cli.ArgParser(void, anyerror){
    .options = &.{
        .opt(.flag_a, null, null, ""),
        .opt(.flag_b, null, "file", ""),
        .opt(.flag_c, 'c', null, ""),
        .header("section a"),
        .opt(.flag_d, 'd', null, ""),
    },
    .option_handler = struct {
        fn option_handler(
            ctx: void,
            comptime option: EnumLiteral,
            value: ?[:0]const u8,
        ) anyerror!void {
            _ = option;
            _ = ctx;
            _ = value;
        }
    }.option_handler,
};

test "Minimal happy path" {
    var args = [_][*:0]const u8{ "--flag-b", "--flag-a", "-c", "-d" };
    try TestArgsMin.parseArgs(&args, {});
}

const TestArgsVersion = cli.ArgParser(void, anyerror){
    .version_info = .{
        .name = "Test App",
        .version = "0.0.0",
        .copyright_year = "2024",
        .copyright_holder = "Fake Name <fake_name@example.com>",
        .license_info = .@"AGPLv3+",
    },
    .help_info = .{},
    .options = &.{
        .opt(.flag_a, 'a', null, ""),
        .opt(.flag_b, 'b', "file", ""),
        .opt(.flag_c, null, null, ""),
        .header("section a"),
        .opt(.flag_d, null, null, ""),
    },
    .option_handler = struct {
        fn option_handler(
            ctx: void,
            comptime option: EnumLiteral,
            value: ?[:0]const u8,
        ) anyerror!void {
            _ = option;
            _ = ctx;
            _ = value;
        }
    }.option_handler,
};
