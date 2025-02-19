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

pub const io = @import("io.zig");
pub const string = @import("string.zig");
pub const ascii = @import("ascii.zig");
pub const log = @import("log.zig");
pub const cli = @import("cli.zig");
pub const virt = @import("virt.zig");
pub const testing = @import("testing.zig");

pub fn assert(cond: bool, comptime reason: ?[]const u8) void {
    if (@inComptime()) {
        if (!cond) @compileError(reason orelse "assertion failed");
    } else {
        if (!cond) {
            @branchHint(.cold);
            @panic(reason orelse "assertion failed");
        }
    }
}

pub fn assume(cond: bool) void {
    if (!cond) unreachable;
}

const std = @import("std");

test {
    _ = io;
    _ = string;
    _ = ascii;
    _ = log;
    _ = cli;
    _ = virt;
    _ = testing;
}
