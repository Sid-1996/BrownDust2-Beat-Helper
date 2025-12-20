; ═══════════════════════════════════════════════════════════════════
; Brown Dust 釣魚腳本 v2.0 (AutoHotkey v2)
; ═══════════════════════════════════════════════════════════════════
; 功能: 自動化釣魚流程，支援參數調整
; 作者: 優化版本
; 日期: 2024-12-20
; ═══════════════════════════════════════════════════════════════════

#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Window"
CoordMode "Pixel", "Window"
SendMode "Input"
SetTitleMatchMode 2
SetControlDelay 1
SetWinDelay 0
SetKeyDelay -1
SetMouseDelay -1
ProcessSetPriority "High"

; ═══════════════════════════════════════════════════════════════════
; 全域變數
; ═══════════════════════════════════════════════════════════════════
global isRunning := false
global imagePaths := Map()
global lastDetectionTime := 0
global lastSuccessTime := 0
global statusText := ""
global speedValue := ""
global cooldownValue := ""
global fishingAccValue := ""
global castValue := ""
global delayValue := ""
global bugDetectionValue := ""
global speedSlider := ""
global cooldownSlider := ""
global fishingAccSlider := ""
global castSlider := ""
global delaySlider := ""
global bugDetectionSlider := ""
global mainGui := ""
global guiVisible := true

; 可調整參數 (預設值)
global config := Map(
    "detectionSpeed", 1,
    "detectionCooldown", 100,
    "fishingAccuracy", 100,
    "collectAccuracy", 100,
    "startAccuracy", 100,
    "hookAccuracy", 0,
    "spaceDelay", 100,
    "castDuration", 300,
    "clickDelay", 50,
    "bugDetectionTimeout", 6000
)

; ═══════════════════════════════════════════════════════════════════
; 初始化
; ═══════════════════════════════════════════════════════════════════
InitializeImagePaths()
LoadConfig()
CreateGUI()

; 預載入圖片路徑
InitializeImagePaths() {
    global imagePaths
    baseDir := A_ScriptDir . "\image\"
    
    imagePaths["fishing"] := baseDir . "Screen_20251220220433.png"
    imagePaths["collect"] := baseDir . "Screen_20251220221404.png"
    imagePaths["start"] := baseDir . "Screen_20251220221757.png"
    imagePaths["hook"] := baseDir . "Screen_20251220222047.png"
    imagePaths["bagFull"] := baseDir . "Screen_20251221011220.png"
    imagePaths["sellItem1"] := baseDir . "Screen_20251221011333.png"
    imagePaths["sellItem2"] := baseDir . "Screen_20251221012203.png"
    imagePaths["sellItem3"] := baseDir . "Screen_20251221011643.png"
    imagePaths["confirm"] := baseDir . "Screen_20251221012010.png"
    imagePaths["specialState"] := baseDir . "Screen_20251221030115.png"
}

