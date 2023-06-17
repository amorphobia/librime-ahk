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
#Requires AutoHotkey v2.0 32-bit

INT_SIZE() {
    return 4
}

UTF8Buffer(text) {
    buf := Buffer()
    if text {
        buf := Buffer(StrPut(text, "UTF-8"), 0)
        StrPut(text, buf, "UTF-8")
    }
    return buf
}
UTF8StrGet(src, offset) {
    if p := NumGet(src, offset, "Ptr")
        return StrGet(p, "UTF-8")
    return ""
}
UTF8StrPut(val, tgt, offset) {
    buf := UTF8Buffer(val)
    NumPut("Ptr", buf.Ptr, tgt, offset)
    return buf
}

class RimeTraits {
    __New() {
        this.buff := Buffer(RimeTraits.size(), 0)
        this.data_size := RimeTraits.size() - INT_SIZE()
    }

    static size() {
        return 48
    }
    static data_size_offset() {
        return 0
    }
    static shared_data_dir_offset() {
        return RimeTraits.data_size_offset() + INT_SIZE()
    }
    static user_data_dir_offset() {
        return RimeTraits.shared_data_dir_offset() + A_PtrSize
    }
    static distribution_name_offset() {
        return RimeTraits.user_data_dir_offset() + A_PtrSize
    }
    static distribution_code_name_offset() {
        return RimeTraits.distribution_name_offset() + A_PtrSize
    }
    static distribution_version_offset() {
        return RimeTraits.distribution_code_name_offset() + A_PtrSize
    }
    static app_name_offset() {
        return RimeTraits.distribution_version_offset() + A_PtrSize
    }
    static modules_offset() {
        return RimeTraits.app_name_offset() + A_PtrSize
    }
    static min_log_level_offset() {
        return RimeTraits.modules_offset() + A_PtrSize
    }
    static log_dir_offset() {
        return RimeTraits.min_log_level_offset() + INT_SIZE()
    }
    static prebuilt_data_dir_offset() {
        return RimeTraits.log_dir_offset() + A_PtrSize
    }
    static staging_dir_offset() {
        return RimeTraits.prebuilt_data_dir_offset() + A_PtrSize
    }

    data_size {
        get => NumGet(this.buff, RimeTraits.data_size_offset(), "Int")
        set => NumPut("Int", Value, this.buff, RimeTraits.data_size_offset())
    }
    shared_data_dir {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.shared_data_dir_offset())
        set => this.__shared_data_dir := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.shared_data_dir_offset())
    }
    user_data_dir {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.user_data_dir_offset())
        set => this.__user_data_dir := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.user_data_dir_offset())
    }
    distribution_name {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.distribution_name_offset())
        set => this.__distribution_name := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.distribution_name_offset())
    }
    distribution_code_name {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.distribution_code_name_offset())
        set => this.__distribution_code_name := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.distribution_code_name_offset())
    }
    distribution_version {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.distribution_version_offset())
        set => this.__distribution_version := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.distribution_version_offset())
    }
    app_name {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.app_name_offset())
        set => this.__app_name := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.app_name_offset())
    }
    ; modules
    min_log_level {
        get => NumGet(this.buff, RimeTraits.min_log_level_offset(), "Int")
        set => NumPut("Int", Value, this.buff, RimeTraits.min_log_level_offset())
    }
    log_dir {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.log_dir_offset())
        set => this.__log_dir := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.log_dir_offset())
    }
    prebuilt_data_dir {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.prebuilt_data_dir_offset())
        set => this.__prebuilt_data_dir := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.prebuilt_data_dir_offset())
    }
    staging_dir {
        get => UTF8StrGet(this.buff.Ptr, RimeTraits.staging_dir_offset())
        set => this.__staging_dir := UTF8StrPut(Value, this.buff.Ptr, RimeTraits.staging_dir_offset())
    }
} ; RimeTraits

