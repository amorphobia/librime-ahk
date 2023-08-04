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
 
INT_SIZE() {
    return 4
}
INT_PAD() {
    return A_PtrSize == 8 ? 4 : 0
}
DEFAULT_BUFFER_SIZE() {
    return 512
}

c_str(val, encoding := "UTF-8") {
    buf := Buffer()
    if val {
        buf := Buffer(StrPut(val, encoding), 0)
        StrPut(val, buf, encoding)
    }
    return buf
}

c_str_array(val_array, encoding := "UTF-8") {
    str_ptrs := Buffer((val_array.Length + 1) * A_PtrSize, 0)
    str_bufs := Array()
    for index, val in val_array {
        if not IsSet(val)
            break
        buff := c_str(val, encoding)
        NumPut("Ptr", buff.Ptr, str_ptrs, (index - 1) * A_PtrSize)
        str_bufs.Push(buff)
    }
    return {
        ptrs: str_ptrs,
        bufs: str_bufs
    }
}

/**
 * The base class to wrap a struct in librime
 * 
 * Traits
 * 
 * `struct_ptr()` - returns the pointer to the underlying data, which could be stored in `Buffer` or possessed by librime
 * 
 * `static struct_size()` - returns the size of the underlying data in bytes
 */
class RimeStruct extends Class {
    bytes_put(src, tgt := this.struct_ptr(), offset := 0, length := %Type(this)%.struct_size()) {
        if src
            Loop length {
                byte := NumGet(src, A_Index - 1, "Char")
                NumPut("Char", byte, tgt, A_Index - 1)
            }
    }
    num_get(offset := 0, type := "Int") {
        return NumGet(this.struct_ptr(), offset, type)
    }
    num_put(type := "Int", val := 0, offset := 0) {
        NumPut(type, val, this.struct_ptr(), offset)
    }
    c_str_get(src := this.struct_ptr(), offset := 0, encoding := "UTF-8") {
        return (p := NumGet(src, offset, "Ptr")) ? StrGet(p, encoding) : ""
    }
    c_str_put(val, tgt := this.struct_ptr(), offset := 0, encoding := "UTF-8") {
        buf := c_str(val, encoding)
        NumPut("Ptr", buf.Ptr, tgt, offset)
        return buf
    }
    c_str_array_get(offset, encoding := "UTF-8") {
        res := Array()
        if ptr := this.num_get(offset, "Ptr")
            Loop {
                if not val := this.c_str_get(ptr, (A_Index - 1) * A_PtrSize, encoding)
                    break
                res.Push(val)
            }
        return res
    }
    c_str_array_put(val_array, tgt := this.struct_ptr(), offset := 0, encoding := "UTF-8") {
        arr_buf := c_str_array(val_array, encoding)
        NumPut("Ptr", arr_buf.ptrs.Ptr, tgt, offset)
        return arr_buf
    }
    struct_array_get(offset, length, struct) {
        res := Array()
        if ptr := this.num_get(offset, "Ptr")
            Loop length {
                res.Push(struct.Call(ptr + (A_Index - 1) * struct.struct_size()))
            }
        return res
    }
} ; RimeStruct

/**
 * The class to wrap a struct with version control
 * 
 * Traits
 * 
 * `static data_size_offset()` - returns the pointer to `data_size`
 */
class RimeVersionedStruct extends RimeStruct {
    data_size {
        get => this.num_get(%Type(this)%.data_size_offset())
    }

    /**
     * The method is **NOT** static
     * @param member type of `Str`
     * @returns `True` if has member, `False` if not
     */
    has_member(member) {
        offset := member . "_offset"
        if not %Type(this)%.HasMethod(offset)
            return False
        return this.data_size + INT_SIZE() > %Type(this)%.%offset%()
    }

    /**
     * Assume member is a non-null pointer in this struct
     * @param member type of `Str`
     * @returns `True` if member has value, `False` if no member or null
     */
    provided(member) {
        return this.has_member(member) and this.%member%
    }
}

class RimeApiStruct extends RimeVersionedStruct {
    fp(offset) {
        return this.num_get(offset, "Ptr")
    }

    /**
     * Clients should test if an api function is available in the current version before calling it.
     * @param func type of `Str`
     * @returns `True` if API available, `False` if not
     */
    api_available(func) {
        return this.has_member(func) and this.%func%
    }
}

class RimeTraits extends RimeVersionedStruct {
    __New() {
        this.buff := Buffer(RimeTraits.struct_size(), 0)
        this.data_size := RimeTraits.struct_size() - INT_SIZE()
    }

