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
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        .default_target = .{
            .cpu_model = if (builtin.cpu.arch == .x86_64)
                .{ .explicit = &std.Target.x86.cpu.x86_64_v3 }
            else
                .baseline,
        },
    });
    const optimize = b.standardOptimizeOption(.{
        .preferred_optimize_mode = .ReleaseSafe,
    });

    _ = b.addModule("breadcore", .{
        .root_source_file = b.path("src/breadcore.zig"),
    });

    const unit_tests = b.addTest(.{
        .root_source_file = b.path("src/breadcore.zig"),
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const run_coverage = b.addSystemCommand(&.{
        "kcov",
        "--clean",
        b.pathJoin(&.{ b.install_path, "kcov" }),
    });
    run_coverage.addArtifactArg(unit_tests);
    const coverage_step = b.step("coverage", "Generate unit test coverage");
    coverage_step.dependOn(&run_coverage.step);

    const check_step = b.step("check", "Check if lib compiles");
    check_step.dependOn(&unit_tests.step);
}