class RimeComposition {
    __New(ptr := 0) {
        this.buff := Buffer(RimeComposition.size(), 0)
        if ptr {
            Loop RimeComposition.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 20
    }
    static lenth_offset() {
        return 0
    }
    static cursor_pos_offset() {
        return RimeComposition.lenth_offset() + INT_SIZE()
    }
    static sel_start_offset() {
        return RimeComposition.cursor_pos_offset() + INT_SIZE()
    }
    static sel_end_offset() {
        return RimeComposition.sel_start_offset() + INT_SIZE()
    }
    static preedit_offset() {
        return RimeComposition.sel_end_offset() + INT_SIZE()
    }

    length {
        get => NumGet(this.buff, RimeComposition.lenth_offset(), "Int")
    }
    cursor_pos {
        get => NumGet(this.buff, RimeComposition.cursor_pos_offset(), "Int")
    }
    sel_start {
        get => NumGet(this.buff, RimeComposition.sel_start_offset(), "Int")
    }
    sel_end {
        get => NumGet(this.buff, RimeComposition.sel_end_offset(), "Int")
    }
    preedit {
        get => UTF8StrGet(this.buff.Ptr, RimeComposition.preedit_offset())
    }
} ; RimeComposition

class RimeCandidate {
    __New(ptr := 0) {
        this.buff := Buffer(RimeCandidate.size(), 0)
        if ptr {
            Loop RimeCandidate.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 12
    }
    static text_offset() {
        return 0
    }
    static comment_offset() {
        return RimeCandidate.text_offset() + A_PtrSize
    }

    text {
        get => UTF8StrGet(this.buff.Ptr, RimeCandidate.text_offset())
    }
    comment {
        get => UTF8StrGet(this.buff.Ptr, RimeCandidate.comment_offset())
    }
} ; RimeCandidate

class RimeMenu {
    __New(ptr := 0) {
        this.buff := Buffer(RimeMenu.size(), 0)
        if ptr {
            Loop RimeMenu.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 28
    }
    static page_size_offset() {
        return 0
    }
    static page_no_offset() {
        return RimeMenu.page_size_offset() + INT_SIZE()
    }
    static is_last_page_offset() {
        return RimeMenu.page_no_offset() + INT_SIZE()
    }
    static highlighted_candidate_index_offset() {
        return RimeMenu.is_last_page_offset() + INT_SIZE()
    }
    static num_candidates_offset() {
        return RimeMenu.highlighted_candidate_index_offset() + INT_SIZE()
    }
    static candidates_offset() {
        return RimeMenu.num_candidates_offset() + INT_SIZE()
    }
    static select_keys_offset() {
        return RimeMenu.candidates_offset() + A_PtrSize
    }

    page_size {
        get => NumGet(this.buff, RimeMenu.page_size_offset(), "Int")
    }
    page_no {
        get => NumGet(this.buff, RimeMenu.page_no_offset(), "Int")
    }
    is_last_page {
        get => NumGet(this.buff, RimeMenu.is_last_page_offset(), "Int")
    }
    highlighted_candidate_index {
        get => NumGet(this.buff, RimeMenu.highlighted_candidate_index_offset(), "Int")
    }
    num_candidates {
        get => NumGet(this.buff, RimeMenu.num_candidates_offset(), "Int")
    }
    candidates {
        get {
            cands := Array()
            if p := NumGet(this.buff.Ptr, RimeMenu.candidates_offset(), "Ptr") {
                Loop this.num_candidates {
                    local ptr := p + (A_Index - 1) * RimeCandidate.size()
                    cands.Push(RimeCandidate(ptr))
                }
            }
            return cands
        }
    }
    select_keys {
        get => UTF8StrGet(this.buff.Ptr, RimeMenu.select_keys_offset())
    }
} ; RimeMenu

class RimeCommit {
    __New(ptr := 0) {
        this.buff := Buffer(RimeCommit.size(), 0)
        this.data_size := RimeCommit.size() - INT_SIZE()
        if ptr {
            Loop RimeCommit.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 8
    }
    static data_size_offset() {
        return 0
    }
    static text_offset() {
        return RimeCommit.data_size_offset() + INT_SIZE()
    }

    data_size {
        get => NumGet(this.buff, RimeCommit.data_size_offset(), "Int")
        set => NumPut("Int", Value, this.buff, RimeCommit.data_size_offset())
    }
    text {
        get => UTF8StrGet(this.buff.Ptr, RimeCommit.text_offset())
    }
} ; RimeCommit

class RimeContext {
    __New() {
        this.buff := Buffer(RimeContext.size(), 0)
        this.data_size := RimeContext.size() - INT_SIZE()
    }