    static data_size_offset := (*) => 0
    static shared_data_dir_offset := (*) => RimeTraits.data_size_offset() + INT_SIZE() + INT_PAD()
    static user_data_dir_offset := (*) => RimeTraits.shared_data_dir_offset() + A_PtrSize
    static distribution_name_offset := (*) => RimeTraits.user_data_dir_offset() + A_PtrSize
    static distribution_code_name_offset := (*) => RimeTraits.distribution_name_offset() + A_PtrSize
    static distribution_version_offset := (*) => RimeTraits.distribution_code_name_offset() + A_PtrSize
    static app_name_offset := (*) => RimeTraits.distribution_version_offset() + A_PtrSize
    static modules_offset := (*) => RimeTraits.app_name_offset() + A_PtrSize
    static min_log_level_offset := (*) => RimeTraits.modules_offset() + A_PtrSize
    static log_dir_offset := (*) => RimeTraits.min_log_level_offset() + INT_SIZE() + INT_PAD()
    static prebuilt_data_dir_offset := (*) => RimeTraits.log_dir_offset() + A_PtrSize
    static staging_dir_offset := (*) => RimeTraits.prebuilt_data_dir_offset() + A_PtrSize
    static struct_size := (*) => RimeTraits.staging_dir_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    data_size {
        set => this.num_put(, Value, RimeTraits.data_size_offset())
    }
    shared_data_dir {
        get => this.c_str_get(, RimeTraits.shared_data_dir_offset(), "CP0")
        set => this.__shared_data_dir := this.c_str_put(Value, , RimeTraits.shared_data_dir_offset(), "CP0")
    }
    user_data_dir {
        get => this.c_str_get(, RimeTraits.user_data_dir_offset(), "CP0")
        set => this.__user_data_dir := this.c_str_put(Value, , RimeTraits.user_data_dir_offset(), "CP0")
    }
    distribution_name {
        get => this.c_str_get(, RimeTraits.distribution_name_offset())
        set => this.__distribution_name := this.c_str_put(Value, , RimeTraits.distribution_name_offset())
    }
    distribution_code_name {
        get => this.c_str_get(, RimeTraits.distribution_code_name_offset())
        set => this.__distribution_code_name := this.c_str_put(Value, , RimeTraits.distribution_code_name_offset())
    }
    distribution_version {
        get => this.c_str_get(, RimeTraits.distribution_version_offset())
        set => this.__distribution_version := this.c_str_put(Value, , RimeTraits.distribution_version_offset())
    }
    app_name {
        get => this.c_str_get(, RimeTraits.app_name_offset())
        set => this.__app_name := this.c_str_put(Value, , RimeTraits.app_name_offset())
    }
    modules {
        get => this.c_str_array_get(RimeTraits.modules_offset())
        set => this.__modules := this.c_str_array_put(Value, , RimeTraits.modules_offset())
    }
    min_log_level {
        get => this.num_get(RimeTraits.min_log_level_offset())
        set => this.num_put(, Value, RimeTraits.min_log_level_offset())
    }
    log_dir {
        get => this.c_str_get(, RimeTraits.log_dir_offset())
        set => this.__log_dir := this.c_str_put(Value, , RimeTraits.log_dir_offset())
    }
    prebuilt_data_dir {
        get => this.c_str_get(, RimeTraits.prebuilt_data_dir_offset(), "CP0")
        set => this.__prebuilt_data_dir := this.c_str_put(Value, , RimeTraits.prebuilt_data_dir_offset(), "CP0")
    }
    staging_dir {
        get => this.c_str_get(, RimeTraits.staging_dir_offset(), "CP0")
        set => this.__staging_dir := this.c_str_put(Value, , RimeTraits.staging_dir_offset(), "CP0")
    }
} ; RimeTraits

class RimeComposition extends RimeStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeComposition.struct_size(), 0)
        this.bytes_put(ptr)
    }

    static length_offset := (*) => 0
    static cursor_pos_offset := (*) => RimeComposition.length_offset() + INT_SIZE()
    static sel_start_offset := (*) => RimeComposition.cursor_pos_offset() + INT_SIZE()
    static sel_end_offset := (*) => RimeComposition.sel_start_offset() + INT_SIZE()
    static preedit_offset := (*) => RimeComposition.sel_end_offset() + INT_SIZE()
    static struct_size := (*) => RimeComposition.preedit_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    length {
        get => this.num_get(RimeComposition.length_offset())
    }
    cursor_pos {
        get => this.num_get(RimeComposition.cursor_pos_offset())
    }
    sel_start {
        get => this.num_get(RimeComposition.sel_start_offset())
    }
    sel_end {
        get => this.num_get(RimeComposition.sel_end_offset())
    }
    preedit {
        get => this.c_str_get(, RimeComposition.preedit_offset())
    }
} ; RimeComposition

class RimeCandidate extends RimeStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeCandidate.struct_size(), 0)
        this.bytes_put(ptr)
    }

    static text_offset := (*) => 0
    static comment_offset := (*) => RimeCandidate.text_offset() + A_PtrSize
    static reserved_offset := (*) => RimeCandidate.comment_offset() + A_PtrSize
    static struct_size := (*) => RimeCandidate.reserved_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    text {
        get => this.c_str_get(, RimeCandidate.text_offset())
    }
    comment {
        get => this.c_str_get(, RimeCandidate.comment_offset())
    }
} ; RimeCandidate

class RimeMenu extends RimeStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeMenu.struct_size(), 0)
        this.bytes_put(ptr)
    }

    static page_size_offset := (*) => 0
    static page_no_offset := (*) => RimeMenu.page_size_offset() + INT_SIZE()
    static is_last_page_offset := (*) => RimeMenu.page_no_offset() + INT_SIZE()
    static highlighted_candidate_index_offset := (*) => RimeMenu.is_last_page_offset() + INT_SIZE()
    static num_candidates_offset := (*) => RimeMenu.highlighted_candidate_index_offset() + INT_SIZE()
    static candidates_offset := (*) => RimeMenu.num_candidates_offset() + INT_SIZE() + INT_PAD()
    static select_keys_offset := (*) => RimeMenu.candidates_offset() + A_PtrSize
    static struct_size := (*) => RimeMenu.select_keys_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    page_size {
        get => this.num_get(RimeMenu.page_size_offset())
    }
    page_no {
        get => this.num_get(RimeMenu.page_no_offset())
    }
    is_last_page {
        get => this.num_get(RimeMenu.is_last_page_offset())
    }
    highlighted_candidate_index {
        get => this.num_get(RimeMenu.highlighted_candidate_index_offset())
    }
    num_candidates {
        get => this.num_get(RimeMenu.num_candidates_offset())
    }
    candidates {
        get => this.struct_array_get(RimeMenu.candidates_offset(), this.num_candidates, RimeCandidate)
    }
    select_keys {
        get => this.c_str_get(, RimeMenu.select_keys_offset())
    }
} ; RimeMenu

class RimeCommit extends RimeVersionedStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeCommit.struct_size(), 0)
        this.data_size := RimeCommit.struct_size() - INT_SIZE()
        this.bytes_put(ptr)
    }

    static data_size_offset := (*) => 0
    static text_offset := (*) => RimeCommit.data_size_offset() + INT_SIZE() + INT_PAD()
    static struct_size := (*) => RimeCommit.text_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    data_size {
        set => this.num_put(, Value, RimeCommit.data_size_offset())
    }
    text {
        get => this.c_str_get(, RimeCommit.text_offset())
    }
} ; RimeCommit

class RimeContext extends RimeVersionedStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeContext.struct_size(), 0)
        this.data_size := RimeContext.struct_size() - INT_SIZE()
        this.bytes_put(ptr)
    }

    static data_size_offset := (*) => 0
    static composition_offset := (*) => RimeContext.data_size_offset() + INT_SIZE() + INT_PAD()
    static menu_offset := (*) => RimeContext.composition_offset() + RimeComposition.struct_size()
    static commit_text_preview_offset := (*) => RimeContext.menu_offset() + RimeMenu.struct_size()
    static select_labels_offset := (*) => RimeContext.commit_text_preview_offset() + A_PtrSize
    static struct_size := (*) => RimeContext.select_labels_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    data_size {
        set => this.num_put(, Value, RimeContext.data_size_offset())
    }
    composition {
        get => RimeComposition(this.struct_ptr() + RimeContext.composition_offset())
    }
    menu {
        get => RimeMenu(this.struct_ptr() + RimeContext.menu_offset())
    }
} ; RimeContext

