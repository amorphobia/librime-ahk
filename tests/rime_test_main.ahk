#Include test_runner.ahk

#Include ..\rime_api.ahk
#Include ..\rime_levers_api.ahk
#Include ..\utils\yaml.ahk

class RimeStringTests {
    Begin() {
        this.str1 := RimeString("Hello, World!")
        this.str2 := RimeString("你好，世界！")
        this.str3 := RimeString("🐇🐰")
        this.str4 := RimeString("床前明月光，疑是地上霜。`r`n举头望明月，低头思故乡。")
        this.str5 := RimeString("قد ومن فرنسا الإمتعاض, استراليا، وبريطانيا ما كما. حين بـ سبتمبر الأولى لمحاكم, يكن وحتّى منتصف ما. لمّ ويعزى وهولندا، قد, و دخول شعار نهاية نفس. عرض وإقامة للإتحاد عل, مع قام وبعد وتتحمّل, جُل خيار البرية المتّبعة إذ. لكون إستعمل لم هذا, تم به، أوزار والقرى.")
    }

    Test_Size() {
        TestRunner.Assert(this.str1.Size == 14)
        TestRunner.Assert(this.str2.Size == 19)
        TestRunner.Assert(this.str3.Size == 9)
        TestRunner.Assert(this.str4.Size == 75)
        TestRunner.Assert(this.str5.Size == 462)
    }

    Test_ToString() {
        TestRunner.Assert(String(this.str1) == "Hello, World!")
        TestRunner.Assert(String(this.str2) == "你好，世界！")
        TestRunner.Assert(String(this.str3) == "🐇🐰")
        TestRunner.Assert(String(this.str4) == "床前明月光，疑是地上霜。`r`n举头望明月，低头思故乡。")
        TestRunner.Assert(String(this.str5) == "قد ومن فرنسا الإمتعاض, استراليا، وبريطانيا ما كما. حين بـ سبتمبر الأولى لمحاكم, يكن وحتّى منتصف ما. لمّ ويعزى وهولندا، قد, و دخول شعار نهاية نفس. عرض وإقامة للإتحاد عل, مع قام وبعد وتتحمّل, جُل خيار البرية المتّبعة إذ. لكون إستعمل لم هذا, تم به، أوزار والقرى.")
    }

    End() {
        this.DeleteProp("str1")
        this.DeleteProp("str2")
        this.DeleteProp("str3")
    }
}

class RimeNullTerminatedStringArrayTests {
    Begin() {
        local values := ["Hello", "你好", "🐇🐰"]

        this.str_arr := RimeNullTerminatedStringArray(values)
        TestRunner.Assert(values.Length == 3)
    }

    Test_Basic() {
        TestRunner.Assert(this.str_arr.Length == 3)
        TestRunner.Assert(this.str_arr.Size == 4 * A_PtrSize + 22)
        TestRunner.Assert(
            NumGet(this.str_arr, 3 * A_PtrSize, "Ptr") == 0
        )
    }

    Test_Empty() {
        local str_arr := RimeNullTerminatedStringArray()

        TestRunner.Assert(str_arr.Length == 0)
        TestRunner.Assert(str_arr.Size == A_PtrSize)
        TestRunner.Assert(NumGet(str_arr, 0, "Ptr") == 0)
    }
}

class RimeTraitsTests {
    Begin() {
        this.traits := RimeTraits()
    }

    Test_Basic() {
        TestRunner.Assert(this.traits.data_size == 10 * A_PtrSize + A_IntSize + 2 * A_IntPaddingSize)
    }

    Test_ModulesAreNullTerminated() {
        this.traits.modules := ["default", "autohotkey"]
        TestRunner.Assert(NumGet(this.traits.__modules, 2 * A_PtrSize, "Ptr") == 0)
        TestRunner.Assert(this.traits.__modules.Length == 2) ; act like a native AutoHotkey array
        TestRunner.Assert(this.traits.modules.Length == 2)
        TestRunner.Assert(this.traits.modules[1] == "default")
        TestRunner.Assert(this.traits.modules[2] == "autohotkey")
    }

