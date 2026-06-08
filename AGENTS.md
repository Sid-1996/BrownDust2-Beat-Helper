# AGENTS.md — BrownDust2 Beat Helper

## 專案概述

AutoHotkey v2 腳本，自動化手機遊戲《棕色塵埃2》的音遊節奏小遊戲。透過 PixelSearch 偵測螢幕顏色，自動執行對應按鍵操作。

## 目錄結構

```
├── BrownDust2 Beat Helper.ahk   # 主程式 (AutoHotkey v2)
├── BrownDust2 Beat Helper.ico   # 應用程式圖示
├── Brown_Dust2_Settings.ini     # 設定檔 (自動讀寫)
├── build.ps1                    # 建置腳本 (編譯 exe + 打包 zip)
├── lang/
│   ├── zh-TW.ini                # 繁體中文語言包
│   └── en-US.ini                # 英文語言包
├── AGENTS.md                    # 本檔案 — AI agent 工作指引
├── CONTRIBUTING.md              # 貢獻指南
├── README.md                    # 專案說明文件
└── LICENSE                      # MIT License
```

## 建置流程

```powershell
.\build.ps1
```

執行後自動：
1. 讀取 `lang/zh-TW.ini` 中的 `version=` 作為版本號
2. 以 Ahk2Exe 編譯 `.ahk` → `.exe`
3. 壓縮 `exe + lang/` 為 `BrownDust2-Beat-Helper-v{version}.zip`

**相依工具：** AutoHotkey v2（scoop 安裝於 `C:\Users\user\scoop\apps\autohotkey\current`）

## AHK v2 撰寫規範

- 檔頭需有 `#Requires AutoHotkey v2.0`
- 全域變數需以 `global` 宣告（AHK v2 強制）
- PixelSearch 使用螢幕絕對座標：`CoordMode("Pixel", "Screen")`
- INI 設定檔儲存/載入使用 `IniRead` / `IniWrite`
- GUI 控制項使用 `Gui("+Resize")` 搭配事件綁定 `OnEvent`
- `SetTimer` 使用命名函式而非匿名 lambda，以便取消

## 語言檔維護

- 位置：`lang/` 目錄下
- 格式：純 `key=value`，無 `[Section]` 標頭
- 換行：值中的 `` `n `` 在載入時自動轉為實際換行
- 新增語言：在 `lang/` 新增 `{lang-code}.ini`，並在 `CreateMainGUI` 的下拉選單中加入選項
- 取值：`GetText("key_name")`，找不到 key 時回傳 key 本身

## 發版流程

1. 更新 `lang/*.ini` 的 `version=` 與 README 更新日誌
2. 執行 `.\build.ps1` 產出 exe 與 zip
3. Commit 文字檔案（不 commit build artifact）
4. 建立 GitHub Release：
   ```bash
   gh release create v1.0.2 \
     --title "BrownDust2-Beat-Helper v1.0.2" \
     --notes "版本說明" \
     "BrownDust2-Beat-Helper-v1.0.2.zip"
   ```

## 關鍵類別 / 函式速查

| 函式 | 位置 | 說明 |
|---|---|---|
| `CreateMainGUI()` | ~276 | 建立主控制視窗 |
| `LoadLanguage()` / `LoadLanguageFromINI()` | ~158 | 語言系統 (INI 解析) |
| `ToggleOverlay()` | ~370 | F3 開關偵測紅框 |
| `CreateResizableOverlay()` | ~387 | 建立可拖拽縮放的透明 overlay |
| `UpdateOverlayControls()` | ~822 | Resize 後更新 overlay 控制項位置 |
| `StartMainLoop()` | ~1050 | 主自動化循環 (顏色偵測 + 按鍵) |
| `ExecuteSingleTap()` / `ExecuteLongPress()` / `ExecuteHoldPress()` / `ExecuteRapidHit()` | ~1130 | 四種按鍵模式 |
| `ShowTooltip()` | ~1258 | 提示訊息 (Timer 管理) |
| `SafeExit()` | ~995 | 安全退出 (釋放按鍵 + 儲存設定) |
