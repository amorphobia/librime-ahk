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
 * Original C++ code rime_api_console.cc
 *
 * Copyright RIME Developers
 * Distributed under the BSD License
 *
 * 2011-08-29 GONG Chen <chen.sst@gmail.com>
 *
 */
#Requires AutoHotkey v2.0
#Include "..\rime_api.ahk"

Print(GuiCtrlObj, output) {
    static text
    if not IsSet(text)
        text := output
    else text := GuiCtrlObj.Value . "`r`n" . output
    GuiCtrlObj.Value := text
    ControlSend("^{End}", GuiCtrlObj)
}

PrintStatus(GuiCtrlObj, status) {
    Print(GuiCtrlObj, "schema: " . status.schema_id . " / " . status.schema_name)
    out := "status: "
    if status.is_disabled
        out := out . "disabled "
    if status.is_composing
        out := out . "composing "
    if status.is_ascii_mode
        out := out . "ascii "
    if status.is_full_shape
        out := out . "full_shape "
    if status.is_simplified
        out := out . "simplified "
    Print(GuiCtrlObj, out)
}

PrintComposition(GuiCtrlObj, composition) {
    if not preedit := composition.preedit
        return
    len := StrPut(preedit, "UTF-8")
    start := composition.sel_start
    end := composition.sel_end
    cursor := composition.cursor_pos
    out := ""
    i := 0
    Loop Parse preedit {
        if start < end {
            if i = start
                out := out . "["
            else if i = end
                out := out . "]"
        }
        if i = cursor
            out := out . "|"
        if i < len
            out := out . A_LoopField
        i := i + StrPut(A_LoopField, "UTF-8") - 1
    }
    ; AHK Loop Parse string does not include ending '\0'
    if start < end and i = end
        out := out . "]"
    if i = cursor
        out := out . "|"
    Print(GuiCtrlObj, out)
}

PrintMenu(GuiCtrlObj, menu) {
    if menu.num_candidates = 0
        return
    Print(GuiCtrlObj, "page: " . menu.page_no + 1 . (menu.is_last_page ? "$" : " ") . " (of size " . menu.page_size . ")")
    cands := menu.candidates
    Loop menu.num_candidates {
        highlighted := A_Index = menu.highlighted_candidate_index + 1
        Print(GuiCtrlObj, A_Index . ". " . (highlighted ? "[" : " ") . cands[A_Index].text . (highlighted ? "]" : " ") . cands[A_Index].comment)
    }
}

PrintContext(GuiCtrlObj, context) {
    if context.composition.length > 0 {
        PrintComposition(GuiCtrlObj, context.composition)
        PrintMenu(GuiCtrlObj, context.menu)
    } else
        Print(GuiCtrlObj, "(not composing)")
}

PrintSession(GuiCtrlObj, sid) {
    api := RimeApi()

    if commit := api.get_commit(sid) {
        Print(GuiCtrlObj, "commit: " . commit.text)
        api.free_commit(commit)
    }

    if status := api.get_status(sid) {
        PrintStatus(GuiCtrlObj, status)
        api.free_status(status)
    }

    if context := api.get_context(sid) {
        PrintContext(GuiCtrlObj, context)
        api.free_context(context)
    }
}