    End() {
        this.DeleteProp("traits")
    }
}

class RimeCandidatePreviewTests {
    Begin() {
        this.preview := RimeCandidatePreview()
        this.before := RimeString("before-")
        this.selected := RimeString("选择")
        this.after := RimeString("-after")
        NumPut("Ptr", this.before.Ptr, this.preview, RimeCandidatePreview.text_before_selection_offset)
        NumPut("Ptr", this.selected.Ptr, this.preview, RimeCandidatePreview.selected_text_offset)
        NumPut("Ptr", this.after.Ptr, this.preview, RimeCandidatePreview.text_after_selection_offset)
    }

    Test_Basic() {
        TestRunner.Assert(this.preview.data_size == 3 * A_PtrSize + A_IntPaddingSize)
        TestRunner.Assert(this.preview.text_before_selection == "before-")
        TestRunner.Assert(this.preview.selected_text == "选择")
        TestRunner.Assert(this.preview.text_after_selection == "-after")
    }

    End() {
        this.DeleteProp("preview")
        this.DeleteProp("before")
        this.DeleteProp("selected")
        this.DeleteProp("after")
    }
}

class RimeYamlTestApi {
    __New(collection_type) {
        this.collection_type := collection_type
        this.events := []
    }

    config_load_string(yaml) => 1

    config_begin_map(config, path) {
        return config == 1 && this.collection_type == "map" ? {key: "child", step: 0} : 0
    }

    config_begin_list(config, path) {
        return config == 1 && this.collection_type == "list" ? {key: "0", step: 0} : 0
    }

    config_next(iter) {
        iter.step += 1
        return iter.step == 1
    }

    config_get_item(config, key) => 2

    config_close(config) {
        this.events.Push("close:" . config)
    }

    config_end(iter) {
        this.events.Push("end")
    }
}

class RimeYamlFailingParser extends RimeYaml {
    _parse_str(obj, &val) {
        throw Error("Expected parse failure.")
    }
}

class RimeYamlTests {
    Test_MapCleanupOnFailure() {
        this.AssertCleanup("map")
    }

    Test_ListCleanupOnFailure() {
        this.AssertCleanup("list")
    }

    AssertCleanup(collection_type) {
        local api := RimeYamlTestApi(collection_type), yaml := RimeYamlFailingParser(api)

        try {
            yaml.load("ignored")
        } catch Error as err {
            TestRunner.Equal("Expected parse failure.", err.Message)
            TestRunner.Equal(3, api.events.Length)
            TestRunner.Equal("close:2", api.events[1])
            TestRunner.Equal("end", api.events[2])
            TestRunner.Equal("close:1", api.events[3])
            return
        }
        throw Error("Expected YAML parsing to fail.")
    }
}