; ═══════════════════════════════════════════════════════════════════
; 建立圖形化使用者介面
; ═══════════════════════════════════════════════════════════════════
CreateGUI() {
    global config, statusText, speedValue, cooldownValue, fishingAccValue, castValue, delayValue, bugDetectionValue
    global speedSlider, cooldownSlider, fishingAccSlider, castSlider, delaySlider, bugDetectionSlider
    global mainGui
    
    ; 建立主視窗
    mainGui := Gui("", "Brown Dust 釣魚腳本 v2.0")
    mainGui.SetFont("s10", "Microsoft JhengHei")
    mainGui.BackColor := "0xF0F0F0"
    
    ; ===== 標題區域 =====
    mainGui.SetFont("s14 bold", "Microsoft JhengHei")
    mainGui.Add("Text", "x20 y15 w460 Center", "🎣 Brown Dust Sid釣魚腳本(非掛機) 🎣")
    mainGui.SetFont("s10 norm", "Microsoft JhengHei")
    
    ; ===== 快捷鍵說明 =====
    mainGui.Add("GroupBox", "x20 y50 w460 h100", "⌨️ 快捷鍵說明")
    mainGui.Add("Text", "x40 y75", "F1  :")
    mainGui.Add("Text", "x100 y75 cBlue", "顯示/隱藏面板")
    mainGui.Add("Text", "x40 y100", "F4  :")
    mainGui.Add("Text", "x100 y100 cGreen", "開始自動釣魚")
    mainGui.Add("Text", "x40 y125", "F8  :")
    mainGui.Add("Text", "x100 y125 cRed", "停止自動釣魚")
    mainGui.Add("Text", "x260 y75", "F11 :")
    mainGui.Add("Text", "x320 y75 cMaroon", "重新載入腳本")
    mainGui.Add("Text", "x260 y100", "F12 :")
    mainGui.Add("Text", "x320 y100 cMaroon", "結束腳本程式")
    
    ; ===== 狀態顯示 =====
    mainGui.Add("GroupBox", "x20 y160 w460 h60", "📊 當前狀態")
    statusText := mainGui.Add("Text", "x40 y185 w420 Center cRed", "⏸️ 未啟動")
    statusText.SetFont("s12 bold")
    
    ; ===== 參數調整區域 =====
    mainGui.Add("GroupBox", "x20 y230 w460 h370", "⚙️ 進階參數設定")
    
    ; 偵測速度
    mainGui.Add("Text", "x40 y260", "偵測速度 (毫秒):")
    speedSlider := mainGui.Add("Slider", "x200 y260 w170 Range1-100 ToolTip", config["detectionSpeed"])
    speedSlider.OnEvent("Change", UpdateSpeed)
    speedValue := mainGui.Add("Text", "x380 y260 w60 Right", config["detectionSpeed"])
    mainGui.Add("Text", "x40 y285 c888888", "(數值越小越快，建議: 1-10)")
    
    ; 冷卻時間
    mainGui.Add("Text", "x40 y315", "冷卻時間 (毫秒):")
    cooldownSlider := mainGui.Add("Slider", "x200 y315 w170 Range10-300 ToolTip", config["detectionCooldown"])
    cooldownSlider.OnEvent("Change", UpdateCooldown)
    cooldownValue := mainGui.Add("Text", "x380 y315 w60 Right", config["detectionCooldown"])
    mainGui.Add("Text", "x40 y340 c888888", "(防止重複觸發，建議: 50-150)")
    
    ; 釣魚按鈕準確度
    mainGui.Add("Text", "x40 y370", "釣魚按鈕準確度:")
    fishingAccSlider := mainGui.Add("Slider", "x200 y370 w170 Range0-255 ToolTip", config["fishingAccuracy"])
    fishingAccSlider.OnEvent("Change", UpdateFishingAcc)
    fishingAccValue := mainGui.Add("Text", "x380 y370 w60 Right", config["fishingAccuracy"])
    mainGui.Add("Text", "x40 y395 c888888", "(0=最精準 255=最寬鬆，建議: 50-150)")
    
    ; 拋竿持續時間
    mainGui.Add("Text", "x40 y425", "拋竿持續時間 (毫秒):")
    castSlider := mainGui.Add("Slider", "x200 y425 w170 Range50-800 ToolTip", config["castDuration"])
    castSlider.OnEvent("Change", UpdateCast)
    castValue := mainGui.Add("Text", "x380 y425 w60 Right", config["castDuration"])
    mainGui.Add("Text", "x40 y450 c888888", "(按住空白鍵時間，建議: 150-400)")
    
    ; 按鍵延遲
    mainGui.Add("Text", "x40 y480", "按鍵反應延遲 (毫秒):")
    delaySlider := mainGui.Add("Slider", "x200 y480 w170 Range10-200 ToolTip", config["spaceDelay"])
    delaySlider.OnEvent("Change", UpdateDelay)
    delayValue := mainGui.Add("Text", "x380 y480 w60 Right", config["spaceDelay"])
    mainGui.Add("Text", "x40 y505 c888888", "(按鍵後等待時間，建議: 30-100)")
    
    ; 異常排除超時時間
    mainGui.Add("Text", "x40 y535", "異常排除超時 (秒):")
    bugDetectionSlider := mainGui.Add("Slider", "x200 y535 w170 Range5000-10000 ToolTip", config["bugDetectionTimeout"])
    bugDetectionSlider.OnEvent("Change", UpdateBugDetection)
    bugDetectionValue := mainGui.Add("Text", "x380 y535 w60 Right", Round(config["bugDetectionTimeout"] / 1000))
    mainGui.Add("Text", "x40 y560 c888888", "(無法偵測時自動排除，建議: 5-10秒)")
    
    ; ===== 按鈕區域 =====
    mainGui.Add("Button", "x40 y590 w190 h40", "💾 儲存設定").OnEvent("Click", SaveConfig)
    mainGui.Add("Button", "x250 y590 w100 h40", "🔄 重置").OnEvent("Click", ResetConfig)
    mainGui.Add("Button", "x370 y590 w100 h40", "❌ 關閉").OnEvent("Click", (*) => mainGui.Hide())
    
    ; ===== 版權資訊 =====
    mainGui.Add("Text", "x20 y640 w460 Center c888888", "© 這是用來協助開圖鑑的 | 高難度魚類還須結合腳本配合手動")
    
    ; 顯示視窗
    mainGui.Show("w500 h675")
    guiVisible := true
}