class RimeStatus extends RimeVersionedStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeStatus.struct_size(), 0)
        this.data_size := RimeStatus.struct_size() - INT_SIZE()
        this.bytes_put(ptr)
    }

    static data_size_offset := (*) => 0
    static schema_id_offset := (*) => RimeStatus.data_size_offset() + INT_SIZE() + INT_PAD()
    static schema_name_offset := (*) => RimeStatus.schema_id_offset() + A_PtrSize
    static is_disabled_offset := (*) => RimeStatus.schema_name_offset() + A_PtrSize
    static is_composing_offset := (*) => RimeStatus.is_disabled_offset() + INT_SIZE()
    static is_ascii_mode_offset := (*) => RimeStatus.is_composing_offset() + INT_SIZE()
    static is_full_shape_offset := (*) => RimeStatus.is_ascii_mode_offset() + INT_SIZE()
    static is_simplified_offset := (*) => RimeStatus.is_full_shape_offset() + INT_SIZE()
    static is_traditional_offset := (*) => RimeStatus.is_simplified_offset() + INT_SIZE()
    static is_ascii_punct_offset := (*) => RimeStatus.is_traditional_offset() + INT_SIZE()
    ; NOTE: is there a tail padding? (which will affect this.data_size)
    static struct_size := (*) => RimeStatus.is_ascii_punct_offset() + INT_SIZE() + INT_PAD()

    struct_ptr := (*) => this.buff.Ptr

    data_size {
        set => this.num_put(, Value, RimeStatus.data_size_offset())
    }
    schema_id {
        get => this.c_str_get(, RimeStatus.schema_id_offset())
    }
    schema_name {
        get => this.c_str_get(, RimeStatus.schema_name_offset())
    }
    is_disabled {
        get => this.num_get(RimeStatus.is_disabled_offset())
    }
    is_composing {
        get => this.num_get(RimeStatus.is_composing_offset())
    }
    is_ascii_mode {
        get => this.num_get(RimeStatus.is_ascii_mode_offset())
    }
    is_full_shape {
        get => this.num_get(RimeStatus.is_full_shape_offset())
    }
    is_simplified {
        get => this.num_get(RimeStatus.is_simplified_offset())
    }
    is_traditional {
        get => this.num_get(RimeStatus.is_traditional_offset())
    }
    is_ascii_punct {
        get => this.num_get(RimeStatus.is_ascii_punct_offset())
    }
} ; RimeStatus

class RimeCandidateListIterator extends RimeStruct {
    __New() {
        this.buff := Buffer(RimeCandidateListIterator.struct_size(), 0)
    }

    static ptr_offset := (*) => 0
    static index_offset := (*) => RimeCandidateListIterator.ptr_offset() + A_PtrSize
    static candidate_offset := (*) => RimeCandidateListIterator.index_offset() + INT_SIZE() + INT_PAD()
    static struct_size := (*) => RimeCandidateListIterator.candidate_offset() + RimeCandidate.struct_size()

    struct_ptr := (*) => this.buff.Ptr

    index {
        get => this.num_get(RimeCandidateListIterator.index_offset())
    }
    candidate {
        get => RimeCandidate(this.struct_ptr() + RimeCandidateListIterator.candidate_offset())
    }
} ; RimeCandidateListIterator

class RimeConfig extends RimeStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeConfig.struct_size(), 0)
        this.bytes_put(ptr)
    }

    static ptr_offset := (*) => 0
    static struct_size := (*) => RimeConfig.ptr_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    ptr {
        get => this.num_get(RimeConfig.ptr_offset(), "Ptr")
    }
} ; RimeConfig

class RimeConfigIterator extends RimeStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeConfigIterator.struct_size(), 0)
        this.bytes_put(ptr)
    }

    static list_offset := (*) => 0
    static map_offset := (*) => RimeConfigIterator.list_offset() + A_PtrSize
    static index_offset := (*) => RimeConfigIterator.map_offset() + A_PtrSize
    static key_offset := (*) => RimeConfigIterator.index_offset() + INT_SIZE() + INT_PAD()
    static path_offset := (*) => RimeConfigIterator.key_offset() + A_PtrSize
    static struct_size := (*) => RimeConfigIterator.path_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    list {
        get => this.num_get(RimeConfigIterator.list_offset(), "Ptr")
    }
    map {
        get => this.num_get(RimeConfigIterator.map_offset(), "Ptr")
    }
    index {
        get => this.num_get(RimeConfigIterator.index_offset())
    }
    key {
        get => this.c_str_get(, RimeConfigIterator.key_offset())
    }
    path {
        get => this.c_str_get(, RimeConfigIterator.path_offset())
    }
}

class RimeSchemaListItem extends RimeStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeSchemaListItem.struct_size(), 0)
        this.bytes_put(ptr)
    }

    static schema_id_offset := (*) => 0
    static name_offset := (*) => RimeSchemaListItem.schema_id_offset() + A_PtrSize
    static reserved_offset := (*) => RimeSchemaListItem.name_offset() + A_PtrSize
    static struct_size := (*) => RimeSchemaListItem.reserved_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    schema_id {
        get => this.c_str_get(, RimeSchemaListItem.schema_id_offset())
    }
    name {
        get => this.c_str_get(, RimeSchemaListItem.name_offset())
    }
    reserved {
        get => this.num_get(RimeSchemaListItem.reserved_offset(), "Ptr")
    }
} ; RimeSchemaListItem

class RimeSchemaList extends RimeStruct {
    __New() {
        this.buff := Buffer(RimeSchemaList.struct_size(), 0)
    }

    static size_offset := (*) => 0
    static list_offset := (*) => RimeSchemaList.size_offset() + A_PtrSize ; size_t size
    static struct_size := (*) => RimeSchemaList.list_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    size {
        get => this.num_get(RimeSchemaList.size_offset(), "UInt") ; returns size_t
    }
    list {
        get => this.struct_array_get(RimeSchemaList.list_offset(), this.size, RimeSchemaListItem)
    }
} ; RimeSchemaList

