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
DEFAULT_BUFFER_SIZE() {
    return 512
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
        this.buff := Buffer(RimeTraits.buffer_size(), 0)
        this.data_size := RimeTraits.buffer_size() - INT_SIZE()
    }

    static data_size_offset := (*) => 0
    static shared_data_dir_offset := (*) => RimeTraits.data_size_offset() + INT_SIZE()
    static user_data_dir_offset := (*) => RimeTraits.shared_data_dir_offset() + A_PtrSize
    static distribution_name_offset := (*) => RimeTraits.user_data_dir_offset() + A_PtrSize
    static distribution_code_name_offset := (*) => RimeTraits.distribution_name_offset() + A_PtrSize
    static distribution_version_offset := (*) => RimeTraits.distribution_code_name_offset() + A_PtrSize
    static app_name_offset := (*) => RimeTraits.distribution_version_offset() + A_PtrSize
    static modules_offset := (*) => RimeTraits.app_name_offset() + A_PtrSize
    static min_log_level_offset := (*) => RimeTraits.modules_offset() + A_PtrSize
    static log_dir_offset := (*) => RimeTraits.min_log_level_offset() + INT_SIZE()
    static prebuilt_data_dir_offset := (*) => RimeTraits.log_dir_offset() + A_PtrSize
    static staging_dir_offset := (*) => RimeTraits.prebuilt_data_dir_offset() + A_PtrSize
    static buffer_size := (*) => RimeTraits.staging_dir_offset() + A_PtrSize

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
        this.buff := Buffer(RimeComposition.buffer_size(), 0)
        if ptr {
            Loop RimeComposition.buffer_size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static lenth_offset := (*) => 0
    static cursor_pos_offset := (*) => RimeComposition.lenth_offset() + INT_SIZE()
    static sel_start_offset := (*) => RimeComposition.cursor_pos_offset() + INT_SIZE()
    static sel_end_offset := (*) => RimeComposition.sel_start_offset() + INT_SIZE()
    static preedit_offset := (*) => RimeComposition.sel_end_offset() + INT_SIZE()
    static buffer_size := (*) => RimeComposition.preedit_offset() + A_PtrSize

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
        this.buff := Buffer(RimeCandidate.buffer_size(), 0)
        if ptr {
            Loop RimeCandidate.buffer_size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static text_offset := (*) => 0
    static comment_offset := (*) => RimeCandidate.text_offset() + A_PtrSize
    static reserved_offset := (*) => RimeCandidate.comment_offset() + A_PtrSize
    static buffer_size := (*) => RimeCandidate.reserved_offset() + A_PtrSize

    text {
        get => UTF8StrGet(this.buff.Ptr, RimeCandidate.text_offset())
    }
    comment {
        get => UTF8StrGet(this.buff.Ptr, RimeCandidate.comment_offset())
    }
} ; RimeCandidate

class RimeMenu {
    __New(ptr := 0) {
        this.buff := Buffer(RimeMenu.buffer_size(), 0)
        if ptr {
            Loop RimeMenu.buffer_size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static page_size_offset := (*) => 0
    static page_no_offset := (*) => RimeMenu.page_size_offset() + INT_SIZE()
    static is_last_page_offset := (*) => RimeMenu.page_no_offset() + INT_SIZE()
    static highlighted_candidate_index_offset := (*) => RimeMenu.is_last_page_offset() + INT_SIZE()
    static num_candidates_offset := (*) => RimeMenu.highlighted_candidate_index_offset() + INT_SIZE()
    static candidates_offset := (*) => RimeMenu.num_candidates_offset() + INT_SIZE()
    static select_keys_offset := (*) => RimeMenu.candidates_offset() + A_PtrSize
    static buffer_size := (*) => RimeMenu.select_keys_offset() + A_PtrSize

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
                    local ptr := p + (A_Index - 1) * RimeCandidate.buffer_size()
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
        this.buff := Buffer(RimeCommit.buffer_size(), 0)
        this.data_size := RimeCommit.buffer_size() - INT_SIZE()
        if ptr {
            Loop RimeCommit.buffer_size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static data_size_offset := (*) => 0
    static text_offset := (*) => RimeCommit.data_size_offset() + INT_SIZE()
    static buffer_size := (*) => RimeCommit.text_offset() + A_PtrSize

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

    static data_size_offset() {
        return 0
    }
    static composition_offset() {
        return RimeContext.data_size_offset() + INT_SIZE()
    }
    static menu_offset() {
        return RimeContext.composition_offset() + RimeComposition.buffer_size()
    }
    static commit_text_preview_offset() {
        return RimeContext.menu_offset() + RimeMenu.buffer_size()
    }
    static select_labels_offset() {
        return RimeContext.commit_text_preview_offset() + A_PtrSize
    }
    static size() {
        return RimeContext.select_labels_offset() + A_PtrSize
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
        this.buff := Buffer(RimeStatus.buffer_size(), 0)
        this.data_size := RimeStatus.buffer_size() - INT_SIZE()
        if ptr {
            Loop RimeStatus.buffer_size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static data_size_offset := (*) => 0
    static schema_id_offset := (*) => RimeStatus.data_size_offset() + INT_SIZE()
    static schema_name_offset := (*) => RimeStatus.schema_id_offset() + A_PtrSize
    static is_disabled_offset := (*) => RimeStatus.schema_name_offset() + A_PtrSize
    static is_composing_offset := (*) => RimeStatus.is_disabled_offset() + INT_SIZE()
    static is_ascii_mode_offset := (*) => RimeStatus.is_composing_offset() + INT_SIZE()
    static is_full_shape_offset := (*) => RimeStatus.is_ascii_mode_offset() + INT_SIZE()
    static is_simplified_offset := (*) => RimeStatus.is_full_shape_offset() + INT_SIZE()
    static is_traditional_offset := (*) => RimeStatus.is_simplified_offset() + INT_SIZE()
    static is_ascii_punct_offset := (*) => RimeStatus.is_traditional_offset() + INT_SIZE()
    static buffer_size := (*) => RimeStatus.is_ascii_punct_offset() + INT_SIZE()

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
        this.buff := Buffer(RimeCandidateListIterator.buffer_size(), 0)
    }

    static ptr_offset := (*) => 0
    static index_offset := (*) => RimeCandidateListIterator.ptr_offset() + A_PtrSize
    static candidate_offset := (*) => RimeCandidateListIterator.index_offset() + INT_SIZE()
    static buffer_size := (*) => RimeCandidateListIterator.candidate_offset() + RimeCandidate.buffer_size()

    index {
        get => NumGet(this.buff, RimeCandidateListIterator.index_offset(), "Int")
    }
    candidate {
        get => RimeCandidate(this.buff.Ptr + RimeCandidateListIterator.candidate_offset())
    }
} ; RimeCandidateListIterator

class RimeConfig {
    __New(ptr := 0) {
        this.buff := Buffer(RimeConfig.buffer_size(), 0)
        if ptr {
            Loop RimeConfig.buffer_size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static ptr_offset := (*) => 0
    static buffer_size := (*) => RimeConfig.ptr_offset() + A_PtrSize

    ptr {
        get => NumGet(this.buff.Ptr, RimeConfig.ptr_offset(), "Ptr")
    }
} ; RimeConfig

class RimeConfigIterator {
    __New(ptr := 0) {
        this.buff := Buffer(RimeConfigIterator.buffer_size(), 0)
        if ptr {
            Loop RimeConfigIterator.buffer_size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static list_offset := (*) => 0
    static map_offset := (*) => RimeConfigIterator.list_offset() + A_PtrSize
    static index_offset := (*) => RimeConfigIterator.map_offset() + A_PtrSize
    static key_offset := (*) => RimeConfigIterator.index_offset() + INT_SIZE()
    static path_offset := (*) => RimeConfigIterator.key_offset() + A_PtrSize
    static buffer_size := (*) => RimeConfigIterator.path_offset() + A_PtrSize

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
        this.buff := Buffer(RimeSchemaListItem.buffer_size(), 0)
        if ptr {
            Loop RimeSchemaListItem.buffer_size() {
                byte := NumGet(ptr, A_Index - 1, "Char")
                NumPut("Char", byte, this.buff, A_Index - 1)
            }
        }
    }

    static schema_id_offset := (*) => 0
    static name_offset := (*) => RimeSchemaListItem.schema_id_offset() + A_PtrSize
    static reserved_offset := (*) => RimeSchemaListItem.name_offset() + A_PtrSize
    static buffer_size := (*) => RimeSchemaListItem.reserved_offset() + A_PtrSize

    schema_id {
        get => UTF8StrGet(this.buff.Ptr, RimeSchemaListItem.schema_id_offset())
    }
    name {
        get => UTF8StrGet(this.buff.Ptr, RimeSchemaListItem.name_offset())
    }
} ; RimeSchemaListItem

class RimeSchemaList {
    __New() {
        this.buff := Buffer(RimeSchemaList.buffer_size(), 0)
    }

    static size_offset := (*) => 0
    static list_offset := (*) => RimeSchemaList.size_offset() + A_PtrSize ; size_t size
    static buffer_size := (*) => RimeSchemaList.list_offset() + A_PtrSize

    size {
        get => NumGet(this.buff, RimeSchemaList.size_offset(), "UInt") ; returns size_t
    }
    list {
        get {
            sl := Array()
            if p := NumGet(this.buff.Ptr, RimeSchemaList.list_offset(), "Ptr") {
                Loop this.size {
                    ptr := p + (A_Index - 1) * RimeSchemaListItem.buffer_size()
                    sl.Push(RimeSchemaListItem(ptr))
                }
            }
            return sl
        }
    }
} ; RimeSchemaList

/**
 * Do not exist in 1.8.5 and before
 */
class RimeStringSlice {
    __New(str := "", length := 0) {
        this.buff := Buffer(RimeStringSlice.buffer_size(), 0)
        this.str := str
        this.length := length
    }

    static str_offset := (*) => 0
    static length_offset := (*) => RimeStringSlice.str_offset() + A_PtrSize
    static buffer_size := (*) => RimeStringSlice.length_offset() + A_PtrSize ; size_t length

    str {
        get => UTF8StrGet(this.buff.Ptr, RimeStringSlice.str_offset())
        set => this.__str := UTF8StrPut(Value, this.buff.Ptr, RimeStringSlice.str_offset())
    }
    length {
        get => NumGet(this.buff, RimeStringSlice.length_offset(), "UInt") ; returns size_t
        set => NumPut("UInt", Value, this.buff, RimeStringSlice.length_offset())
    }
} ; RimeStringSlice

; Just a template struct
; Check out the actual example RimeLeversApi
; RimeCustomApi

class RimeModule {
    __New(rime := 0, module_name := "") {
        this.buff := 0
        this.module := 0
        if rime and module_name
            this.module := rime.find_module(module_name)
        if not this.module {
            this.buff := Buffer(RimeModule.buffer_size(), 0)
            this.data_size := RimeModule.buffer_size() - INT_SIZE()
        }
    }

    static data_size_offset := (*) => 0
    static module_name_offset := (*) => RimeModule.data_size_offset() + INT_SIZE()
    static initialize_offset := (*) => RimeModule.module_name_offset() + A_PtrSize
    static finalize_offset := (*) => RimeModule.initialize_offset() + A_PtrSize
    static get_api_offset := (*) => RimeModule.finalize_offset() + A_PtrSize
    static buffer_size := (*) => RimeModule.get_api_offset() + A_PtrSize

    ptr := (*) => this.buff ? this.buff.Ptr : this.module

    data_size {
        get => NumGet(this.ptr(), RimeModule.data_size_offset(), "Int")
        set => NumPut("Int", Value, this.ptr(), RimeModule.data_size_offset())
    }
    module_name {
        get => UTF8StrGet(this.ptr(), RimeModule.module_name_offset())
        set => this.__module_name := UTF8StrPut(Value, this.ptr(), RimeModule.module_name_offset())
    }
    initialize := (*) => DllCall(NumGet(this.ptr(), RimeModule.initialize_offset(), "Ptr"), "Cdecl")
    finalize := (*) => DllCall(NumGet(this.ptr(), RimeModule.finalize_offset(), "Ptr"), "Cdecl")
    get_api := (*) => DllCall(NumGet(this.ptr(), RimeModule.get_api_offset(), "Ptr"), "Cdecl Ptr")
} ; RimeModule

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

    /**
     * Set the notification handler
     * 
     * @param handler a function that takes four parameters (type in ahk / type in c):
     * 
     * `Ptr` / `void *`
     * 
     * `UInt` / `RimeSessionId`
     * 
     * `Ptr` / `const char *`
     * 
     * `Ptr` / `const char *`
     * @param context_object `Ptr` in ahk, `void *` in librime
     */
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
    get_property(session_id, prop, buffer_size := DEFAULT_BUFFER_SIZE()) {
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
    get_current_schema(session_id, buffer_size := DEFAULT_BUFFER_SIZE()) {
        buf := Buffer(buffer_size)
        res := DllCall(NumGet(this.api, 136, "Ptr"), "UInt", session_id, "Ptr", buf.Ptr, "UInt", buffer_size, "Cdecl Int")
        return res ? StrGet(buf.Ptr, "UTF-8") : ""
    }

    ; (UInt, Str) => Int
    select_schema(session_id, schema_id) {
        return DllCall(NumGet(this.api, 140, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(schema_id).Ptr, "Cdecl Int")
    }

    /**
     * Open a schema
     * 
     * @param schema_id type of `Str`
     * @returns type of `RimeConfig` on success, `0` on failure
     */
    schema_open(schema_id) {
        config := RimeConfig()
        res := DllCall(NumGet(this.api, 144, "Ptr"), "Ptr", UTF8Buffer(schema_id).Ptr, "Ptr", config.buff.Ptr, "Cdecl Int")
        return res ? config : 0
    }

    /**
     * Open a config
     * 
     * @param config_id type of `Str`
     * @returns type of `RimeConfig` on success, `0` on failure
     */
    config_open(config_id) {
        config := RimeConfig()
        res := DllCall(NumGet(this.api, 148, "Ptr"), "Ptr", UTF8Buffer(config_id).Ptr, "Ptr", config.buff.Ptr, "Cdecl Int")
        return res ? config : 0
    }

    ; (RimeConfig) => void
    /**
     * Close a config
     * 
     * @param config type of `RimeConfig`
     * @returns `True` on success, `False` on failure
     */
    config_close(config) {
        return DllCall(NumGet(this.api, 152, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Cdecl Int")
    }

    /**
     * Test the existence of a boolean value in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` if exist, `False` if not
     */
    config_exist_bool(config, key) {
        buf := Buffer(INT_SIZE())
        return DllCall(NumGet(this.api, 156, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
    }

    /**
     * Get a boolean value from the config
     * 
     * Suggest to use `config_exist_bool` before this function, or use `config_test_get_bool` instead
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns the boolean value in the config if exists, or `False` if not exists 
     */
    config_get_bool(config, key) {
        buf := Buffer(INT_SIZE())
        res := DllCall(NumGet(this.api, 156, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
        return res ? NumGet(buf, "Int") : 0
    }

    /**
     * Test and get a boolean value from the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param value pass by reference, type of `Int`
     * @returns `True` on success, `False` on failure
     */
    config_test_get_bool(config, key, &value) {
        buf := Buffer(INT_SIZE())
        if res := DllCall(NumGet(this.api, 156, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
            value := NumGet(buf, "Int")
        return res
    }

    /**
     * Test the existence of an integer in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` if exist, `False` if not
     */
    config_exist_int(config, key) {
        buf := Buffer(INT_SIZE())
        return DllCall(NumGet(this.api, 160, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
    }

    /**
     * Get integer from the config
     * 
     * Suggest to use `config_exist_int` before this function, or use `config_test_get_int` instead
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns the integer in the config if exists, or `0` if not exists
     */
    config_get_int(config, key) {
        buf := Buffer(INT_SIZE())
        res := DllCall(NumGet(this.api, 160, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
        return res ? NumGet(buf, "Int") : 0
    }

    /**
     * Test and get an integer from the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param value pass by reference, type of `Double`
     * @returns `True` on success, `False` on failure
     */
    config_test_get_int(config, key, &value) {
        buf := Buffer(INT_SIZE())
        if res := DllCall(NumGet(this.api, 160, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
            value := NumGet(buf, "Int")
        return res
    }

    /**
     * Test the existence of a double in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` if exist, `False` if not
     */
    config_exist_double(config, key) {
        buf := Buffer(INT_SIZE() * 2)
        return DllCall(NumGet(this.api, 164, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
    }

    ; (RimeConfig, Str) => Double
    /**
     * Get a double from the config
     * 
     * Suggest to use `config_exist_double` before this function, or use `config_test_get_double` instead
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns the double value in the config if exists, or `False` if not exists
     */
    config_get_double(config, key) {
        buf := Buffer(INT_SIZE() * 2)
        res := DllCall(NumGet(this.api, 164, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
        return res ? NumGet(buf, "Double") : 0
    }

    /**
     * Test and get a double from the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param value pass by reference, type of `Double`
     * @returns `True` on success, `False` on failure
     */
    config_test_get_double(config, key, &value) {
        buf := Buffer(INT_SIZE() * 2)
        if res := DllCall(NumGet(this.api, 164, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "Cdecl Int")
            value := NumGet(buf, "Double")
        return res
    }

    /**
     * Get a string from the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param buffer_size default 512
     * @returns the string in the config, or empty string if failed
     */
    config_get_string(config, key, buffer_size := DEFAULT_BUFFER_SIZE()) {
        buf := Buffer(buffer_size)
        res := DllCall(NumGet(this.api, 168, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", buf.Ptr, "UInt", buffer_size, "Cdecl Int")
        return res ? StrGet(buf.Ptr, "UTF-8") : ""
    }

    ; TODO: it seems this function fetches the raw string of yaml, need furthre confirming
    ; config_get_cstring, offset 172

    /**
     * 
     * @param config type of `RimeConfig`
     * @param signer type of `Str`
     * @returns `True` on success, `False` on failure
     */
    config_update_signature(config, signer) {
        return DllCall(NumGet(this.api, 172, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(signer).Ptr, "Cdecl Int")
    }

    /**
     * Get the begin iterator of a map from the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns iterator of `RimeConfigIterator` on success, `0` on failure
     */
    config_begin_map(config, key) {
        iterator := RimeConfigIterator()
        res := DllCall(NumGet(this.api, 180, "Ptr"), "Ptr", iterator.buff.Ptr, "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Cdecl Int")
        return res ? iterator : 0
    }

    ; config_next, offset 184
    /**
     * Increment the config iterator
     * 
     * @param iterator type of `RimeConfigIterator`
     * @returns `True` if not end, `False` if end
     */
    config_next(iterator) {
        return DllCall(NumGet(this.api, 184, "Ptr"), "Ptr", iterator ? iterator.buff.Ptr : 0, "Cdecl Int")
    }

    /**
     * Cleanup the config iterator
     * 
     * @param iterator type of `RimeConfigIterator`
     */
    config_end(iterator) {
        DllCall(NumGet(this.api, 188, "Ptr"), "Ptr", iterator ? iterator.buff.Ptr : 0, "Cdecl")
    }

    ; (UInt, Str) => Int
    simulate_key_sequence(session_id, key_sequence) {
        return DllCall(NumGet(this.api, 192, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(key_sequence).Ptr, "Cdecl Int")
    }

    /**
     * 
     * @param module type of `RimeModule`
     * @returns `True` on success, `False` on failure
     */
    register_module(module) {
        return DllCall(NumGet(this.api, 196, "Ptr"), "Ptr", module ? module.buff.Ptr : 0, "Cdecl Int")
    }

    find_module := module_name => DllCall(NumGet(this.api, 200, "Ptr"), "Ptr", UTF8Buffer(module_name).Ptr, "Cdecl Ptr")

    /**
     * Run task
     * 
     * @param task_name type of `Str`
     * @returns `True` on success, `False` on failure
     */
    run_task(task_name) {
        return DllCall(NumGet(this.api, 204, "Ptr"), "Ptr", UTF8Buffer(task_name).Ptr, "Cdecl Int")
    }

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
    get_user_data_sync_dir(buffer_size := DEFAULT_BUFFER_SIZE()) {
        buf := Buffer(buffer_size, 0)
        DllCall(NumGet(this.api, 224, "Ptr"), "Ptr", buf.Ptr, "UInt", buffer_size, "Cdecl")
        return StrGet(buf.Ptr, "UTF-8")
    }

    /**
     * Initialize an empty config object
     * 
     * should call `config_close` to free the object
     * 
     * @returns `RimeConfig` on success, `0` on failure
     */
    config_init() {
        config := RimeConfig()
        res := DllCall(NumGet(this.api, 228, "Ptr"), "Ptr", config.buff.Ptr, "Cdecl Int")
        return res ? config : 0
    }

    /**
     * Create config from a yaml string
     * 
     * @param yaml type of `Str`
     * @returns `RimeConfig` on success, `0` on failure
     */
    config_load_string(yaml) {
        config := RimeConfig()
        res := DllCall(NumGet(this.api, 232, "Ptr"), "Ptr", config.buff.Ptr, "Ptr", UTF8Buffer(yaml).Ptr, "Cdecl Int")
        return res ? config : 0
    }

    /**
     * Set boolean value to config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param value `True` or `False`
     * @returns `True` on success, `False` on failure
     */
    config_set_bool(config, key, value) {
        return DllCall(NumGet(this.api, 236, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Int", value, "Cdecl Int")
    }

    /**
     * Set integer to config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param value type of `Int`
     * @returns `True` on success, `False` on failure
     */
    config_set_int(config, key, value) {
        return DllCall(NumGet(this.api, 240, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Int", value, "Cdecl Int")
    }

    /**
     * Set double to config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param value type of `Double`
     * @returns `True` on success, `False` on failure
     */
    config_set_double(config, key, value) {
        return DllCall(NumGet(this.api, 244, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Double", value, "Cdecl Int")
    }

    /**
     * Set string to config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param value type of `Double`
     * @returns `True` on success, `False` on failure
     */
    config_set_string(config, key, value) {
        return DllCall(NumGet(this.api, 248, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", UTF8Buffer(value).Ptr, "Cdecl Int")
    }

    /**
     * Get item from the config
     * 
     * @param config type of `RimeConfig
     * @param key type of `Str`
     * @returns `RimeConfig` onsuccess, `0` on failure
     */
    config_get_item(config, key) {
        value := RimeConfig()
        res := DllCall(NumGet(this.api, 252, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", value.buff.Ptr, "Cdecl Int")
        return res ? value : 0
    }

    /**
     * Set item into the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @param value type of `RimeConfig`
     * @returns `True` on success, `False` on failure
     */
    config_set_item(config, key, value) {
        return DllCall(NumGet(this.api, 256, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Ptr", value ? value.buff.Ptr : 0, "Cdecl Int")
    }

    /**
     * Clear item of the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` on success, `False` on failure
     */
    config_clear(config, key) {
        return DllCall(NumGet(this.api, 260, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Cdecl Int")
    }

    /**
     * Create a list in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` on success, `False` on failure
     */
    config_create_list(config, key) {
        return DllCall(NumGet(this.api, 264, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Cdecl Int")
    }

    /**
     * Create a map in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` on success, `False` on failure
     */
    config_create_map(config, key) {
        return DllCall(NumGet(this.api, 268, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Cdecl Int")
    }

    /**
     * Get size of list in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns the size of desired list
     */
    config_list_size(config, key) {
        return DllCall(NumGet(this.api, 272, "Ptr"), "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Cdecl UInt") ; returns size_t
    }

    /**
     * Get the begin iterator of a list from the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns iterator of `RimeConfigIterator` on success, `0` on failure
     */
    config_begin_list(config, key) {
        iterator := RimeConfigIterator()
        res := DllCall(NumGet(this.api, 276, "Ptr"), "Ptr", iterator.buff.Ptr, "Ptr", config ? config.buff.Ptr : 0, "Ptr", UTF8Buffer(key).Ptr, "Cdecl Int")
        return res ? iterator : 0
    }

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

    /**
     * Open user config
     * 
     * @param config_id type of `Str`
     * @returns `RimConfig` on success, `0` on failure`
     */
    user_config_open(config_id) {
        config := RimeConfig()
        res := DllCall(NumGet(this.api, 316, "Ptr"), "Ptr", UTF8Buffer(config_id).Ptr, "Ptr", config.buff.Ptr, "Cdecl Int")
        return res ? config : 0
    }

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

    ; Deprecated - nullptr
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

    /**
     * This API returns a struct `rime_string_slice_t` instead of a pointer to it. Due to the limitation of `DllCall`, there is currently no way to retrieve a struct with size larger than 64 bits. It will only work with 32-bit librime and AutoHotkey.
     * 
     * This API is not available in librime 1.8.5 and below.
     * 
     * @param session_id type of `UInt`
     * @param option_name type of `Str`
     * @param state `True` or `False`
     * @param abbreviated `True` or `False`
     * @returns `RimeStringSlice` on success, `0` on failure
     */
    get_state_label_abbreviated(session_id, option_name, state, abbreviated) {
        if this.data_size < 356 or A_PtrSize > 4
            return 0
        res := DllCall(NumGet(this.api, 356, "Ptr"), "UInt", session_id, "Ptr", UTF8Buffer(option_name).Ptr, "Int", state, "Int", abbreviated, "Cdecl Int64")
        try
            str := StrGet(res & 0xffffffff, "UTF-8")
        catch as e
            return 0
        return RimeStringSlice(str, res >> 32)
    }
}
