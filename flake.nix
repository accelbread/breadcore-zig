# breadcore -- General-purpose utility library
# Copyright (C) 2024 Archit Gupta <archit@accelbread.com>
#
# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, either version 3 of the License, or (at your option) any
# later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# SPDX-License-Identifier: AGPL-3.0-or-later

{
  description = "General-purpose utility library.";
  inputs = {
    flakelight-zig.url = "github:accelbread/flakelight-zig";
    zig-master-flake.url = "github:accelbread/zig-master-flake";
  };
  outputs = { flakelight-zig, zig-master-flake, ... }:
    flakelight-zig ./. {
      withOverlays = [ zig-master-flake.overlays.override-zig ];
      license = "AGPL-3.0-or-later";
      zigFlags = [ "--release" ];
      devShell.packages = pkgs: [ pkgs.kcov ];
    };
}