/**
 * Do not exist in 1.8.5 and before
 */
class RimeStringSlice extends RimeStruct {
    __New(str := "", length := 0) {
        this.buff := Buffer(RimeStringSlice.struct_size(), 0)
        this.str := str
        this.length := length
    }

    static str_offset := (*) => 0
    static length_offset := (*) => RimeStringSlice.str_offset() + A_PtrSize
    static struct_size := (*) => RimeStringSlice.length_offset() + A_PtrSize ; size_t length

    struct_ptr := (*) => this.buff.Ptr

    str {
        get => this.c_str_get(, RimeStringSlice.str_offset())
        set => this.__str := this.c_str_put(Value, , RimeStringSlice.str_offset())
    }
    length {
        get => this.num_get(RimeStringSlice.length_offset(), "UInt") ; returns size_t
        set => this.num_put("UInt", Value, RimeStringSlice.length_offset())
    }

    slice {
        get => SubStr(this.str, 1, this.length)
    }
} ; RimeStringSlice

; Just a template struct
; Check out the actual example RimeLeversApi
; RimeCustomApi

class RimeModule extends RimeVersionedStruct {
    __New(ptr := 0) {
        this.buff := Buffer(RimeModule.struct_size(), 0)
        this.data_size := RimeModule.struct_size() - INT_SIZE()
        this.bytes_put(ptr)
    }

    static data_size_offset := (*) => 0
    static module_name_offset := (*) => RimeModule.data_size_offset() + INT_SIZE() + INT_PAD()
    static initialize_offset := (*) => RimeModule.module_name_offset() + A_PtrSize
    static finalize_offset := (*) => RimeModule.initialize_offset() + A_PtrSize
    static get_api_offset := (*) => RimeModule.finalize_offset() + A_PtrSize
    static struct_size := (*) => RimeModule.get_api_offset() + A_PtrSize

    struct_ptr := (*) => this.buff.Ptr

    data_size {
        set => this.num_put(, Value, RimeModule.data_size_offset())
    }
    module_name {
        get => this.c_str_get(, RimeModule.module_name_offset())
        set => this.__module_name := this.c_str_put(Value, , RimeModule.module_name_offset())
    }
    initialize := (*) => DllCall(this.num_get(RimeModule.initialize_offset(), "Ptr"), "CDecl")
    finalize := (*) => DllCall(this.num_get(RimeModule.finalize_offset(), "Ptr"), "CDecl")
    get_api := (*) => DllCall(this.num_get(RimeModule.get_api_offset(), "Ptr"), "CDecl Ptr")
} ; RimeModule

class RimeApi extends RimeApiStruct {
    __New() {
        if not RimeApi.rimeDll and not RimeApi.rimeDll := DllCall("LoadLibrary", "Str", RimeApi.weasel_root . "\rime.dll", "Ptr")
            throw Error("未找到 rime.dll！")
        this.api := DllCall("rime\rime_get_api", "CDecl Ptr")
        if not this.api
            throw Error("获取 Rime API 失败！")
        if VerCompare(this.get_version(), RimeApi.min_version()) < 0
            throw Error("Librime 版本过低，请使用 1.8.5 及以上版本。")
    }