    static size() {
        return 60
    }
    static data_size_offset() {
        return 0
    }
    static composition_offset() {
        return RimeContext.data_size_offset() + INT_SIZE()
    }
    static menu_offset() {
        return RimeContext.composition_offset() + RimeComposition.size()
    }
    static commit_text_preview_offset() {
        return RimeContext.menu_offset() + RimeMenu.size()
    }
    static select_labels_offset() {
        return RimeContext.commit_text_preview_offset() + A_PtrSize
    }

    data_size {
        get => NumGet(this.buff, RimeContext.data_size_offset(), "Int")
        set => NumPut("Int", Value, this.buff, RimeContext.data_size_offset())
    }
    composition {
        get => RimeComposition(this.buff.Ptr + RimeContext.composition_offset())
    }
    menu {
        get => RimeMenu(this.buff.Ptr + RimeContext.menu_offset())
    }
} ; RimeContext

class RimeStatus {
    __New(ptr := 0) {
        this.buff := Buffer(RimeStatus.size(), 0)
        this.data_size := RimeStatus.size() - INT_SIZE()
        if ptr {
            Loop RimeStatus.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 40
    }
    static data_size_offset() {
        return 0
    }
    static schema_id_offset() {
        return this.data_size_offset() + INT_SIZE()
    }
    static schema_name_offset() {
        return this.schema_id_offset() + A_PtrSize
    }
    static is_disabled_offset() {
        return this.schema_name_offset() + A_PtrSize
    }
    static is_composing_offset() {
        return this.is_disabled_offset() + INT_SIZE()
    }
    static is_ascii_mode_offset() {
        return this.is_composing_offset() + INT_SIZE()
    }
    static is_full_shape_offset() {
        return this.is_ascii_mode_offset() + INT_SIZE()
    }
    static is_simplified_offset() {
        return this.is_full_shape_offset() + INT_SIZE()
    }
    static is_traditional_offset() {
        return this.is_simplified_offset() + INT_SIZE()
    }
    static is_ascii_punct_offset() {
        return this.is_traditional_offset() + INT_SIZE()
    }

    data_size {
        get => NumGet(this.buff, RimeStatus.data_size_offset(), "Int")
        set => NumPut("Int", Value, this.buff, RimeStatus.data_size_offset())
    }
    schema_id {
        get => UTF8StrGet(this.buff.Ptr, RimeStatus.schema_id_offset())
    }
    schema_name {
        get => UTF8StrGet(this.buff.Ptr, RimeStatus.schema_name_offset())
    }
    is_disabled {
        get => NumGet(this.buff, RimeStatus.is_disabled_offset(), "Int")
    }
    is_composing {
        get => NumGet(this.buff, RimeStatus.is_composing_offset(), "Int")
    }
    is_ascii_mode {
        get => NumGet(this.buff, RimeStatus.is_ascii_mode_offset(), "Int")
    }
    is_full_shape {
        get => NumGet(this.buff, RimeStatus.is_full_shape_offset(), "Int")
    }
    is_simplified {
        get => NumGet(this.buff, RimeStatus.is_simplified_offset(), "Int")
    }
    is_traditional {
        get => NumGet(this.buff, RimeStatus.is_traditional_offset(), "Int")
    }
    is_ascii_punct {
        get => NumGet(this.buff, RimeStatus.is_ascii_punct_offset(), "Int")
    }
} ; RimeStatus

class RimeCandidateListIterator {
    __New() {
        this.buff := Buffer(RimeCandidateListIterator.size(), 0)
    }

    static size() {
        return 20
    }
    static ptr_offset() {
        return 0
    }
    static index_offset() {
        return RimeCandidateListIterator.ptr_offset() + A_PtrSize
    }
    static candidate_offset() {
        return RimeCandidateListIterator.index_offset() + INT_SIZE()
    }