; 更新滑桿數值的函數
UpdateSpeed(*) {
    global config, speedValue, speedSlider
    config["detectionSpeed"] := speedSlider.Value
    speedValue.Text := speedSlider.Value
}

UpdateCooldown(*) {
    global config, cooldownValue, cooldownSlider
    config["detectionCooldown"] := cooldownSlider.Value
    cooldownValue.Text := cooldownSlider.Value
}

UpdateFishingAcc(*) {
    global config, fishingAccValue, fishingAccSlider
    config["fishingAccuracy"] := fishingAccSlider.Value
    fishingAccValue.Text := fishingAccSlider.Value
}

UpdateCast(*) {
    global config, castValue, castSlider
    config["castDuration"] := castSlider.Value
    castValue.Text := castSlider.Value
}

UpdateDelay(*) {
    global config, delayValue, delaySlider
    config["spaceDelay"] := delaySlider.Value
    delayValue.Text := delaySlider.Value
}

UpdateBugDetection(*) {
    global config, bugDetectionValue, bugDetectionSlider
    config["bugDetectionTimeout"] := bugDetectionSlider.Value
    bugDetectionValue.Text := Round(bugDetectionSlider.Value / 1000)
}

; 儲存設定
SaveConfig(*) {
    global config
    configFile := A_ScriptDir . "\config.ini"
    
    IniWrite config["detectionSpeed"], configFile, "Settings", "detectionSpeed"
    IniWrite config["detectionCooldown"], configFile, "Settings", "detectionCooldown"
    IniWrite config["fishingAccuracy"], configFile, "Settings", "fishingAccuracy"
    IniWrite config["collectAccuracy"], configFile, "Settings", "collectAccuracy"
    IniWrite config["startAccuracy"], configFile, "Settings", "startAccuracy"
    IniWrite config["hookAccuracy"], configFile, "Settings", "hookAccuracy"
    IniWrite config["spaceDelay"], configFile, "Settings", "spaceDelay"
    IniWrite config["castDuration"], configFile, "Settings", "castDuration"
    IniWrite config["clickDelay"], configFile, "Settings", "clickDelay"
    IniWrite config["bugDetectionTimeout"], configFile, "Settings", "bugDetectionTimeout"
    
    ToolTip "✅ 設定已儲存！"
    SetTimer () => ToolTip(), -2000
}

