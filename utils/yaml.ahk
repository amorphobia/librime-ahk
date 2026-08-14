/*
 * Copyright (c) 2023 - 2026 Xuesong Peng <pengxuesong.cn@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 */

#Include ..\rime_api.ahk

class RimeYaml extends RimeStruct {
    __New(api) {
        if not this.api := api
            if not this.api := RimeApi()
                throw Error("API not available")
    }

    load(yaml) {
        local config, obj, succ

        if !(config := this.api.config_load_string(yaml))
            return 0
        try {
            succ := this._parse_obj(config, &obj)
            return succ ? obj : 0
        } finally {
            this.api.config_close(config)
        }
    }

    _parse_obj(obj, &val) {
        if this._parse_map(obj, &val)
            return true
        if this._parse_arr(obj, &val)
            return true
        if this._parse_str(obj, &val)
            return true
        if this._parse_int(obj, &val)
            return true
        if this._parse_double(obj, &val)
            return true
        if this._parse_bool(obj, &val)
            return true
        return false
    }

    _parse_map(obj, &val) {
        local inner, iter, v

        if !(iter := this.api.config_begin_map(obj, "/"))
            return false
        try {
            val := Map()
            while this.api.config_next(iter) {
                inner := this.api.config_get_item(obj, iter.key)
                try {
                    if this._parse_obj(inner, &v)
                        val[iter.key] := v
                } finally {
                    this.api.config_close(inner)
                }
            }
            return true
        } finally {
            this.api.config_end(iter)
        }
    }

    _parse_arr(obj, &val) {
        local inner, iter, v

        if !(iter := this.api.config_begin_list(obj, "/"))
            return false
        try {
            val := []
            while this.api.config_next(iter) {
                inner := this.api.config_get_item(obj, iter.key)
                try {
                    if this._parse_obj(inner, &v)
                        val.Push(v)
                } finally {
                    this.api.config_close(inner)
                }
            }
            return true
        } finally {
            this.api.config_end(iter)
        }
    }

    _parse_str(obj, &val) {
        return this.api.config_test_get_string(obj, "/", &val)
    }

    _parse_int(obj, &val) {
        return this.api.config_test_get_int(obj, "/", &val)
    }

    _parse_double(obj, &val) {
        return this.api.config_test_get_double(obj, "/", &val)
    }

    _parse_bool(obj, &val) {
        return this.api.config_test_get_bool(obj, "/", &val)
    }
} ; RimeYaml
