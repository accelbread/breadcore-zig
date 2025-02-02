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

const io = @import("io.zig");
const std = @import("std");

const TestWriter = struct {
    expected: []const u8,
    errored: bool = false,
    matches: bool = false,

    fn write(self: *TestWriter, buf: []const u8) error{IncorrectWrite}!usize {
        if (self.errored) {
            return error.IncorrectWrite;
        }
        if ((buf.len > self.expected.len) or
            !std.mem.eql(u8, buf, self.expected[0..buf.len]))
        {
            self.errored = true;
            self.matches = false;
            return error.IncorrectWrite;
        }

        self.expected = self.expected[buf.len..];

        if (self.expected.len == 0) {
            self.matches = true;
        }
        return buf.len;
    }

    pub fn writer(self: *TestWriter) io.Writer(write) {
        return .new(self);
    }

    pub fn new(expected: []const u8) TestWriter {
        return .{ .expected = expected };
    }
};

test TestWriter {
    var output: TestWriter = .new("hello");
    _ = try output.writer().write("hello");
    try std.testing.expect(output.matches);
    output = .new("world");
    const err_result = output.writer().write("wurld");
    try std.testing.expectError(error.IncorrectWrite, err_result);
    try std.testing.expect(!output.matches);
}