    index {
        get => NumGet(this.buff, RimeCandidateListIterator.index_offset(), "Int")
    }
    candidate {
        get => RimeCandidate(this.buff.Ptr + RimeCandidateListIterator.candidate_offset())
    }
} ; RimeCandidateListIterator

class RimeConfig {
    __New(ptr := 0) {
        this.buff := Buffer(RimeConfig.size(), 0)
        if ptr {
            Loop RimeConfig.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 4
    }
    static ptr_offset() {
        return 0
    }

    ptr {
        get => NumGet(this.buff.Ptr, RimeConfig.ptr_offset(), "Ptr")
    }
} ; RimeConfig

class RimeConfigIterator {
    __New(ptr := 0) {
        this.buff := Buffer(RimeConfigIterator.size(), 0)
        if ptr {
            Loop RimeConfigIterator.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 20
    }
    static list_offset() {
        return 0
    }
    static map_offset() {
        return RimeConfigIterator.list_offset() + A_PtrSize
    }
    static index_offset() {
        return RimeConfigIterator.map_offset() + A_PtrSize
    }
    static key_offset() {
        return RimeConfigIterator.index_offset() + INT_SIZE()
    }
    static path_offset() {
        return RimeConfigIterator.key_offset() + A_PtrSize
    }

    list {
        get => NumGet(this.buff.Ptr, RimeConfigIterator.list_offset(), "Ptr")
    }
    map {
        get => NumGet(this.buff.Ptr, RimeConfigIterator.map_offset(), "Ptr")
    }
    index {
        get => NumGet(this.buff, RimeConfigIterator.index_offset(), "Int")
    }
    key {
        get => UTF8StrGet(this.buff.Ptr, RimeConfigIterator.key_offset())
    }
    path {
        get => UTF8StrGet(this.buff.Ptr, RimeConfigIterator.path_offset())
    }
}

class RimeSchemaListItem {
    __New(ptr := 0) {
        this.buff := Buffer(RimeSchemaListItem.size(), 0)
        if ptr {
            Loop RimeSchemaListItem.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 12
    }
    static schema_id_offset() {
        return 0
    }
    static name_offset() {
        return RimeSchemaListItem.schema_id_offset() + A_PtrSize
    }

    schema_id {
        get => UTF8StrGet(this.buff.Ptr, RimeSchemaListItem.schema_id_offset())
    }
    name {
        get => UTF8StrGet(this.buff.Ptr, RimeSchemaListItem.name_offset())
    }
} ; RimeSchemaListItem

class RimeSchemaList {
    __New() {
        this.buff := Buffer(RimeSchemaList.size(), 0)
    }

    static size() {
        return 8
    }
    static size_offset() {
        return 0
    }
    static list_offset() {
        return RimeSchemaList.size_offset() + INT_SIZE()
    }