; 重置設定
ResetConfig(*) {
    global config, speedSlider, cooldownSlider, fishingAccSlider, castSlider, delaySlider, bugDetectionSlider
    global speedValue, cooldownValue, fishingAccValue, castValue, delayValue, bugDetectionValue
    
    result := MsgBox("確定要重置所有設定為預設值嗎？", "確認重置", "YesNo Icon?")
    if result = "Yes" {
        config["detectionSpeed"] := 1
        config["detectionCooldown"] := 100
        config["fishingAccuracy"] := 100
        config["collectAccuracy"] := 100
        config["startAccuracy"] := 100
        config["hookAccuracy"] := 0
        config["spaceDelay"] := 100
        config["castDuration"] := 300
        config["clickDelay"] := 50
        config["bugDetectionTimeout"] := 6000
        
        speedSlider.Value := 1
        cooldownSlider.Value := 100
        fishingAccSlider.Value := 100
        castSlider.Value := 300
        delaySlider.Value := 100
        bugDetectionSlider.Value := 6000
        
        speedValue.Text := 1
        cooldownValue.Text := 100
        fishingAccValue.Text := 100
        castValue.Text := 300
        delayValue.Text := 100
        bugDetectionValue.Text := 6
        
        ToolTip "🔄 已重置為預設值！"
        SetTimer () => ToolTip(), -2000
    }
}

; 載入設定
LoadConfig() {
    global config
    configFile := A_ScriptDir . "\config.ini"
    
    if FileExist(configFile) {
        config["detectionSpeed"] := Integer(IniRead(configFile, "Settings", "detectionSpeed", 1))
        config["detectionCooldown"] := Integer(IniRead(configFile, "Settings", "detectionCooldown", 100))
        config["fishingAccuracy"] := Integer(IniRead(configFile, "Settings", "fishingAccuracy", 100))
        config["collectAccuracy"] := Integer(IniRead(configFile, "Settings", "collectAccuracy", 100))
        config["startAccuracy"] := Integer(IniRead(configFile, "Settings", "startAccuracy", 100))
        config["hookAccuracy"] := Integer(IniRead(configFile, "Settings", "hookAccuracy", 0))
        config["spaceDelay"] := Integer(IniRead(configFile, "Settings", "spaceDelay", 100))
        config["castDuration"] := Integer(IniRead(configFile, "Settings", "castDuration", 300))
        config["clickDelay"] := Integer(IniRead(configFile, "Settings", "clickDelay", 50))
        config["bugDetectionTimeout"] := Integer(IniRead(configFile, "Settings", "bugDetectionTimeout", 6000))
    }
}

; ═══════════════════════════════════════════════════════════════════
; 快捷鍵定義
; ═══════════════════════════════════════════════════════════════════

; F1: 顯示/隱藏 GUI 面板
F1:: {
    global mainGui, guiVisible
    if guiVisible {
        mainGui.Hide()
        guiVisible := false
        ToolTip "📋 GUI 面板已隱藏"
        SetTimer () => ToolTip(), -1500
    } else {
        mainGui.Show()
        guiVisible := true
        ToolTip "📋 GUI 面板已顯示"
        SetTimer () => ToolTip(), -1500
    }
}

; F4: 開始循環
F4:: {
    global isRunning, statusText, config
    if WinExist("BrownDust") {
        WinActivate
        WinWaitActive "BrownDust", , 2
        isRunning := true
        SetTimer FishingLoop, config["detectionSpeed"]
        statusText.Text := "✅ 執行中..."
        statusText.SetFont("cGreen")
        ToolTip "🎣 [F4] 釣魚腳本已啟動！(偵測速度: " . config["detectionSpeed"] . "ms)"
        SetTimer () => ToolTip(), -2000
    } else {
        MsgBox "❌ 找不到 BrownDust 遊戲視窗！`n`n請確保遊戲已開啟且視窗標題包含 'BrownDust'", "錯誤", "Icon!"
        ToolTip "❌ [F4] 找不到遊戲視窗"
        SetTimer () => ToolTip(), -2000
    }
}

; F8: 結束循環
F8:: {
    global isRunning, statusText
    isRunning := false
    SetTimer FishingLoop, 0
    statusText.Text := "⏸️ 已停止"
    statusText.SetFont("cRed")
    ToolTip "⏸️ [F8] 釣魚腳本已停止"
    SetTimer () => ToolTip(), -2000
}

; F11: 重新載入
F11:: {
    ToolTip "🔄 [F11] 重新載入腳本中..."
    Sleep 500
    Reload
}

