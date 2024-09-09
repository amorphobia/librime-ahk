#Include Yunit\Yunit.ahk
#Include Yunit\Stdout.ahk
#Include Yunit\OutputDebug.ahk
#Include Yunit\JUnit.ahk
#Include Yunit\Window.ahk

#Include ..\rime_api.ahk
#Include ..\rime_levers_api.ahk

Class RimeApiTests {
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
    AllTests() {
        api := this.api

        fn := "create_session"
        Yunit.Assert(api.api_available(fn), Format(this.na_msg, fn))
        local test_session := api.create_session()
        Yunit.Assert(0 !== test_session)

        fn := "get_context"
        Yunit.Assert(api.api_available(fn), Format(this.na_msg, fn))
        ctx := api.get_context(test_session)
        Yunit.Assert(0 !== ctx)
        Yunit.Assert(0 == ctx.menu.num_candidates)

        fn := "get_status"
        Yunit.Assert(api.api_available(fn), Format(this.na_msg, fn))
        status := api.get_status(test_session)
        Yunit.Assert(0 !== status)
        Yunit.Assert(!status.is_composing)

        fn := "destroy_session"
        Yunit.Assert(api.api_available(fn), Format(this.na_msg, fn))
        Yunit.Assert(api.destroy_session(test_session))


        levers := this.levers

        fn := "custom_settings_init"
        Yunit.Assert(levers.api_available(fn), Format(this.na_msg, fn))
        custom_settings := levers.custom_settings_init("levers_test", "rime_test")
        Yunit.Assert(!!custom_settings)

        fn := "customize_bool"
        Yunit.Assert(levers.api_available(fn), Format(this.na_msg, fn))
        Yunit.Assert(levers.customize_bool(custom_settings, "test_key", true))

        fn := "custom_settings_destroy"
        Yunit.Assert(levers.api_available(fn), Format(this.na_msg, fn))
        levers.custom_settings_destroy(custom_settings)
    }

    End() {
        ; 
    }
}

if A_Args.Length {
    Yunit.Use(YunitJUnit).Test(RimeApiTests)
} else
    Yunit.Use(YunitStdOut, YunitOutputDebug, YunitJUnit, YunitWindow).Test(RimeApiTests)