    static rimeDll := DllCall("LoadLibrary", "Str", "rime.dll", "Ptr")
    static weasel_root := RegRead("HKEY_LOCAL_MACHINE\Software\Rime\Weasel", "WeaselRoot", "")
    static min_version := (*) => "1.8.5"
    static data_size_offset := (*) => 0
    static setup_offset := (*) => RimeApi.data_size_offset() + INT_SIZE() + INT_PAD()
    static set_notification_handler_offset := (*) => RimeApi.setup_offset() + A_PtrSize
    static initialize_offset := (*) => RimeApi.set_notification_handler_offset() + A_PtrSize
    static finalize_offset := (*) => RimeApi.initialize_offset() + A_PtrSize
    static start_maintenance_offset := (*) => RimeApi.finalize_offset() + A_PtrSize
    static is_maintenance_mode_offset := (*) => RimeApi.start_maintenance_offset() + A_PtrSize
    static join_maintenance_thread_offset := (*) => RimeApi.is_maintenance_mode_offset() + A_PtrSize
    static deployer_initialize_offset := (*) => RimeApi.join_maintenance_thread_offset() + A_PtrSize
    static prebuild_offset := (*) => RimeApi.deployer_initialize_offset() + A_PtrSize
    static deploy_offset := (*) => RimeApi.prebuild_offset() + A_PtrSize
    static deploy_schema_offset := (*) => RimeApi.deploy_offset() + A_PtrSize
    static deploy_config_file_offset := (*) => RimeApi.deploy_schema_offset() + A_PtrSize
    static sync_user_data_offset := (*) => RimeApi.deploy_config_file_offset() + A_PtrSize
    static create_session_offset := (*) => RimeApi.sync_user_data_offset() + A_PtrSize
    static find_session_offset := (*) => RimeApi.create_session_offset() + A_PtrSize
    static destroy_session_offset := (*) => RimeApi.find_session_offset() + A_PtrSize
    static cleanup_stale_sessions_offset := (*) => RimeApi.destroy_session_offset() + A_PtrSize
    static cleanup_all_sessions_offset := (*) => RimeApi.cleanup_stale_sessions_offset() + A_PtrSize
    static process_key_offset := (*) => RimeApi.cleanup_all_sessions_offset() + A_PtrSize
    static commit_composition_offset := (*) => RimeApi.process_key_offset() + A_PtrSize
    static clear_composition_offset := (*) => RimeApi.commit_composition_offset() + A_PtrSize
    static get_commit_offset := (*) => RimeApi.clear_composition_offset() + A_PtrSize
    static free_commit_offset := (*) => RimeApi.get_commit_offset() + A_PtrSize
    static get_context_offset := (*) => RimeApi.free_commit_offset() + A_PtrSize
    static free_context_offset := (*) => RimeApi.get_context_offset() + A_PtrSize
    static get_status_offset := (*) => RimeApi.free_context_offset() + A_PtrSize
    static free_status_offset := (*) => RimeApi.get_status_offset() + A_PtrSize
    static set_option_offset := (*) => RimeApi.free_status_offset() + A_PtrSize
    static get_option_offset := (*) => RimeApi.set_option_offset() + A_PtrSize
    static set_property_offset := (*) => RimeApi.get_option_offset() + A_PtrSize
    static get_property_offset := (*) => RimeApi.set_property_offset() + A_PtrSize
    static get_schema_list_offset := (*) => RimeApi.get_property_offset() + A_PtrSize
    static free_schema_list_offset := (*) => RimeApi.get_schema_list_offset() + A_PtrSize
    static get_current_schema_offset := (*) => RimeApi.free_schema_list_offset() + A_PtrSize
    static select_schema_offset := (*) => RimeApi.get_current_schema_offset() + A_PtrSize
    static schema_open_offset := (*) => RimeApi.select_schema_offset() + A_PtrSize
    static config_open_offset := (*) => RimeApi.schema_open_offset() + A_PtrSize
    static config_close_offset := (*) => RimeApi.config_open_offset() + A_PtrSize
    static config_get_bool_offset := (*) => RimeApi.config_close_offset() + A_PtrSize
    static config_get_int_offset := (*) => RimeApi.config_get_bool_offset() + A_PtrSize
    static config_get_double_offset := (*) => RimeApi.config_get_int_offset() + A_PtrSize
    static config_get_string_offset := (*) => RimeApi.config_get_double_offset() + A_PtrSize
    static config_get_cstring_offset := (*) => RimeApi.config_get_string_offset() + A_PtrSize
    static config_update_signature_offset := (*) => RimeApi.config_get_cstring_offset() + A_PtrSize
    static config_begin_map_offset := (*) => RimeApi.config_update_signature_offset() + A_PtrSize
    static config_next_offset := (*) => RimeApi.config_begin_map_offset() + A_PtrSize
    static config_end_offset := (*) => RimeApi.config_next_offset() + A_PtrSize
    static simulate_key_sequence_offset := (*) => RimeApi.config_end_offset() + A_PtrSize
    static register_module_offset := (*) => RimeApi.simulate_key_sequence_offset() + A_PtrSize
    static find_module_offset := (*) => RimeApi.register_module_offset() + A_PtrSize
    static run_task_offset := (*) => RimeApi.find_module_offset() + A_PtrSize
    static get_shared_data_dir_offset := (*) => RimeApi.run_task_offset() + A_PtrSize
    static get_user_data_dir_offset := (*) => RimeApi.get_shared_data_dir_offset() + A_PtrSize
    static get_sync_dir_offset := (*) => RimeApi.get_user_data_dir_offset() + A_PtrSize
    static get_user_id_offset := (*) => RimeApi.get_sync_dir_offset() + A_PtrSize
    static get_user_data_sync_dir_offset := (*) => RimeApi.get_user_id_offset() + A_PtrSize
    static config_init_offset := (*) => RimeApi.get_user_data_sync_dir_offset() + A_PtrSize
    static config_load_string_offset := (*) => RimeApi.config_init_offset() + A_PtrSize
    static config_set_bool_offset := (*) => RimeApi.config_load_string_offset() + A_PtrSize
    static config_set_int_offset := (*) => RimeApi.config_set_bool_offset() + A_PtrSize
    static config_set_double_offset := (*) => RimeApi.config_set_int_offset() + A_PtrSize
    static config_set_string_offset := (*) => RimeApi.config_set_double_offset() + A_PtrSize
    static config_get_item_offset := (*) => RimeApi.config_set_string_offset() + A_PtrSize
    static config_set_item_offset := (*) => RimeApi.config_get_item_offset() + A_PtrSize
    static config_clear_offset := (*) => RimeApi.config_set_item_offset() + A_PtrSize
    static config_create_list_offset := (*) => RimeApi.config_clear_offset() + A_PtrSize
    static config_create_map_offset := (*) => RimeApi.config_create_list_offset() + A_PtrSize
    static config_list_size_offset := (*) => RimeApi.config_create_map_offset() + A_PtrSize
    static config_begin_list_offset := (*) => RimeApi.config_list_size_offset() + A_PtrSize
    static get_input_offset := (*) => RimeApi.config_begin_list_offset() + A_PtrSize
    static get_caret_pos_offset := (*) => RimeApi.get_input_offset() + A_PtrSize
    static select_candidate_offset := (*) => RimeApi.get_caret_pos_offset() + A_PtrSize
    static get_version_offset := (*) => RimeApi.select_candidate_offset() + A_PtrSize
    static set_caret_pos_offset := (*) => RimeApi.get_version_offset() + A_PtrSize
    static select_candidate_on_current_page_offset := (*) => RimeApi.set_caret_pos_offset() + A_PtrSize
    static candidate_list_begin_offset := (*) => RimeApi.select_candidate_on_current_page_offset() + A_PtrSize
    static candidate_list_next_offset := (*) => RimeApi.candidate_list_begin_offset() + A_PtrSize
    static candidate_list_end_offset := (*) => RimeApi.candidate_list_next_offset() + A_PtrSize
    static user_config_open_offset := (*) => RimeApi.candidate_list_end_offset() + A_PtrSize
    static candidate_list_from_index_offset := (*) => RimeApi.user_config_open_offset() + A_PtrSize
    static get_prebuilt_data_dir_offset := (*) => RimeApi.candidate_list_from_index_offset() + A_PtrSize
    static get_staging_dir_offset := (*) => RimeApi.get_prebuilt_data_dir_offset() + A_PtrSize
    static commit_proto_offset := (*) => RimeApi.get_staging_dir_offset() + A_PtrSize
    static context_proto_offset := (*) => RimeApi.commit_proto_offset() + A_PtrSize
    static status_proto_offset := (*) => RimeApi.context_proto_offset() + A_PtrSize
    static get_state_label_offset := (*) => RimeApi.status_proto_offset() + A_PtrSize
    static delete_candidate_offset := (*) => RimeApi.get_state_label_offset() + A_PtrSize
    static delete_candidate_on_current_page_offset := (*) => RimeApi.delete_candidate_offset() + A_PtrSize
    static get_state_label_abbreviated_offset := (*) => RimeApi.delete_candidate_on_current_page_offset() + A_PtrSize
    static struct_size := (*) => RimeApi.get_state_label_abbreviated_offset() + A_PtrSize

    struct_ptr := (*) => this.api