; F12: 結束腳本
F12:: {
    global isRunning
    ToolTip "🛑 [F12] 確認結束腳本..."
    result := MsgBox("確定要結束腳本嗎？", "確認結束", "YesNo Icon?")
    if result = "Yes" {
        isRunning := false
        SetTimer FishingLoop, 0
        ToolTip "🛑 [F12] 腳本已結束"
        SetTimer () => ToolTip(), -2000
        Sleep 500
        ExitApp
    } else {
        ToolTip "❌ [F12] 已取消結束"
        SetTimer () => ToolTip(), -1500
    }
}

; ═══════════════════════════════════════════════════════════════════
; 主要釣魚循環函數
; ═══════════════════════════════════════════════════════════════════
FishingLoop() {
    global isRunning, imagePaths, lastDetectionTime, lastSuccessTime, config
    
    if !isRunning
        return
    
    if !WinActive("BrownDust")
        return
    
    currentTime := A_TickCount
    if (currentTime - lastDetectionTime) < config["detectionCooldown"]
        return
    
    ; === 優先級 -1: 背包滿清包檢測 (最高優先級) ===
    try {
        if ImageSearch(&FoundX, &FoundY, 835, 97, 1085, 257, "*100 " . imagePaths["bagFull"]) {
            lastDetectionTime := A_TickCount
            lastSuccessTime := A_TickCount
            ToolTip "💼 [檢測] 背包已滿，開始清包程序"
            SetTimer () => ToolTip(), -3000
            ClearBackpack()
            return
        }
    }
    
    ; === 優先級 0: 釣魚按鈕檢測 (次高優先級) ===
    try {
        searchStr := "*" . config["fishingAccuracy"] . " *TransBlack " . imagePaths["fishing"]
        if ImageSearch(&FoundX, &FoundY, 764, 929, 1233, 965, searchStr) {
            lastDetectionTime := A_TickCount
            lastSuccessTime := A_TickCount
            ToolTip "🎣 [按鈕] 檢測到釣魚按鈕，按下空白鍵"
            SetTimer () => ToolTip(), -1000
            SendEvent "{Space}"
            Sleep config["spaceDelay"]
            return
        }
    }
    
    ; === 優先級 1: 位置調整檢測 ===
    try {
        if ImageSearch(&FoundX, &FoundY, 759, 94, 1169, 258, "*100 image\Screen_20251221003629.png") {
            lastDetectionTime := A_TickCount
            lastSuccessTime := A_TickCount
            ToolTip "📍 [檢測] 位置調整中"
            SetTimer () => ToolTip(), -1000
            SendEvent "{s Up}"
            Sleep 200
            SendEvent "{s Down}"
            Sleep 200
            SendEvent "{s Up}"
            Sleep 200
            return
        }
    }
    
    ; === 優先級 2: 收魚檢測 ===
    try {
        searchStr := "*" . config["collectAccuracy"] . " *TransBlack " . imagePaths["collect"]
        if ImageSearch(&FoundX, &FoundY, 742, 100, 1215, 200, searchStr) {
            lastDetectionTime := A_TickCount
            lastSuccessTime := A_TickCount
            ToolTip "🎁 [收魚] 檢測到可收魚，執行收魚"
            SetTimer () => ToolTip(), -1000
            CenterX := FoundX + GetImageWidth(searchStr) // 2
            CenterY := FoundY + GetImageHeight(searchStr) // 2
            Click CenterX, CenterY
            Sleep config["clickDelay"]
            return
        }
    }
    
    ; === 優先級 3: 開始釣魚檢測 ===
    try {
        searchStr := "*" . config["startAccuracy"] . " *TransBlack " . imagePaths["start"]
        if ImageSearch(&FoundX, &FoundY, 1500, 876, 1541, 900, searchStr) {
            lastDetectionTime := A_TickCount
            lastSuccessTime := A_TickCount
            ToolTip "🚀 [拋竿] 開始拋竿，按住空白鍵 " . config["castDuration"] . "ms"
            SetTimer () => ToolTip(), -2000
            SendEvent "{Space Up}"
            Sleep 100
            SendEvent "{Space Down}"
            Sleep config["castDuration"]
            SendEvent "{Space Up}"
            return
        }
    }
    
    ; === 優先級 4: 魚上鉤拉線檢測 ===
    try {
        searchStr := "*" . config["hookAccuracy"] . " *TransBlack " . imagePaths["hook"]
        if ImageSearch(&FoundX, &FoundY, 1696, 770, 1742, 796, searchStr) {
            lastDetectionTime := A_TickCount
            lastSuccessTime := A_TickCount
            ToolTip "⚡ [上鉤] 魚上鉤！拉線中"
            SetTimer () => ToolTip(), -1000
            SendEvent "{Space Up}"
            Sleep 100
            SendEvent "{Space}"
            Sleep config["spaceDelay"]
            return
        }
    }
    
    ; === 優先級 5: 異常排除檢測 (最低優先級) ===
    currentTime := A_TickCount
    if (currentTime - lastSuccessTime) > config["bugDetectionTimeout"] {
        HandleBugDetection()
        lastSuccessTime := A_TickCount
    }
}

