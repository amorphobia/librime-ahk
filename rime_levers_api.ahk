/*
 * Copyright (c) 2023 Xuesong Peng <pengxuesong.cn@gmail.com>
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
#Include rime_api.ahk

; Placeholder class processes the pointer to rime class `CustomSettings`. Do not presume the memory layout
class RimeCustomSettings extends RimeStruct {
    __New(ptr := 0) {
        this.placeholder := ptr
    }
    struct_ptr := (*) => this.placeholder
}

; Placeholder class processes the pointer to rime class `SwitcherSettings`. Do not presume the memory layout
class RimeSwitcherSettings extends RimeStruct {
    __New(ptr := 0) {
        this.placeholder := ptr
    }
    struct_ptr := (*) => this.placeholder
}

; Placeholder class processes the pointer to rime class `SchemaInfo`. Do not presume the memory layout
class RimeSchemaInfo extends RimeStruct {
    /**
     * 
     * @param `RimeSchemaListItem` item
     */
    __New(item := 0) {
        this.placeholder := item ? item.reserved : 0
    }
    struct_ptr := (*) => this.placeholder
}

class RimeUserDictIterator extends RimeStruct {
    __New() {
        this.buff := Buffer(RimeUserDictIterator.struct_size(), 0)
    }

    static ptr_offset := (*) => 0
    static i_offset := (*) => RimeUserDictIterator.ptr_offset() + A_PtrSize
    static struct_size := (*) => RimeUserDictIterator.i_offset() + A_PtrSize ; size_t

    struct_ptr := (*) => this.buff.Ptr

    i {
        get => this.num_get(RimeUserDictIterator.i_offset(), "UInt") ; size_t
    }
}

class RimeLeversApi extends RimeApiStruct {
    __New(rime := RimeApi()) {
        if not rime or not this.module := rime.find_module("levers")
            throw Error("获取 Levers API 失败！")
        this.api := this.module.get_api()
    }

    static data_size_offset := (*) => 0
    static custom_settings_init_offset := (*) => RimeLeversApi.data_size_offset() + A_IntSize + A_IntPaddingSize
    static custom_settings_destroy_offset := (*) => RimeLeversApi.custom_settings_init_offset() + A_PtrSize
    static load_settings_offset := (*) => RimeLeversApi.custom_settings_destroy_offset() + A_PtrSize
    static save_settings_offset := (*) => RimeLeversApi.load_settings_offset() + A_PtrSize
    static customize_bool_offset := (*) => RimeLeversApi.save_settings_offset() + A_PtrSize
    static customize_int_offset := (*) => RimeLeversApi.customize_bool_offset() + A_PtrSize
    static customize_double_offset := (*) => RimeLeversApi.customize_int_offset() + A_PtrSize
    static customize_string_offset := (*) => RimeLeversApi.customize_double_offset() + A_PtrSize
    static is_first_run_offset := (*) => RimeLeversApi.customize_string_offset() + A_PtrSize
    static settings_is_modified_offset := (*) => RimeLeversApi.is_first_run_offset() + A_PtrSize
    static settings_get_config_offset := (*) => RimeLeversApi.settings_is_modified_offset() + A_PtrSize
    static switcher_settings_init_offset := (*) => RimeLeversApi.settings_get_config_offset() + A_PtrSize
    static get_available_schema_list_offset := (*) => RimeLeversApi.switcher_settings_init_offset() + A_PtrSize
    static get_selected_schema_list_offset := (*) => RimeLeversApi.get_available_schema_list_offset() + A_PtrSize
    static schema_list_destroy_offset := (*) => RimeLeversApi.get_selected_schema_list_offset() + A_PtrSize
    static get_schema_id_offset := (*) => RimeLeversApi.schema_list_destroy_offset() + A_PtrSize
    static get_schema_name_offset := (*) => RimeLeversApi.get_schema_id_offset() + A_PtrSize
    static get_schema_version_offset := (*) => RimeLeversApi.get_schema_name_offset() + A_PtrSize
    static get_schema_author_offset := (*) => RimeLeversApi.get_schema_version_offset() + A_PtrSize
    static get_schema_description_offset := (*) => RimeLeversApi.get_schema_author_offset() + A_PtrSize
    static get_schema_file_path_offset := (*) => RimeLeversApi.get_schema_description_offset() + A_PtrSize
    static select_schemas_offset := (*) => RimeLeversApi.get_schema_file_path_offset() + A_PtrSize
    static get_hotkeys_offset := (*) => RimeLeversApi.select_schemas_offset() + A_PtrSize
    static set_hotkeys_offset := (*) => RimeLeversApi.get_hotkeys_offset() + A_PtrSize
    static user_dict_iterator_init_offset := (*) => RimeLeversApi.set_hotkeys_offset() + A_PtrSize
    static user_dict_iterator_destroy_offset := (*) => RimeLeversApi.user_dict_iterator_init_offset() + A_PtrSize
    static next_user_dict_offset := (*) => RimeLeversApi.user_dict_iterator_destroy_offset() + A_PtrSize
    static backup_user_dict_offset := (*) => RimeLeversApi.next_user_dict_offset() + A_PtrSize
    static restore_user_dict_offset := (*) => RimeLeversApi.backup_user_dict_offset() + A_PtrSize
    static export_user_dict_offset := (*) => RimeLeversApi.restore_user_dict_offset() + A_PtrSize
    static import_user_dict_offset := (*) => RimeLeversApi.export_user_dict_offset() + A_PtrSize
    static customize_item_offset := (*) => RimeLeversApi.import_user_dict_offset() + A_PtrSize
    static struct_size := (*) => RimeLeversApi.customize_item_offset() + A_PtrSize