    size {
        get => NumGet(this.buff, RimeSchemaList.size_offset(), "Int")
    }
    list {
        get {
            sl := Array()
            if p := NumGet(this.buff.Ptr, RimeSchemaList.list_offset(), "Ptr") {
                Loop this.size {
                    ptr := p + (A_Index - 1) * RimeSchemaListItem.size()
                    sl.Push(RimeSchemaListItem(ptr))
                }
            }
            return sl
        }
    }
} ; RimeSchemaList

class RimeStringSlice {
    __New(ptr := 0) {
        this.buff := Buffer(RimeStringSlice.size(), 0)
        if ptr {
            Loop RimeStringSlice.size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static size() {
        return 8
    }
    static str_offset() {
        return 0
    }
    static length_offset() {
        return RimeStringSlice.str_offset() + A_PtrSize
    }

    str {
        get => UTF8StrGet(this.buff.Ptr, RimeStringSlice.str_offset())
    }
    length {
        get => NumGet(this.buff, RimeStringSlice.length_offset(), "UInt")
    }
} ; RimeStringSlice

; RimeCustomApi
; RimeModule

class RimeApi {
    __New() {
        if not RimeApi.rimeDll {
            MsgBox("未找到 rime.dll！", "错误")
            ExitApp(1)
        }

        this.api := DllCall("rime\rime_get_api", "Cdecl Ptr")
        if not this.api {
            MsgBox("获取 Rime API 失败！", "错误")
            ExitApp(1)
        }

        if VerCompare(this.get_version(), RimeApi.min_version()) < 0 {
            MsgBox("Librime 版本过低，请使用 1.8.5 及以上版本。", "错误")
            ExitApp(1)
        }
    }

    static rimeDll := DllCall("LoadLibrary", "Str", "rime.dll", "Ptr")
    static min_version() {
        return "1.8.5"
    }

    data_size {
        get => NumGet(this.api, 0, "Int")
    }

    ; (RimeTraits) => void
    setup(traits) {
        DllCall(NumGet(this.api, 4, "Ptr"), "Ptr", traits ? traits.buff.Ptr : 0, "Cdecl")
    }

    ; () => void
    set_notification_handler(handler, context_object) {
        DllCall(NumGet(this.api, 8, "Ptr"), "Ptr", CallbackCreate(handler, "C", 4), "Ptr", context_object, "Cdecl")
    }

    ; (RimeTraits) => void
    initialize(traits) {
        DllCall(NumGet(this.api, 12, "Ptr"), "Ptr", traits ? traits.buff.Ptr : 0, "Cdecl")
    }

    ; () => void
    finalize() {
        DllCall(NumGet(this.api, 16, "Ptr"), "Cdecl")
        DllCall("FreeLibrary", "Ptr", RimeApi.rimeDll)
    }

    ; (Int) => Int
    start_maintenace(full_check) {
        return DllCall(NumGet(this.api, 20, "Ptr"), "Int", full_check, "Cdecl Int")
    }

    ; () => Int
    is_maintenance_mode() {
        return DllCall(NumGet(this.api, 24, "Ptr"), "Cdecl Int")
    }

    ; () => void
    join_maintenance_thread() {
        DllCall(NumGet(this.api, 28, "Ptr"), "Cdecl")
    }

    ; (RimeTraits) => void
    deployer_initialize(traits) {
        DllCall(NumGet(this.api, 32, "Ptr"), "Ptr", traits ? traits.buff.Ptr : 0, "Cdecl")
    }

    ; () => Int
    prebuild() {
        return DllCall(NumGet(this.api, 36, "Ptr"), "Cdecl Int")
    }

    ; () => Int
    deploy() {
        return DllCall(NumGet(this.api, 40, "Ptr"), "Cdecl Int")
    }

    ; (Str) => Int
    deploy_schemas(schema_file) {
        return DllCall(NumGet(this.api, 44, "Ptr"), "Ptr", UTF8Buffer(schema_file).Ptr, "Cdecl Int")
    }

    ; (Str, Str) => Int
    deploy_config_file(file_name, version_key) {
        return DllCall(NumGet(this.api, 48, "Ptr"), "Ptr", UTF8Buffer(file_name).Ptr, "Ptr", UTF8Buffer(version_key).Ptr, "Cdecl Int")
    }

    ; () => Int
    sync_user_data() {
        return DllCall(NumGet(this.api, 52, "Ptr"), "Cdecl Int")
    }

    ; () => UInt
    create_session() {
        return DllCall(NumGet(this.api, 56, "Ptr"), "Cdecl UInt")
    }

    ; (UInt) => Int
    find_session(session_id) {
        return DllCall(NumGet(this.api, 60, "Ptr"), "UInt", session_id, "Cdecl Int")
    }

    ; (UInt) => Int
    destroy_session(session_id) {
        return DllCall(NumGet(this.api, 64, "Ptr"), "UInt", session_id, "Cdecl Int")
    }

    ; () => void
    cleanup_stale_sessions() {
        DllCall(NumGet(this.api, 68, "Ptr"), "Cdecl")
    }

    ; () => void
    cleanup_all_sessions() {
        DllCall(NumGet(this.api, 72, "Ptr"), "Cdecl")
    }

    ; (UInt, Int, Int) => Int
    process_key(session_id, keycode, mask) {
        return DllCall(NumGet(this.api, 76, "Ptr"), "UInt", session_id, "Int", keycode, "Int", mask, "Cdecl Int")
    }

    ; (UInt) => Int
    commit_composition(session_id) {
        return DllCall(NumGet(this.api, 80, "Ptr"), "UInt", session_id, "Cdecl Int")
    }

    ; (UInt) => void
    clear_composition(session_id) {
        DllCall(NumGet(this.api, 84, "Ptr"), "UInt", session_id, "Cdecl")
    }

    ; (UInt) => RimeCommit or 0
    get_commit(session_id) {
        commit := RimeCommit()
        res := DllCall(NumGet(this.api, 88, "Ptr"), "UInt", session_id, "Ptr", commit.buff.Ptr, "Cdecl Int")
        return res ? commit : 0
    }

    ; (RimeCommit) => Int
    free_commit(commit) {
        return DllCall(NumGet(this.api, 92, "Ptr"), "Ptr", commit ? commit.buff.Ptr : 0, "Cdecl Int")
    }

    ; (UInt) => RimeContext or 0
    get_context(session_id) {
        context := RimeContext()
        res := DllCall(NumGet(this.api, 96, "Ptr"), "UInt", session_id, "Ptr", context.buff.Ptr, "Cdecl Int")
        return res ? context : 0
    }

    ; (RimeContext) => Int
    free_context(context) {
        return DllCall(NumGet(this.api, 100, "Ptr"), "Ptr", context ? context.buff.Ptr : 0, "Cdecl Int")
    }

    ; (UInt) => RimeStatus or 0
    get_status(session_id) {
        status := RimeStatus()
        res := DllCall(NumGet(this.api, 104, "Ptr"), "UInt", session_id, "Ptr", status.buff.Ptr, "Cdecl Int")
        return res ? status : 0
    }

    ; (RimeStatus) => Int
    free_status(status) {
        return DllCall(NumGet(this.api, 108, "Ptr"), "Ptr", status ? status.buff.Ptr : 0, "Cdecl Int")
    }

    ; (UInt, Str, Int) => void
    set_option(session_id, option, value) {
        DllCall(NumGet(this.api, 112, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(option).Ptr, "Int", value, "Cdecl")
    }

    ; (UInt, Str) => Int
    get_option(session_id, option) {
        return DllCall(NumGet(this.api, 116, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(option).Ptr, "Cdecl Int")
    }

    ; (UInt, Str, Str) => void
    set_property(session_id, prop, value) {
        DllCall(NumGet(this.api, 120, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(prop).Ptr, "Ptr", UTF8Buffer(value).Ptr, "Cdecl")
    }

    ; (UInt, Str, UInt) => Str
    get_property(session_id, prop, buffer_size) {
        buf := Buffer(buffer_size)
        res := DllCall(NumGet(this.api, 124, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(prop).Ptr, "Ptr", buf.Ptr, "UInt", buffer_size, "Cdecl Int")
        return res ? StrGet(buf.Ptr, "UTF-8") : ""
    }

    ; () => RimeSchemaList or 0
    get_schema_list() {
        list := RimeSchemaList()
        res := DllCall(NumGet(this.api, 128, "Ptr"), "Ptr", list.buff.Ptr, "Cdecl Int")
        return res ? list : 0
    }

    ; (RimeSchemaList) => void
    free_schema_list(schema_list) {
        DllCall(NumGet(this.api, 132, "Ptr"), "Ptr", schema_list ? schema_list.buff.Ptr : 0, "Cdecl")
    }

    ; (UInt, UInt) => Str
    get_current_schema(session_id, buffer_size) {
        buf := Buffer(buffer_size)
        res := DllCall(NumGet(this.api, 136, "Ptr"), "UInt", session_id, "Ptr", buf.Ptr, "UInt", buffer_size, "Cdecl Int")
        return res ? StrGet(buf.Ptr, "UTF-8") : ""
    }

    ; (UInt, Str) => Int
    select_schema(session_id, schema_id) {
        return DllCall(NumGet(this.api, 140, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(schema_id).Ptr, "Cdecl Int")
    }

    ; schema_open, offset 144
    ; config_open, offset 148
    ; config_close, offset 152
    ; config_get_bool, offset 156
    ; config_get_int, offset 160
    ; config_get_double, offset 164
    ; config_get_string, offset 168
    ; config_get_cstring, offset 172
    ; config_update_signature, offset 176
    ; config_begin_map, offset 180
    ; config_next, offset 184
    ; config_end, offset 188

    ; (UInt, Str) => Int
    simulate_key_sequence(session_id, key_sequence) {
        return DllCall(NumGet(this.api, 192, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(key_sequence).Ptr, "Cdecl Int")
    }

    ; register_module, offset 196
    ; find_module, offset 200
    ; run_task, offset 204

    ; () => Str
    get_shared_data_dir() {
        if p := DllCall(NumGet(this.api, 208, "Ptr"), "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; () => Str
    get_user_data_dir() {
        if p := DllCall(NumGet(this.api, 212, "Ptr"), "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; () => Str
    get_sync_dir() {
        if p := DllCall(NumGet(this.api, 216, "Ptr"), "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; () => Str
    get_user_id() {
        if p := DllCall(NumGet(this.api, 220, "Ptr"), "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; (UInt) => Str
    get_user_data_sync_dir(buffer_size) {
        buf := Buffer(buffer_size, 0)
        DllCall(NumGet(this.api, 224, "Ptr"), "Ptr", buf.Ptr, "UInt", buffer_size, "Cdecl")
        return StrGet(buf.Ptr, "UTF-8")
    }

    ; config_init, offset 228
    ; config_load_string, offset 232
    ; config_set_bool, offset 236
    ; config_set_int, offset 240
    ; config_set_double, offset 244
    ; config_set_string, offset 248
    ; config_get_item, offset 252
    ; config_set_item, offset 256
    ; config_clear, offset 260
    ; config_create_list, offset 264
    ; config_create_map, offset 268
    ; config_list_size, offset 272
    ; config_begin_list, offset 276

    ; (UInt) => Str
    get_input(session_id) {
        if p := DllCall(NumGet(this.api, 280, "Ptr"), "UInt", session_id, "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; (UInt) => UInt
    get_caret_pos(session_id) {
        return DllCall(NumGet(this.api, 284, "Ptr"), "UInt", session_id, "Cdecl UInt")
    }

    ; (UInt, UInt) => Int
    select_candidate(session_id, index) {
        return DllCall(NumGet(this.api, 288, "Ptr"), "UInt", session_id, "UInt", index, "Cdecl Int")
    }

    ; () => Str
    get_version() {
        if p := DllCall(NumGet(this.api, 292, "Ptr"), "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; (UInt, UInt) => void
    set_caret_pos(session_id, caret_pos) {
        DllCall(NumGet(this.api, 296, "Ptr"), "UInt", session_id, "UInt", caret_pos, "Cdecl")
    }

    ; (UInt, UInt) => Int
    select_candidate_on_current_page(session_id, index) {
        return DllCall(NumGet(this.api, 300, "Ptr"), "UInt", session_id, "UInt", index, "Cdecl Int")
    }

    ; (UInt) => RimeCandidateListIterator or 0
    candidate_list_begin(session_id) {
        iter := RimeCandidateListIterator()
        res := DllCall(NumGet(this.api, 304, "Ptr"), "UInt", session_id, "Ptr", iter.buff.Ptr, "Cdecl Int")
        return res ? iter : 0
    }

    ; (RimeCandidateListIterator) => Int
    candidate_list_next(iterator) {
        return DllCall(NumGet(this.api, 308, "Ptr"), "Ptr", iterator ? iterator.buff.Ptr : 0, "Cdecl Int")
    }

    ; (RimeCandidateListIterator) => void
    candidate_list_end(iterator) {
        DllCall(NumGet(this.api, 312, "Ptr"), "Ptr", iterator ? iterator.buff.Ptr : 0, "Cdecl")
    }

    ; user_config_open, offset 316

    ; (UInt, RimeCandidateListIterator, UInt) => Int
    candidate_list_from_index(session_id, iterator, index) {
        return DllCall(NumGet(this.api, 320, "Ptr"), "UInt", session_id, "Ptr", iterator ? iterator.buff.Ptr : 0, "UInt", index, "Cdecl Int")
    }

    ; () => Str
    get_prebuilt_data_dir() {
        if p := DllCall(NumGet(this.api, 324, "Ptr"), "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; () => Str
    get_staging_dir() {
        if p := DllCall(NumGet(this.api, 328, "Ptr"), "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; commit_proto, offset 332
    ; context_proto, offset 336
    ; status_proto, offset 340

    ; (UInt, Str, Int) => Str
    get_state_label(session_id, option_name, state) {
        if p := DllCall(NumGet(this.api, 344, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(option_name).Ptr, "Int", state, "Cdecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; (UInt, UInt) => Int
    delete_candidate(session_id, index) {
        return DllCall(NumGet(this.api, 348, "Ptr"), "UInt", session_id, "UInt", index, "Cdecl Int")
    }

    ; (UInt, UInt) => Int
    delete_candidate_on_current_page(session_id, index) {
        return DllCall(NumGet(this.api, 352, "Ptr"), "UInt", session_id, "UInt", index, "Cdecl Int")
    }

    ; get_state_label_abbreviated, offset 356
}