Class RimeApiTests {
    NoopNotification(context_object, session_id, message_type, message_value) {
    }

    Begin() {
        api := RimeApi()
        traits := RimeTraits()
        traits.shared_data_dir := traits.user_data_dir := traits.prebuilt_data_dir := traits.staging_dir := "."
        traits.app_name := "rime.test"
        api.setup(traits)
        api.initialize(0)
        this.api := api
        this.levers := RimeLeversApi(api)
        this.na_msg := "API {} not available"
    }

    ; Rime has multi-threading components, which
    ; are beyond AutoHotkey's capability to handle.
    ; Therefore all tests must be done within one function.
    Test_All() {
        api := this.api

        TestRunner.Assert(api.data_size >= 98 * A_PtrSize + A_IntPaddingSize)
        TestRunner.Assert(RimeApi.struct_size == 101 * A_PtrSize)

        fn := "create_session"
        TestRunner.Assert(api.api_available(fn), Format(this.na_msg, fn))
        local test_session := api.create_session()
        TestRunner.Assert(0 !== test_session)

        fn := "get_context"
        TestRunner.Assert(api.api_available(fn), Format(this.na_msg, fn))
        ctx := api.get_context(test_session)
        TestRunner.Assert(0 !== ctx)
        try {
            TestRunner.Assert(0 == ctx.menu.num_candidates)
        } finally {
            TestRunner.Assert(api.free_context(ctx))
        }

        fn := "get_status"
        TestRunner.Assert(api.api_available(fn), Format(this.na_msg, fn))
        status := api.get_status(test_session)
        TestRunner.Assert(0 !== status)
        try {
            TestRunner.Assert(!status.is_composing)
        } finally {
            TestRunner.Assert(api.free_status(status))
        }

        candidate_preview_available := api.api_available("get_candidate_preview")
        TestRunner.Assert(candidate_preview_available == api.api_available("free_candidate_preview"))
        preview := api.get_candidate_preview(test_session)
        TestRunner.Assert(0 == preview)

        if candidate_preview_available {
            TestRunner.Assert(api.free_candidate_preview(RimeCandidatePreview()))
        } else {
            TestRunner.Assert(0 == api.free_candidate_preview(RimeCandidatePreview()))
        }

        fn := "destroy_session"
        TestRunner.Assert(api.api_available(fn), Format(this.na_msg, fn))
        TestRunner.Assert(api.destroy_session(test_session))


        levers := this.levers

        TestRunner.Assert(levers.data_size == 32 * A_PtrSize + A_IntPaddingSize)

        fn := "custom_settings_init"
        TestRunner.Assert(levers.api_available(fn), Format(this.na_msg, fn))
        custom_settings := levers.custom_settings_init("levers_test", "rime_test")
        TestRunner.Assert(!!custom_settings)

        fn := "customize_bool"
        TestRunner.Assert(levers.api_available(fn), Format(this.na_msg, fn))
        TestRunner.Assert(levers.customize_bool(custom_settings, "test_key", true))

        fn := "custom_settings_destroy"
        TestRunner.Assert(levers.api_available(fn), Format(this.na_msg, fn))
        levers.custom_settings_destroy(custom_settings)
    }

    Test_ApiCopiesLastFunctionPointer() {
        local ptr := DllCall("rime\rime_get_api", "CDecl Ptr")

        if this.api.api_available("free_candidate_preview") {
            TestRunner.Assert(this.api.fp(RimeApi.free_candidate_preview_offset)
                == NumGet(ptr, RimeApi.free_candidate_preview_offset, "Ptr"))
        } else {
            TestRunner.Assert(this.api.fp(RimeApi.change_page_offset)
                == NumGet(ptr, RimeApi.change_page_offset, "Ptr"))
            TestRunner.Assert(this.api.fp(RimeApi.get_candidate_preview_offset) == 0)
            TestRunner.Assert(this.api.fp(RimeApi.free_candidate_preview_offset) == 0)
        }
    }

    Test_NotificationCallbackLifetime() {
        local first_callback, notification_handler := ObjBindMethod(this, "NoopNotification")

        this.api.set_notification_handler(notification_handler, 0)
        first_callback := RimeApi.notification_callback
        TestRunner.Assert(first_callback != 0)

        this.api.set_notification_handler(notification_handler, 0)
        TestRunner.Assert(RimeApi.notification_callback != 0)
        TestRunner.Assert(RimeApi.notification_callback != first_callback)

        first_callback := RimeApi.notification_callback
        try {
            this.api.set_notification_handler(0, 0)
        } catch RimeError {
            TestRunner.Assert(RimeApi.notification_callback == first_callback)
            return
        }
        throw Error("Expected RimeError for an invalid notification handler.")
    }

    End() {
        local rime_dll := RimeApi.rimeDll

        this.api.finalize()
        TestRunner.Assert(RimeApi.notification_callback == 0)
        TestRunner.Assert(RimeApi.rimeDll == rime_dll)
        this.DeleteProp("api")
        this.DeleteProp("levers")
        this.DeleteProp("na_msg")
    }
}

results := TestRunner.Run(RimeStringTests, RimeNullTerminatedStringArrayTests, RimeTraitsTests,
    RimeCandidatePreviewTests, RimeYamlTests, RimeApiTests)
failures := TestRunner.WriteJUnit(results, A_ScriptDir "\junit.xml")
TestRunner.Print(results, "*")
ExitApp(failures ? 1 : 0)