ExecuteSpecialCommand(GuiCtrlObj, line, sid) {
    api := RimeApi()
    if line = "print schema list" {
        if list := api.get_schema_list() {
            Print(GuiCtrlObj, "schema list:")
            schemas := list.list
            Loop list.size
                Print(GuiCtrlObj, A_Index . ". " . schemas[A_Index].name . " [" . schemas[A_Index].schema_id . "]")
            api.free_schema_list(list)
        }
        if current := api.get_current_schema(sid, 100)
            Print(GuiCtrlObj, "current schema: [" . current . "]")
        return true
    }
    if RegExMatch(line, "select schema (.+)", &matched) {
        schema_id := matched[1]
        if api.select_schema(sid, schema_id)
            Print(GuiCtrlObj, "selected schema: [" . schema_id . "]")
        return true
    }
    if RegExMatch(line, "select candidate (.+)", &matched) {
        index := Integer(matched[1])
        if index > 0 and api.select_candidate_on_current_page(sid, index - 1)
            PrintSession(GuiCtrlObj, sid)
        else
            MsgBox("cannot select candidate at index " . index . ".", "Error")
        return true
    }
    if line = "print candidate list" {
        if iterator := api.candidate_list_begin(sid) {
            Loop {
                if not api.candidate_list_next(iterator)
                    break
                out := iterator.index + 1 . ". " . iterator.candidate.text
                if comment := iterator.candidate.comment
                    out := out . " (" . comment . ")"
                Print(GuiCtrlObj, out)
            }
            api.candidate_list_end(iterator)
        } else
            Print(GuiCtrlObj, "no candidates.")
        return true
    }
    if RegExMatch(line, "set option (.+)", &matched) {
        is_on := true
        option := matched[1]
        if SubStr(option, 1, 1) = "!" {
            is_on := false
            option := SubStr(option, 2)
        }
        api.set_option(sid, option, is_on)
        Print(GuiCtrlObj, option . " set " . (is_on ? "on" : "off") . ".")
        return true
    }
    return false
}

on_message(context_object, session_id, message_type, message_value) {
    msg := StrGet(message_type, "UTF-8") . ": " . StrGet(message_value, "UTF-8")
    TrayTip(msg, "Session: " . session_id)
}

Send_KeySequence(&rimeReady, &session_id, GuiCtrlObj, Info) {
    if not rimeReady
        return
    api := RimeApi()
    GuiObj := GuiCtrlObj.Gui
    printGuiCtrlObj := GuiObj["Log"]
    line := GuiObj["Input"].Value
    GuiObj["Input"].Value := ""
    if not line
        return
    if line = "exit"
        ExitApp
    Print(printGuiCtrlObj, "Input: `"" . line . "`"")
    if ExecuteSpecialCommand(printGuiCtrlObj, line, session_id)
        return
    if api.simulate_key_sequence(session_id, line)
        PrintSession(printGuiCtrlObj, session_id)
    else
        MsgBox("Error processing key sequence: " . line, "Error")
}

main() {
    rimeReady := false
    rime := RimeApi()
    traits := RimeTraits()
    traits.app_name := "rime.ahk_console"
    traits.shared_data_dir := "rime"
    traits.user_data_dir := "rime"
    session_id := 0

    Main := Gui()
    Main.MarginX := 15
    Main.MarginY := 15
    Main.SetFont("S12", "Microsoft YaHei UI")
    Main.Title := "AHK Rime Console"
    maxLogLine := 12
    Main.OnEvent("Close", (*) => ExitApp)
    logs := Main.AddEdit("vLog xm ym w480 ReadOnly VScroll r" . maxLogLine)
    inputs := Main.AddEdit("vInput -Multi w480")
    btn := Main.AddButton("Default Hidden w0 h0 vDftBtn")
    btn.OnEvent("Click", Send_KeySequence.Bind(&rimeReady, &session_id))
    ControlFocus(Main["Input"])
    Main.Show("AutoSize")

    rime.setup(traits)
    rime.set_notification_handler(on_message, 0)

    Print(logs, "initializing...")

    rime.initialize(0)
    full_check := true
    success := rime.start_maintenance(full_check)
    if success {
        rime.join_maintenance_thread()
    }

    rimeReady := true
    Print(logs, "ready.")

    session_id := rime.create_session()
    if not session_id {
        MsgBox("Error creating rime session.", "Error")
        ExitApp(1)
    }

    Main.Title := "AHK Rime Console (Session " . session_id . ")"

    OnExit ExitRimeConsole

    ExitRimeConsole(ExitReason, ExitCode) {
        rime.destroy_session(session_id)
        rime.finalize()
    }
}

main()