    ; (RimeTraits) => void
    setup(traits) {
        DllCall(this.fp(RimeApi.setup_offset()), "Ptr", traits ? traits.struct_ptr() : 0, "CDecl")
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
        DllCall(this.fp(RimeApi.set_notification_handler_offset()), "Ptr", CallbackCreate(handler, "C", 4), "Ptr", context_object, "CDecl")
    }

    ; (RimeTraits) => void
    initialize(traits) {
        DllCall(this.fp(RimeApi.initialize_offset()), "Ptr", traits ? traits.struct_ptr() : 0, "CDecl")
    }

    ; () => void
    finalize() {
        DllCall(this.fp(RimeApi.finalize_offset()), "CDecl")
        DllCall("FreeLibrary", "Ptr", RimeApi.rimeDll)
    }

    ; (Int) => Int
    start_maintenace(full_check) {
        return DllCall(this.fp(RimeApi.start_maintenance_offset()), "Int", full_check, "CDecl Int")
    }

    ; () => Int
    is_maintenance_mode() {
        return DllCall(this.fp(RimeApi.is_maintenance_mode_offset()), "CDecl Int")
    }

    ; () => void
    join_maintenance_thread() {
        DllCall(this.fp(RimeApi.join_maintenance_thread_offset()), "CDecl")
    }

    ; (RimeTraits) => void
    deployer_initialize(traits) {
        DllCall(this.fp(RimeApi.deployer_initialize_offset()), "Ptr", traits ? traits.struct_ptr() : 0, "CDecl")
    }

    ; () => Int
    prebuild() {
        return DllCall(this.fp(RimeApi.prebuild_offset()), "CDecl Int")
    }

    ; () => Int
    deploy() {
        return DllCall(this.fp(RimeApi.deploy_offset()), "CDecl Int")
    }

    ; (Str) => Int
    deploy_schema(schema_file) {
        return DllCall(this.fp(RimeApi.deploy_schema_offset()), "Ptr", c_str(schema_file).Ptr, "CDecl Int")
    }

    ; (Str, Str) => Int
    deploy_config_file(file_name, version_key) {
        return DllCall(this.fp(RimeApi.deploy_config_file_offset()), "Ptr", c_str(file_name).Ptr, "Ptr", c_str(version_key).Ptr, "CDecl Int")
    }

    ; () => Int
    sync_user_data() {
        return DllCall(this.fp(RimeApi.sync_user_data_offset()), "CDecl Int")
    }

    ; () => UInt
    create_session() {
        return DllCall(this.fp(RimeApi.create_session_offset()), "CDecl UInt")
    }

    ; (UInt) => Int
    find_session(session_id) {
        return DllCall(this.fp(RimeApi.find_session_offset()), "UInt", session_id, "CDecl Int")
    }

    ; (UInt) => Int
    destroy_session(session_id) {
        return DllCall(this.fp(RimeApi.destroy_session_offset()), "UInt", session_id, "CDecl Int")
    }

    ; () => void
    cleanup_stale_sessions() {
        DllCall(this.fp(RimeApi.cleanup_stale_sessions_offset()), "CDecl")
    }

    ; () => void
    cleanup_all_sessions() {
        DllCall(this.fp(RimeApi.cleanup_all_sessions_offset()), "CDecl")
    }

    ; (UInt, Int, Int) => Int
    process_key(session_id, keycode, mask) {
        return DllCall(this.fp(RimeApi.process_key_offset()), "UInt", session_id, "Int", keycode, "Int", mask, "CDecl Int")
    }

    ; (UInt) => Int
    commit_composition(session_id) {
        return DllCall(this.fp(RimeApi.commit_composition_offset()), "UInt", session_id, "CDecl Int")
    }

    ; (UInt) => void
    clear_composition(session_id) {
        DllCall(this.fp(RimeApi.clear_composition_offset()), "UInt", session_id, "CDecl")
    }

    ; (UInt) => RimeCommit or 0
    get_commit(session_id) {
        commit := RimeCommit()
        res := DllCall(this.fp(RimeApi.get_commit_offset()), "UInt", session_id, "Ptr", commit.struct_ptr(), "CDecl Int")
        return res ? commit : 0
    }

    ; (RimeCommit) => Int
    free_commit(commit) {
        return DllCall(this.fp(RimeApi.free_commit_offset()), "Ptr", commit ? commit.struct_ptr() : 0, "CDecl Int")
    }

    ; (UInt) => RimeContext or 0
    get_context(session_id) {
        context := RimeContext()
        res := DllCall(this.fp(RimeApi.get_context_offset()), "UInt", session_id, "Ptr", context.struct_ptr(), "CDecl Int")
        return res ? context : 0
    }

    ; (RimeContext) => Int
    free_context(context) {
        return DllCall(this.fp(RimeApi.free_context_offset()), "Ptr", context ? context.struct_ptr() : 0, "CDecl Int")
    }

    ; (UInt) => RimeStatus or 0
    get_status(session_id) {
        status := RimeStatus()
        res := DllCall(this.fp(RimeApi.get_status_offset()), "UInt", session_id, "Ptr", status.struct_ptr(), "CDecl Int")
        return res ? status : 0
    }

    ; (RimeStatus) => Int
    free_status(status) {
        return DllCall(this.fp(RimeApi.free_status_offset()), "Ptr", status ? status.struct_ptr() : 0, "CDecl Int")
    }

    ; (UInt, Str, Int) => void
    set_option(session_id, option, value) {
        DllCall(this.fp(RimeApi.set_option_offset()), "UInt", session_id, "Ptr", c_str(option).Ptr, "Int", value, "CDecl")
    }

    ; (UInt, Str) => Int
    get_option(session_id, option) {
        return DllCall(this.fp(RimeApi.get_option_offset()), "UInt", session_id, "Ptr", c_str(option).Ptr, "CDecl Int")
    }

    ; (UInt, Str, Str) => void
    set_property(session_id, prop, value) {
        DllCall(this.fp(RimeApi.set_property_offset()), "UInt", session_id, "Ptr", c_str(prop).Ptr, "Ptr", c_str(value).Ptr, "CDecl")
    }

