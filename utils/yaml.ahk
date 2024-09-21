/*
 * Copyright (c) 2024 Xuesong Peng <pengxuesong.cn@gmail.com>
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
        if not config := this.api.config_load_string(yaml)
            return 0
        local succ := this._parse_obj(config, &obj)
        this.api.config_close(config)
        return succ ? obj : 0
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
        if not iter := this.api.config_begin_map(obj, "/")
            return false
        val := Map()
        while this.api.config_next(iter) {
            local inner := this.api.config_get_item(obj, iter.key)
            if this._parse_obj(inner, &v)
                val[iter.key] := v
            this.api.config_close(inner)
        }
        this.api.config_end(iter)
        return true
    }

    _parse_arr(obj, &val) {
        if not iter := this.api.config_begin_list(obj, "/")
            return false
        val := []
        while this.api.config_next(iter) {
            local inner := this.api.config_get_item(obj, iter.key)
            if this._parse_obj(inner, &v)
                val.Push(v)
            this.api.config_close(inner)
        }
        this.api.config_end(iter)
        return true
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
