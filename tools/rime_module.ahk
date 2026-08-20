/*
 * Copyright (c) 2026 Xuesong Peng <pengxuesong.cn@gmail.com>
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
#Requires AutoHotkey v2.0
#Include ..\rime_api.ahk

; Layer 1: defines the custom API ABI. A provider publishes the table, while a client copies and calls it.
class HelloModuleApi extends RimeApiStruct {
    static CreateProvider(hello_handler) {
        return HelloModuleApi(0, hello_handler)
    }

    static FromPtr(ptr) {
        if !ptr {
            throw RimeError("Cannot create hello module API from a null pointer.")
        }
        return HelloModuleApi(ptr)
    }

    __New(ptr, hello_handler?) {
        local real_size
        local copy_size

        super.__New(HelloModuleApi.struct_size, 0)

        if IsSet(hello_handler) {
            if ptr {
                throw RimeError("A provider API table cannot copy an existing API.")
            }
            this.num_put("Int", HelloModuleApi.struct_size - A_IntSize, HelloModuleApi.data_size_offset)
            this.hello_handler := hello_handler
            this.hello_entry_handler := this.OnHello.Bind(this)
            this.hello_callback := CallbackCreate(this.hello_entry_handler, "C", 0)
            this.num_put("Ptr", this.hello_callback, HelloModuleApi.hello_offset)
            return
        }

        real_size := A_IntSize + NumGet(ptr, HelloModuleApi.data_size_offset, "Int")
        if real_size <= A_IntSize {
            throw RimeError("Invalid hello module API data size.")
        }

        copy_size := Min(real_size, HelloModuleApi.struct_size)
        this.copy(ptr, , , copy_size)
    }

    static data_size_offset := 0
    static hello_offset := HelloModuleApi.data_size_offset + A_IntSize + A_IntPaddingSize
    static struct_size := HelloModuleApi.hello_offset + A_PtrSize

    Hello() {
        local hello_callback

        if !this.has_member("hello") {
            return false
        }

        hello_callback := this.fp(HelloModuleApi.hello_offset)
        if !hello_callback {
            return false
        }

        DllCall(hello_callback, "CDecl")
        return true
    }

    OnHello() {
        try {
            this.hello_handler.Call()
        } catch as err {
            ExitWithCallbackError("hello", err)
        }
    }
}

; Layer 2: adapts an AutoHotkey implementation to RimeModule and owns all native callback entry points.
class HelloModuleRegistration {
    static registrations := Map()

    static Register(rime, name, implementation, api) {
        local registration

        if !name {
            throw RimeError("The hello module name cannot be empty.")
        }
        if this.registrations.Has(name) || rime.find_module(name) {
            throw RimeError("A Rime module named '" . name . "' is already registered.")
        }

        registration := HelloModuleRegistration(name, implementation, api)
        if !rime.register_module(registration.module) {
            throw RimeError("Failed to register hello module '" . name . "'.")
        }

        ; librime stores the RimeModule pointer without an unregister operation. Keep the descriptor,
        ; API table, callbacks, and implementation alive until process exit.
        this.registrations[name] := registration
        return registration
    }

    __New(name, implementation, api) {
        this.name := name
        this.implementation := implementation
        this.api := api
        this.module := RimeModule()
        this.module.module_name := name

        this.initialize_handler := this.OnInitialize.Bind(this)
        this.finalize_handler := this.OnFinalize.Bind(this)
        this.get_api_handler := this.OnGetApi.Bind(this)

        this.initialize_callback := CallbackCreate(this.initialize_handler, "C", 0)
        this.finalize_callback := CallbackCreate(this.finalize_handler, "C", 0)
        this.get_api_callback := CallbackCreate(this.get_api_handler, "C", 0)

        this.module.num_put("Ptr", this.initialize_callback, RimeModule.initialize_offset)
        this.module.num_put("Ptr", this.finalize_callback, RimeModule.finalize_offset)
        this.module.num_put("Ptr", this.get_api_callback, RimeModule.get_api_offset)
    }

    OnInitialize() {
        try {
            this.implementation.Initialize()
        } catch as err {
            ExitWithCallbackError(this.name . ".initialize", err)
        }
    }

    OnFinalize() {
        try {
            this.implementation.Finalize()
        } catch as err {
            ExitWithCallbackError(this.name . ".finalize", err)
        }
    }

    OnGetApi() {
        try {
            return this.api.Ptr
        } catch as err {
            ExitWithCallbackError(this.name . ".get_api", err)
        }
    }
}

; Layer 3: implements the module's behavior without knowing about native structs, callbacks, or registration.
class HelloModule {
    Initialize() {
        FileAppend("Hello Rime module initialized`n", "*")
    }

    Finalize() {
        FileAppend("Hello Rime module finalized`n", "*")
    }

    HandleHello() {
        MsgBox("Hello from the Rime module!")
    }
}

ExitWithCallbackError(callback_name, err) {
    FileAppend(
        "Uncaught exception in " . callback_name . " callback: " . err.Message
            . "`n  at " . err.What . "`n  " . err.Line . "`nStack:`n" . err.Stack . "`n",
        "*"
    )
    ExitApp 1
}

Main() {
    local rime := RimeApi()
    local traits := RimeTraits()
    local implementation
    local provider_api
    local registration
    local initialized := false
    local module
    local api_ptr
    local client_api

    traits.app_name := "rime.hello_module"
    traits.shared_data_dir := "rime"
    traits.user_data_dir := "rime"
    traits.modules := ["default", "hello_module"]

    rime.setup(traits)

    implementation := HelloModule()
    provider_api := HelloModuleApi.CreateProvider(implementation.HandleHello.Bind(implementation))
    registration := HelloModuleRegistration.Register(rime, "hello_module", implementation, provider_api)

    try {
        rime.initialize(traits)
        initialized := true

        module := rime.find_module("hello_module")
        if !module {
            throw RimeError("Cannot find hello module.")
        }

        api_ptr := module.get_api()
        if !api_ptr {
            throw RimeError("Hello module has no custom API.")
        }

        client_api := HelloModuleApi.FromPtr(api_ptr)
        if !client_api.Hello() {
            throw RimeError("Hello module does not provide hello().")
        }
    } finally {
        if initialized {
            rime.finalize()
        }
    }
}

if A_LineFile = A_ScriptFullPath {
    try {
        Main()
    } catch as err {
        FileAppend(
            "Uncaught exception: " . err.Message . "`n  at " . err.What . "`n  " . err.Line
                . "`nStack:`n" . err.Stack . "`n",
            "*"
        )
        ExitApp 1
    }
}