    ; (UInt, Str, UInt) => Str
    get_property(session_id, prop, buffer_size := DEFAULT_BUFFER_SIZE()) {
        buf := Buffer(buffer_size)
        res := DllCall(this.fp(RimeApi.get_property_offset()), "UInt", session_id, "Ptr", c_str(prop).Ptr, "Ptr", buf.Ptr, "UInt", buffer_size, "CDecl Int")
        return res ? StrGet(buf.Ptr, "UTF-8") : ""
    }

    ; () => RimeSchemaList or 0
    get_schema_list() {
        list := RimeSchemaList()
        res := DllCall(this.fp(RimeApi.get_schema_list_offset()), "Ptr", list.struct_ptr(), "CDecl Int")
        return res ? list : 0
    }

    ; (RimeSchemaList) => void
    free_schema_list(schema_list) {
        DllCall(this.fp(RimeApi.free_schema_list_offset()), "Ptr", schema_list ? schema_list.struct_ptr() : 0, "CDecl")
    }

    ; (UInt, UInt) => Str
    get_current_schema(session_id, buffer_size := DEFAULT_BUFFER_SIZE()) {
        buf := Buffer(buffer_size)
        res := DllCall(this.fp(RimeApi.get_current_schema_offset()), "UInt", session_id, "Ptr", buf.Ptr, "UInt", buffer_size, "CDecl Int")
        return res ? StrGet(buf.Ptr, "UTF-8") : ""
    }

    ; (UInt, Str) => Int
    select_schema(session_id, schema_id) {
        return DllCall(this.fp(RimeApi.select_schema_offset()), "UInt", session_id, "Ptr", c_str(schema_id).Ptr, "CDecl Int")
    }

