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

pub fn logFn(
    comptime level: std.log.Level,
    comptime scope: @TypeOf(.EnumLiteral),
    comptime format: []const u8,
    args: anytype,
) void {
    const fmt_str = comptime str: {
        const color = switch (level) {
            .err => "\x1B[1;31m",
            .warn => "\x1B[1;33m",
            else => "\x1B[0;34m",
        };
        const level_id = switch (level) {
            .err => "E",
            .warn => "W",
            .info => "I",
            .debug => "D",
        };
        const tag =
            if (scope == .default) "" else "[" ++ @tagName(scope) ++ "]";

        const prefix = color ++ level_id ++ tag ++ " ";

        break :str prefix ++ format ++ "\x1B[0m\n";
    };

    const stderr = std.io.getStdErr().writer();
    var bw = std.io.bufferedWriter(stderr);
    const writer = bw.writer();

    std.debug.lockStdErr();
    defer std.debug.unlockStdErr();

    writer.print(fmt_str, args) catch return;
    bw.flush() catch return;
}
