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

fn IntType(T: type) type {
    return @Type(.{ .int = .{
        .signedness = .unsigned,
        .bits = @sizeOf(T) * 8,
    } });
}

pub fn pack_usize_ctx(RealType: type, ref: *const RealType) usize {
    if (@sizeOf(RealType) <= @sizeOf(usize)) {
        return @as(*const IntType(RealType), @ptrCast(ref)).*;
    }
    return @intFromPtr(ref);
}

pub fn unpack_usize_ctx(RealType: type, ctx: usize) RealType {
    if (@sizeOf(RealType) <= @sizeOf(usize)) {
        const val: IntType(RealType) = @intCast(ctx);
        return @as(*const RealType, @ptrCast(&val)).*;
    }
    return @as(*const RealType, @ptrFromInt(ctx)).*;
}