    /**
     * Open a schema
     * 
     * @param schema_id type of `Str`
     * @returns type of `RimeConfig` on success, `0` on failure
     */
    schema_open(schema_id) {
        config := RimeConfig()
        res := DllCall(this.fp(RimeApi.schema_open_offset()), "Ptr", c_str(schema_id).Ptr, "Ptr", config.struct_ptr(), "CDecl Int")
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
        res := DllCall(this.fp(RimeApi.config_open_offset()), "Ptr", c_str(config_id).Ptr, "Ptr", config.struct_ptr(), "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_close_offset()), "Ptr", config ? config.struct_ptr() : 0, "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_get_bool_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        res := DllCall(this.fp(RimeApi.config_get_bool_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        if res := DllCall(this.fp(RimeApi.config_get_bool_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_get_int_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        res := DllCall(this.fp(RimeApi.config_get_int_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        if res := DllCall(this.fp(RimeApi.config_get_int_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_get_double_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        res := DllCall(this.fp(RimeApi.config_get_double_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        if res := DllCall(this.fp(RimeApi.config_get_double_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "CDecl Int")
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
        res := DllCall(this.fp(RimeApi.config_get_string_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", buf.Ptr, "UInt", buffer_size, "CDecl Int")
        return res ? StrGet(buf.Ptr, "UTF-8") : ""
    }

    /**
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `Str`
     */
    config_get_cstring(config, key) {
        p := DllCall(this.fp(RimeApi.config_get_cstring_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "CDecl Ptr")
        return p ? StrGet(p, "UTF-8") : ""
    }

    /**
     * 
     * @param config type of `RimeConfig`
     * @param signer type of `Str`
     * @returns `True` on success, `False` on failure
     */
    config_update_signature(config, signer) {
        return DllCall(this.fp(RimeApi.config_update_signature_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(signer).Ptr, "CDecl Int")
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
        res := DllCall(this.fp(RimeApi.config_begin_map_offset()), "Ptr", iterator.struct_ptr(), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "CDecl Int")
        return res ? iterator : 0
    }

    /**
     * Increment the config iterator
     * 
     * @param iterator type of `RimeConfigIterator`
     * @returns `True` if not end, `False` if end
     */
    config_next(iterator) {
        return DllCall(this.fp(RimeApi.config_next_offset()), "Ptr", iterator ? iterator.struct_ptr() : 0, "CDecl Int")
    }

    /**
     * Cleanup the config iterator
     * 
     * @param iterator type of `RimeConfigIterator`
     */
    config_end(iterator) {
        DllCall(this.fp(RimeApi.config_end_offset()), "Ptr", iterator ? iterator.struct_ptr() : 0, "CDecl")
    }

    ; (UInt, Str) => Int
    simulate_key_sequence(session_id, key_sequence) {
        return DllCall(this.fp(RimeApi.simulate_key_sequence_offset()), "UInt", session_id, "Ptr", c_str(key_sequence).Ptr, "CDecl Int")
    }

    /**
     * 
     * @param module type of `RimeModule`
     * @returns `True` on success, `False` on failure
     */
    register_module(module) {
        return DllCall(this.fp(RimeApi.register_module_offset()), "Ptr", module ? module.struct_ptr() : 0, "CDecl Int")
    }

    /**
     * 
     * @param module_name type of `Str`
     * @returns `RimeModule` onsuccess, `0` onfailure
     */
    find_module(module_name) {
        res := DllCall(this.fp(RimeApi.find_module_offset()), "Ptr", c_str(module_name).Ptr, "CDecl Ptr")
        return res ? RimeModule(res) : 0
    }

    /**
     * Run task
     * 
     * @param task_name type of `Str`
     * @returns `True` on success, `False` on failure
     */
    run_task(task_name) {
        return DllCall(this.fp(RimeApi.run_task_offset()), "Ptr", c_str(task_name).Ptr, "CDecl Int")
    }

    ; () => Str
    get_shared_data_dir() {
        if p := DllCall(this.fp(RimeApi.get_shared_data_dir_offset()), "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; () => Str
    get_user_data_dir() {
        if p := DllCall(this.fp(RimeApi.get_user_data_dir_offset()), "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; () => Str
    get_sync_dir() {
        if p := DllCall(this.fp(RimeApi.get_sync_dir_offset()), "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; () => Str
    get_user_id() {
        if p := DllCall(this.fp(RimeApi.get_user_id_offset()), "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; (UInt) => Str
    get_user_data_sync_dir(buffer_size := DEFAULT_BUFFER_SIZE()) {
        buf := Buffer(buffer_size, 0)
        DllCall(this.fp(RimeApi.get_user_data_sync_dir_offset()), "Ptr", buf.Ptr, "UInt", buffer_size, "CDecl")
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
        res := DllCall(this.fp(RimeApi.config_init_offset()), "Ptr", config.struct_ptr(), "CDecl Int")
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
        res := DllCall(this.fp(RimeApi.config_load_string_offset()), "Ptr", config.struct_ptr(), "Ptr", c_str(yaml).Ptr, "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_set_bool_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Int", value, "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_set_int_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Int", value, "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_set_double_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Double", value, "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_set_string_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", c_str(value).Ptr, "CDecl Int")
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
        res := DllCall(this.fp(RimeApi.config_get_item_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", value.struct_ptr(), "CDecl Int")
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
        return DllCall(this.fp(RimeApi.config_set_item_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "Ptr", value ? value.struct_ptr() : 0, "CDecl Int")
    }

    /**
     * Clear item of the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` on success, `False` on failure
     */
    config_clear(config, key) {
        return DllCall(this.fp(RimeApi.config_clear_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "CDecl Int")
    }

    /**
     * Create a list in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` on success, `False` on failure
     */
    config_create_list(config, key) {
        return DllCall(this.fp(RimeApi.config_create_list_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "CDecl Int")
    }

    /**
     * Create a map in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns `True` on success, `False` on failure
     */
    config_create_map(config, key) {
        return DllCall(this.fp(RimeApi.config_create_map_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "CDecl Int")
    }

    /**
     * Get size of list in the config
     * 
     * @param config type of `RimeConfig`
     * @param key type of `Str`
     * @returns the size of desired list
     */
    config_list_size(config, key) {
        return DllCall(this.fp(RimeApi.config_list_size_offset()), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "CDecl UInt") ; returns size_t
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
        res := DllCall(this.fp(RimeApi.config_begin_list_offset()), "Ptr", iterator.struct_ptr(), "Ptr", config ? config.struct_ptr() : 0, "Ptr", c_str(key).Ptr, "CDecl Int")
        return res ? iterator : 0
    }

    ; (UInt) => Str
    get_input(session_id) {
        if p := DllCall(this.fp(RimeApi.get_input_offset()), "UInt", session_id, "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; (UInt) => UInt
    get_caret_pos(session_id) {
        return DllCall(this.fp(RimeApi.get_caret_pos_offset()), "UInt", session_id, "CDecl UInt")
    }

    ; (UInt, UInt) => Int
    select_candidate(session_id, index) {
        return DllCall(this.fp(RimeApi.select_candidate_offset()), "UInt", session_id, "UInt", index, "CDecl Int")
    }

    ; () => Str
    get_version() {
        if p := DllCall(this.fp(RimeApi.get_version_offset()), "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; (UInt, UInt) => void
    set_caret_pos(session_id, caret_pos) {
        DllCall(this.fp(RimeApi.set_caret_pos_offset()), "UInt", session_id, "UInt", caret_pos, "CDecl")
    }

    ; (UInt, UInt) => Int
    select_candidate_on_current_page(session_id, index) {
        return DllCall(this.fp(RimeApi.select_candidate_on_current_page_offset()), "UInt", session_id, "UInt", index, "CDecl Int")
    }

    ; (UInt) => RimeCandidateListIterator or 0
    candidate_list_begin(session_id) {
        iter := RimeCandidateListIterator()
        res := DllCall(this.fp(RimeApi.candidate_list_begin_offset()), "UInt", session_id, "Ptr", iter.struct_ptr(), "CDecl Int")
        return res ? iter : 0
    }

    ; (RimeCandidateListIterator) => Int
    candidate_list_next(iterator) {
        return DllCall(this.fp(RimeApi.candidate_list_next_offset()), "Ptr", iterator ? iterator.struct_ptr() : 0, "CDecl Int")
    }

    ; (RimeCandidateListIterator) => void
    candidate_list_end(iterator) {
        DllCall(this.fp(RimeApi.candidate_list_end_offset()), "Ptr", iterator ? iterator.struct_ptr() : 0, "CDecl")
    }

    /**
     * Open user config
     * 
     * @param config_id type of `Str`
     * @returns `RimConfig` on success, `0` on failure`
     */
    user_config_open(config_id) {
        config := RimeConfig()
        res := DllCall(this.fp(RimeApi.user_config_open_offset()), "Ptr", c_str(config_id).Ptr, "Ptr", config.struct_ptr(), "CDecl Int")
        return res ? config : 0
    }

    ; (UInt, RimeCandidateListIterator, UInt) => Int
    candidate_list_from_index(session_id, iterator, index) {
        return DllCall(this.fp(RimeApi.candidate_list_from_index_offset()), "UInt", session_id, "Ptr", iterator ? iterator.struct_ptr() : 0, "UInt", index, "CDecl Int")
    }

    ; () => Str
    get_prebuilt_data_dir() {
        if p := DllCall(this.fp(RimeApi.get_prebuilt_data_dir_offset()), "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; () => Str
    get_staging_dir() {
        if p := DllCall(this.fp(RimeApi.get_staging_dir_offset()), "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; Deprecated
    commit_proto := (*) => 0
    ; Deprecated
    context_proto := (*) => 0
    ; Deprecated
    status_proto := (*) => 0

    ; (UInt, Str, Int) => Str
    get_state_label(session_id, option_name, state) {
        if p := DllCall(this.fp(RimeApi.get_state_label_offset()), "UInt", session_id, "Ptr", c_str(option_name).Ptr, "Int", state, "CDecl Ptr")
            return StrGet(p, "UTF-8")
        return ""
    }

    ; (UInt, UInt) => Int
    delete_candidate(session_id, index) {
        return DllCall(this.fp(RimeApi.delete_candidate_offset()), "UInt", session_id, "UInt", index, "CDecl Int")
    }

    ; (UInt, UInt) => Int
    delete_candidate_on_current_page(session_id, index) {
        return DllCall(this.fp(RimeApi.delete_candidate_on_current_page_offset()), "UInt", session_id, "UInt", index, "CDecl Int")
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
        if not this.api_available("get_state_label_abbreviated") or A_PtrSize > 4
            return 0
        res := DllCall(this.fp(RimeApi.get_state_label_abbreviated_offset()), "UInt", session_id, "Ptr", c_str(option_name).Ptr, "Int", state, "Int", abbreviated, "CDecl Int64")
        try
            str := StrGet(res & 0xffffffff, "UTF-8")
        catch as e
            return 0
        return RimeStringSlice(str, res >> 32)
    }
}
