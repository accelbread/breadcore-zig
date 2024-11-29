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

pub fn build(b: *std.Build) !void {
    return standardBuild(b, "breadcore", .lib);
}

const BuildConfig = struct {
    const BuildType = enum { exe, lib };
    const ExeConfigFn = fn (exe: *std.Build.Step.Compile) void;

    build_type: BuildType,
    configure_exe: ?ExeConfigFn = null,

    pub const lib = BuildConfig{ .build_type = .lib };

    pub fn exe(configure_exe: ?ExeConfigFn) BuildConfig {
        return .{ .build_type = .exe, .configure_exe = configure_exe };
    }
};

pub fn standardBuild(
    b: *std.Build,
    comptime name: []const u8,
    comptime config: BuildConfig,
) !void {
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

    const root_file = b.path(switch (config.build_type) {
        .exe => "src/main.zig",
        .lib => "src/root.zig",
    });

    const exe_opts = std.Build.ExecutableOptions{
        .name = name,
        .root_source_file = root_file,
        .target = target,
        .optimize = optimize,
        .strip = optimize != .Debug,
    };

    if (config.build_type == .exe) {
        const exe = b.addExecutable(exe_opts);

        exe.pie = true;
        exe.want_lto = optimize != .Debug;
        exe.compress_debug_sections = .zlib;

        if (config.configure_exe) |configure_exe| {
            configure_exe(exe);
        }

        b.installArtifact(exe);

        const run_step = b.step("run", "Run the app");

        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        if (b.args) |args| {
            run_cmd.addArgs(args);
        }
        run_step.dependOn(&run_cmd.step);
    }

    if (config.build_type == .lib) {
        _ = b.addModule(name, .{ .root_source_file = root_file });
    }

    const test_step = b.step("test", "Run unit tests");

    const unit_tests = b.addTest(.{
        .root_source_file = root_file,
        .target = target,
        .optimize = optimize,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);
    test_step.dependOn(&run_unit_tests.step);

    const coverage_step = b.step("coverage", "Generate unit test coverage");

    const run_coverage = b.addSystemCommand(
        &.{ "kcov", "--clean", "--include-path=src" },
    );
    const coverage_path = run_coverage.addOutputDirectoryArg("kcov");
    run_coverage.addArtifactArg(unit_tests);

    const open_coverage = b.addSystemCommand(&.{"xdg-open"});
    open_coverage.addFileArg(try coverage_path.join(b.allocator, "index.html"));
    open_coverage.step.dependOn(&run_coverage.step);
    coverage_step.dependOn(&open_coverage.step);

    const check_step = b.step("check", "Check compilation");

    const unit_tests_check = b.addTest(.{
        .root_source_file = root_file,
        .target = target,
        .optimize = optimize,
    });
    check_step.dependOn(&unit_tests_check.step);

    if (config.build_type == .exe) {
        const exe_check = b.addExecutable(exe_opts);
        if (config.configure_exe) |configure_exe| {
            configure_exe(exe_check);
        }
        check_step.dependOn(&exe_check.step);
    }
}
