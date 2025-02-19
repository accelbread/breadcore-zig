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

const reader = @import("io/reader.zig");

pub const Reader = reader.Reader;
pub const DynReader = reader.DynReader;

const writer = @import("io/writer.zig");

pub const Writer = writer.Writer;
pub const DynWriter = writer.DynWriter;

fn null_read(self: void, buf: []u8) error{}!usize {
    _ = self;
    _ = buf;
    return 0;
}

pub const null_reader = Reader(null_read).new({});

fn null_write(self: void, buf: []const u8) error{InsufficientSpace}!usize {
    _ = self;
    return if (buf.len == 0) 0 else error.InsufficientSpace;
}

pub const null_writer = Writer(null_write).new({});

pub const BufReader = struct {
    buf: []const u8,

    fn read(self: *BufReader, buf: []u8) error{}!usize {
        const copy_len = @min(self.buf.len, buf.len);
        @memcpy(buf[0..copy_len], self.buf[0..copy_len]);
        self.buf = self.buf[copy_len..];
        return copy_len;
    }

    pub fn reader(self: *BufReader) Reader(read) {
        return .new(self);
    }

    pub fn new(buf: []const u8) BufReader {
        return .{ .buf = buf };
    }
};

test BufReader {
    var input: BufReader = .new("hello");
    var output_buf: [10]u8 = undefined;
    var output: []u8 = &output_buf;
    output.len = try input.reader().read(output);
    try std.testing.expectEqualStrings(output, "hello");
}

pub const BufWriter = struct {
    buf: []u8,

    fn write(self: *BufWriter, buf: []const u8) error{InsufficientSpace}!usize {
        if (self.buf.len == 0) {
            return error.InsufficientSpace;
        }
        const copy_len = @min(buf.len, self.buf.len);
        @memcpy(self.buf[0..copy_len], buf[0..copy_len]);
        self.buf = self.buf[copy_len..];
        return copy_len;
    }

    pub fn writer(self: *BufWriter) Writer(write) {
        return .new(self);
    }

    pub fn new(buf: []u8) BufWriter {
        return .{ .buf = buf };
    }
};

test BufWriter {
    var output_buf: [10]u8 = undefined;
    var output: BufWriter = .new(&output_buf);
    const written = try output.writer().write("hello");
    try std.testing.expectEqualStrings(output_buf[0..written], "hello");
}
