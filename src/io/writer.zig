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
const virt = @import("../virt.zig");

pub fn Writer(writeFn: anytype) type {
    const fn_info = @typeInfo(@TypeOf(writeFn)).@"fn";
    const fn_ret_info = @typeInfo(fn_info.return_type.?);

    const WriteError = fn_ret_info.error_union.error_set;
    const Ctx = fn_info.params[0].type.?;

    return struct {
        ctx: Ctx,

        const Self = @This();

        pub fn new(ctx: Ctx) Self {
            return .{ .ctx = ctx };
        }

        pub inline fn write(self: Self, buf: []const u8) WriteError!usize {
            return writeFn(self.ctx, buf);
        }

        pub fn writeFull(self: Self, buf: []const u8) WriteError!void {
            var rest: []const u8 = buf;
            while (rest.len > 0) {
                const write_amt = try self.write(buf);
                rest = rest[write_amt..];
            }
        }

        pub fn dyn(self: *const Self) DynWriter {
            if (Self == DynWriter) {
                return self.*;
            }
            return .new(Vtable{
                .write_impl = virtualWrite,
                .ctx = virt.packUsizeCtx(Ctx, &self.ctx),
            });
        }

        fn virtualWrite(ctx: usize, buf: []const u8) anyerror!usize {
            return writeFn(virt.unpackUsizeCtx(Ctx, ctx), buf);
        }
    };
}

const Vtable = packed struct {
    write_impl: *const fn (ctx: usize, buf: []const u8) anyerror!usize,
    ctx: usize,

    inline fn write(self: Vtable, buf: []const u8) anyerror!usize {
        return self.write_impl(self.ctx, buf);
    }
};

pub const DynWriter = Writer(Vtable.write);
