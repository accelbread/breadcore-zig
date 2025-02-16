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

pub fn is_alpha(c: u8) bool {
    const lower = c | 0b00100000;
    return 'a' <= lower and lower <= 'z';
}

pub fn is_num(c: u8) bool {
    return '0' <= c and c <= '9';
}

pub fn is_alphanum(c: u8) bool {
    return is_alpha(c) or is_num(c);
}