; ═══════════════════════════════════════════════════════════════════
; 輔助函數
; ═══════════════════════════════════════════════════════════════════

; 背包清理函數
ClearBackpack() {
    global imagePaths, config
    
    ToolTip "⚠️ 檢測到背包已滿，開始清包程序..."
    Sleep 500
    
    ; 打開交易介面
    SendEvent "{t}"
    Sleep 1000
    
    ; 出售物品 1
    try {
        if ImageSearch(&FoundX, &FoundY, 1539, 967, 1796, 1050, "*100 " . imagePaths["sellItem1"]) {
            Click FoundX, FoundY
            Sleep 1000
        }
    }
    
    ; 出售物品 2
    try {
        if ImageSearch(&FoundX, &FoundY, 1512, 979, 1643, 1036, "*100 " . imagePaths["sellItem2"]) {
            Click FoundX, FoundY
            Sleep 1000
        }
    }
    
    ; 出售物品 3
    try {
        if ImageSearch(&FoundX, &FoundY, 1724, 953, 1821, 1056, "*100 " . imagePaths["sellItem3"]) {
            Click FoundX, FoundY
            Sleep 1000
        }
    }
    
    ; 確認售出
    try {
        if ImageSearch(&FoundX, &FoundY, 966, 640, 1206, 716, "*100 " . imagePaths["confirm"]) {
            Click FoundX, FoundY
            Sleep 1000
        }
    }
    
    ; 關閉介面
    SendEvent "{Escape}"
    Sleep 1000
    
    ToolTip "✅ 背包清理完成！"
    SetTimer () => ToolTip(), -2000
}

; 異常排除函數
HandleBugDetection() {
    ToolTip "🐛 檢測到卡住！執行異常排除程序..."
    
    ; 釋放 SPACE
    SendEvent "{Space Up}"
    Sleep 50
    
    ; 點擊螢幕正中央
    screenCenterX := A_ScreenWidth // 2
    screenCenterY := A_ScreenHeight // 2
    Click screenCenterX, screenCenterY
    Sleep 200
    
    ; 長按 SPACE 100 毫秒
    SendEvent "{Space Down}"
    Sleep 100
    SendEvent "{Space Up}"
    Sleep 200
    
    ToolTip "✅ 異常排除完成，繼續釣魚"
    SetTimer () => ToolTip(), -2000
}

GetImageWidth(FilePath) {
    static cache := Map()
    CleanPath := RegExReplace(FilePath, "^(\*\w+\s)+")
    
    if cache.Has(CleanPath)
        return cache[CleanPath]
    
    TempGui := Gui()
    TempGui.Add("Picture", "vPic", CleanPath)
    Pic := TempGui["Pic"]
    Pic.GetPos(, , &w, &h)
    TempGui.Destroy()
    
    cache[CleanPath] := w
    return w
}

GetImageHeight(FilePath) {
    static cache := Map()
    CleanPath := RegExReplace(FilePath, "^(\*\w+\s)+")
    
    if cache.Has(CleanPath)
        return cache[CleanPath]
    
    TempGui := Gui()
    TempGui.Add("Picture", "vPic", CleanPath)
    Pic := TempGui["Pic"]
    Pic.GetPos(, , &w, &h)
    TempGui.Destroy()
    
    cache[CleanPath] := h
    return h
}