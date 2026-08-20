# Rime tools

Examples to demonstrate the usages. Require `rime.dll` to run.

## Rime API Console

Ported from [rime_api_console.cc](https://github.com/rime/librime/blob/master/tools/rime_api_console.cc).

```powershell
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' rime_api_console.ahk
```

## Hello Rime Module

Demonstrate a custom Rime module in three layers: its API ABI, the registration adapter, and the implementation.

```powershell
& 'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe' rime_module.ahk | Write-Output
```