    struct_ptr := (*) => this.api

    /**
     * 
     * @param config_id type of `Str`
     * @param generator_id type of `Str`
     * @returns `RimeCustomSettings` on success, `0` on failure
     */
    custom_settings_init(config_id, generator_id) {
        if not ptr := DllCall(this.fp(RimeLeversApi.custom_settings_init_offset()), "Ptr", RimeStruct.c_str(config_id).Ptr, "Ptr", RimeStruct.c_str(generator_id).Ptr, "CDecl Ptr")
            return 0
        return RimeCustomSettings(ptr)
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     */
    custom_settings_destroy(settings) {
        DllCall(this.fp(RimeLeversApi.custom_settings_destroy_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "CDecl")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @returns `True` on success, `False` on failure
     */
    load_settings(settings) {
        return DllCall(this.fp(RimeLeversApi.load_settings_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @returns `True` on success, `False` on failure
     */
    save_settings(settings) {
        return DllCall(this.fp(RimeLeversApi.save_settings_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @param key type of `Str`
     * @param value `True` or `False`
     * @returns `True` on success, `False` on failure
     */
    customize_bool(settings, key, value) {
        return DllCall(this.fp(RimeLeversApi.customize_bool_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", RimeStruct.c_str(key).Ptr, "Int", value, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @param key type of `Str`
     * @param value type of `Int`
     * @returns `True` on success, `False` on failure
     */
    customize_int(settings, key, value) {
        return DllCall(this.fp(RimeLeversApi.customize_int_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", RimeStruct.c_str(key).Ptr, "Int", value, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @param key type of `Str`
     * @param value type of `Double`
     * @returns `True` on success, `False` on failure
     */
    customize_double(settings, key, value) {
        return DllCall(this.fp(RimeLeversApi.customize_double_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", RimeStruct.c_str(key).Ptr, "Double", value, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @param key type of `Str`
     * @param value type of `Str`
     * @returns `True` on success, `False` on failure
     */
    customize_string(settings, key, value) {
        return DllCall(this.fp(RimeLeversApi.customize_string_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", RimeStruct.c_str(key).Ptr, "Ptr", RimeStruct.c_str(value).Ptr, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @returns `True` or `False`
     */
    is_first_run(settings) {
        return DllCall(this.fp(RimeLeversApi.is_first_run_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @returns `True` or `False`
     */
    settings_is_modified(settings) {
        return DllCall(this.fp(RimeLeversApi.settings_is_modified_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @returns `RimeConfig` on success, `0` on failure
     */
    settings_get_config(settings) {
        config := RimeConfig()
        res := DllCall(this.fp(RimeLeversApi.settings_get_config_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", config.struct_ptr(), "CDecl Int")
        return res ? config : 0
    }

    /**
     * 
     * @returns `RimeSwitcherSettings` on success, `0` on failure
     */
    switcher_settings_init() {
        if not ptr := DllCall(this.fp(RimeLeversApi.switcher_settings_init_offset()), "CDecl Ptr")
            return 0
        return RimeSwitcherSettings(ptr)
    }

    /**
     * 
     * @param settings type of `RimeSwitcherSettings`
     * @returns `RimeSchemaList` on success, `0` on failure
     */
    get_available_schema_list(settings) {
        list := RimeSchemaList()
        res := DllCall(this.fp(RimeLeversApi.get_available_schema_list_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", list.struct_ptr(), "CDecl Int")
        return res ? list : 0
    }

    /**
     * 
     * @param settings type of `RimeSwitcherSettings`
     * @returns `RimeSchemaList` on success, `0` on failure
     */
    get_selected_schema_list(settings) {
        list := RimeSchemaList()
        res := DllCall(this.fp(RimeLeversApi.get_selected_schema_list_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", list.struct_ptr(), "CDecl Int")
        return res ? list : 0
    }

    /**
     * 
     * @param list type of `RimeSchemaList`
     */
    schema_list_destroy(list) {
        DllCall(this.fp(RimeLeversApi.schema_list_destroy_offset()), "Ptr", list ? list.struct_ptr() : 0, "CDecl")
    }

    /**
     * 
     * @param info type of `RimeSchemaInfo`
     * @returns `Str`
     */
    get_schema_id(info) {
        p := DllCall(this.fp(RimeLeversApi.get_schema_id_offset()), "Ptr", info ? info.struct_ptr() : 0, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }

    /**
     * 
     * @param info type of `RimeSchemaInfo`
     * @returns `Str`
     */
    get_schema_name(info) {
        p := DllCall(this.fp(RimeLeversApi.get_schema_name_offset()), "Ptr", info ? info.struct_ptr() : 0, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }

    /**
     * 
     * @param info type of `RimeSchemaInfo`
     * @returns `Str`
     */
    get_schema_version(info) {
        p := DllCall(this.fp(RimeLeversApi.get_schema_version_offset()), "Ptr", info ? info.struct_ptr() : 0, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }

    /**
     * 
     * @param info type of `RimeSchemaInfo`
     * @returns `Str`
     */
    get_schema_author(info) {
        p := DllCall(this.fp(RimeLeversApi.get_schema_author_offset()), "Ptr", info ? info.struct_ptr() : 0, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }

    /**
     * 
     * @param info type of `RimeSchemaInfo`
     * @returns `Str`
     */
    get_schema_description(info) {
        p := DllCall(this.fp(RimeLeversApi.get_schema_description_offset()), "Ptr", info ? info.struct_ptr() : 0, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }

    /**
     * 
     * @param info type of `RimeSchemaInfo`
     * @returns `Str`
     */
    get_schema_file_path(info) {
        p := DllCall(this.fp(RimeLeversApi.get_schema_file_path_offset()), "Ptr", info ? info.struct_ptr() : 0, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }

    /**
     * 
     * @param settings type of `RimeSwitcherSettings`
     * @param schema_id_list `Array` of `Str`
     * @returns `True` on success, `False` on failure
     */
    select_schemas(settings, schema_id_list) {
        arr := RimeStruct.c_str_array(schema_id_list)
        return DllCall(this.fp(RimeLeversApi.select_schemas_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", arr.str_ptrs, "Int", arr.str_bufs.Length, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeSwitcherSettings`
     * @returns `Str`
     */
    get_hotkeys(settings) {
        p := DllCall(this.fp(RimeLeversApi.get_hotkeys_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }
 
    /**
     * 
     * @param settings type of `RimeSwitcherSettings`
     * @param hotkeys type of `Str`
     * @returns `True` on success, `False` on failure
     */
    set_hotkeys(settings, hotkeys) {
        return DllCall(this.fp(RimeLeversApi.set_hotkeys_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", RimeStruct.c_str(hotkeys).Ptr, "CDecl Int")
    }

    /**
     * 
     * @returns `RimeUserDictIterator` on success, `0` on failure
     */
    user_dict_iterator_init() {
        iter := RimeUserDictIterator()
        res := DllCall(this.fp(RimeLeversApi.user_dict_iterator_init_offset()), "Ptr", iter.struct_ptr(), "CDecl Int")
        return res ? iter : 0
    }

    /**
     * 
     * @param iter type of `RimeUserDictIterator`
     */
    user_dict_iterator_destroy(iter) {
        DllCall(this.fp(RimeLeversApi.user_dict_iterator_destroy_offset()), "Ptr", iter ? iter.struct_ptr() : 0, "CDecl")
    }

    /**
     * 
     * @param iter type of `RimeUserDictIterator`
     * @returns `Str`
     */
    next_user_dict(iter) {
        p := DllCall(this.fp(RimeLeversApi.next_user_dict_offset()), "Ptr", iter ? iter.struct_ptr() : 0, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }

    /**
     * 
     * @param dict_name type of `Str`
     * @returns `True` on success, `False` on failure
     */
    backup_user_dict(dict_name) {
        return DllCall(this.fp(RimeLeversApi.backup_user_dict_offset()), "Ptr", RimeStruct.c_str(dict_name).Ptr, "CDecl Int")
    }

    /**
     * 
     * @param snapshot_file type of `Str`
     * @returns `True` on success, `False` on failure
     */
    restore_user_dict(snapshot_file) {
        return DllCall(this.fp(RimeLeversApi.restore_user_dict_offset()), "Ptr", RimeStruct.c_str(snapshot_file).Ptr, "CDecl Int")
    }

    /**
     * 
     * @param dict_name type of `Str`
     * @param text_file type of `Str`
     * @returns `Int`
     */
    export_user_dict(dict_name, text_file) {
        return DllCall(this.fp(RimeLeversApi.export_user_dict_offset()), "Ptr", RimeStruct.c_str(dict_name).Ptr, "Ptr", RimeStruct.c_str(text_file).Ptr, "CDecl Int")
    }

    /**
     * 
     * @param dict_name type of `Str`
     * @param text_file type of `Str`
     * @returns `Int`
     */
    import_user_dict(dict_name, text_file) {
        return DllCall(this.fp(RimeLeversApi.import_user_dict_offset()), "Ptr", RimeStruct.c_str(dict_name).Ptr, "Ptr", RimeStruct.c_str(text_file).Ptr, "CDecl Int")
    }

    /**
     * 
     * @param settings type of `RimeCustomSettings`
     * @param key type of `Str`
     * @param value type of `RimeConfig`
     * @returns `True` on success, `False` on failure
     */
    customize_item(settings, key, value) {
        return DllCall(this.fp(RimeLeversApi.customize_item_offset()), "Ptr", settings ? settings.struct_ptr() : 0, "Ptr", RimeStruct.c_str(key).Ptr, "Ptr", value ? value.struct_ptr() : 0, "CDecl Int")
    }
}
