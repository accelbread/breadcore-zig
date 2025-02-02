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

pub fn Reader(readFn: anytype) type {
    const fn_info = @typeInfo(@TypeOf(readFn)).@"fn";
    const fn_ret_info = @typeInfo(fn_info.return_type.?);

    const ReadError = fn_ret_info.error_union.error_set;
    const Ctx = fn_info.params[0].type.?;

    return struct {
        ctx: Ctx,

        const Self = @This();

        pub fn new(ctx: Ctx) Self {
            return .{ .ctx = ctx };
        }

        pub inline fn read(self: Self, buf: []u8) ReadError!usize {
            return readFn(self.ctx, buf);
        }

        pub fn readFull(self: Self, buf: []u8) ReadError!usize {
            var rest: []u8 = buf;
            while (rest.len > 0) {
                const read_amt = try self.read(buf);
                if (read_amt == 0) {
                    return buf.len - rest.len;
                }
                rest = rest[read_amt..];
            }
            return buf.len;
        }

        pub fn readExact(
            self: Self,
            buf: []u8,
        ) (ReadError || error{UnexpectedEof})!void {
            const read_amt = try self.readFull(buf);
            if (read_amt != buf.len) {
                return error.UnexpectedEof;
            }
        }

        pub fn dyn(self: *const Self) DynReader {
            if (Self == DynReader) {
                return self.*;
            }
            return .new(Vtable{
                .read_impl = virtualRead,
                .ctx = virt.packUsizeCtx(Ctx, &self.ctx),
            });
        }

        fn virtualRead(ctx: usize, buf: []u8) anyerror!usize {
            return readFn(virt.unpackUsizeCtx(Ctx, ctx), buf);
        }
    };
}

const Vtable = packed struct {
    read_impl: *const fn (ctx: usize, buf: []u8) anyerror!usize,
    ctx: usize,

    inline fn read(self: Vtable, buf: []u8) anyerror!usize {
        return self.read_impl(self.ctx, buf);
    }
};

pub const DynReader = Reader(Vtable.read);
