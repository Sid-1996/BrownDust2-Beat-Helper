#Requires AutoHotkey v2.0
#SingleInstance Force

; @Purpose: 棕色塵埃2 
; @Author: Sid  
; @Version: 1.0.2
; @LastUpdated: 2025-08-16
; @NewFeatures: 可調整大小的拖拽框、INI設定儲存/載入

; === 系統權限檢查 ===
if !A_IsAdmin {
    result := MsgBox("此腳本需要管理員權限才能正常運作`n是否重新以管理員身份執行？", "權限不足", "YesNo Icon!")
    if (result = "Yes") {
        try {
            Run('*RunAs "' . A_ScriptFullPath . '"')
        }
        ExitApp()
    } else {
        ExitApp()
    }
}

; === 全域變數宣告 ===
global loopRunning := false
global loopActive := false  
global colorVariation := 10
global showOverlay := false
global mainGui := ""

; INI檔案路徑
global iniFile := A_ScriptDir . "\Brown_Dust2_Settings.ini"

; 使用Map物件管理所有overlay實例
global overlayMap := Map()

; 拖拽狀態管理
global isDraggingAny := false
global currentDragOverlay := ""
global dragMode := ""  ; "move" 或 "resize"
global resizeCorner := ""  ; "tl", "tr", "bl", "br"

; 平滑拖拽相關變數
global lastSmoothX := 0
global lastSmoothY := 0
global targetX := 0
global targetY := 0
global smoothingFactor := 0.3  ; 平滑係數 (0.1-0.5, 越小越平滑)

; 調整大小平滑變數
global lastSmoothWidth := 0
global lastSmoothHeight := 0
global targetWidth := 0
global targetHeight := 0
global resizeSmoothingFactor := 0.2  ; 調整大小平滑係數

; 預設遊戲區域座標定義 (1920x1080解析度)
global defaultCoords := {
    leftBtn: {x1: 122, y1: 733, x2: 322, y2: 871},
    rightBtn: {x1: 1607, y1: 741, x2: 1830, y2: 881},
    rapidHit: {x1: 1605, y1: 1065, x2: 1797, y2: 1079}
}

; 當前使用的座標 (可被修改)
global leftBtn := {x1: 122, y1: 733, x2: 322, y2: 871}
global rightBtn := {x1: 1607, y1: 741, x2: 1830, y2: 881}
global rapidHit := {x1: 1605, y1: 1065, x2: 1797, y2: 1079}

; 顏色定義 (BGR格式)
global COLOR_BLUE := 0x116AF6    ; 藍色按鈕
global COLOR_PINK := 0xE53172    ; 粉色長按
global COLOR_GREEN := 0x5AC694   ; 綠色持續
global COLOR_BLACK := 0x000007   ; 黑色連擊

; 偵測結果座標
global foundX := 0
global foundY := 0

; GUI控制項引用
global variationSlider := ""
global variationText := ""
global statusBar := ""

; 語言系統變數
global currentLanguage := "zh-TW"  ; 預設語言
global languageData := ""  ; 語言包數據
global langDir := A_ScriptDir . "\lang"  ; 語言包目錄
global languageDropdown := ""  ; 語言選擇下拉選單

; === 載入設定檔 ===
LoadSettings() {
    global leftBtn, rightBtn, rapidHit, colorVariation, iniFile
    
    try {
        ; 載入左側按鈕座標
        leftBtn.x1 := IniRead(iniFile, "LeftButton", "x1", leftBtn.x1)
        leftBtn.y1 := IniRead(iniFile, "LeftButton", "y1", leftBtn.y1)
        leftBtn.x2 := IniRead(iniFile, "LeftButton", "x2", leftBtn.x2)
        leftBtn.y2 := IniRead(iniFile, "LeftButton", "y2", leftBtn.y2)
        
        ; 載入右側按鈕座標
        rightBtn.x1 := IniRead(iniFile, "RightButton", "x1", rightBtn.x1)
        rightBtn.y1 := IniRead(iniFile, "RightButton", "y1", rightBtn.y1)
        rightBtn.x2 := IniRead(iniFile, "RightButton", "x2", rightBtn.x2)
        rightBtn.y2 := IniRead(iniFile, "RightButton", "y2", rightBtn.y2)
        
        ; 載入連擊區域座標
        rapidHit.x1 := IniRead(iniFile, "RapidHit", "x1", rapidHit.x1)
        rapidHit.y1 := IniRead(iniFile, "RapidHit", "y1", rapidHit.y1)
        rapidHit.x2 := IniRead(iniFile, "RapidHit", "x2", rapidHit.x2)
        rapidHit.y2 := IniRead(iniFile, "RapidHit", "y2", rapidHit.y2)
        
        ; 載入顏色容錯率
        colorVariation := IniRead(iniFile, "Settings", "ColorVariation", colorVariation)
        
        ; 載入語言設置
        currentLanguage := IniRead(iniFile, "Settings", "Language", "zh-TW")
        
    } catch {
        ; 如果讀取失敗，使用預設值
    }
}

; === 儲存設定檔 ===
SaveSettings() {
    global leftBtn, rightBtn, rapidHit, colorVariation, iniFile
    
    try {
        ; 儲存左側按鈕座標
        IniWrite(leftBtn.x1, iniFile, "LeftButton", "x1")
        IniWrite(leftBtn.y1, iniFile, "LeftButton", "y1")
        IniWrite(leftBtn.x2, iniFile, "LeftButton", "x2")
        IniWrite(leftBtn.y2, iniFile, "LeftButton", "y2")
        
        ; 儲存右側按鈕座標
        IniWrite(rightBtn.x1, iniFile, "RightButton", "x1")
        IniWrite(rightBtn.y1, iniFile, "RightButton", "y1")
        IniWrite(rightBtn.x2, iniFile, "RightButton", "x2")
        IniWrite(rightBtn.y2, iniFile, "RightButton", "y2")
        
        ; 儲存連擊區域座標
        IniWrite(rapidHit.x1, iniFile, "RapidHit", "x1")
        IniWrite(rapidHit.y1, iniFile, "RapidHit", "y1")
        IniWrite(rapidHit.x2, iniFile, "RapidHit", "x2")
        IniWrite(rapidHit.y2, iniFile, "RapidHit", "y2")
        
        ; 儲存顏色容錯率
        IniWrite(colorVariation, iniFile, "Settings", "ColorVariation")
        
        ; 儲存語言設置
        IniWrite(currentLanguage, iniFile, "Settings", "Language")
        
    } catch {
        ; 儲存失敗處理
        ShowTooltip(GetText("tooltip_settings_save_fail"), 2000)
    }
}

; === 載入語言包 ===
LoadLanguage(langCode) {
    global languageData, langDir, currentLanguage
    
    langFile := langDir . "\" . langCode . ".ini"
    
    if !FileExist(langFile) {
        langCode := "zh-TW"
        langFile := langDir . "\" . langCode . ".ini"
    }
    
    languageData := LoadLanguageFromINI(langFile)
    
    if (languageData.Count = 0) {
        return false
    }
    
    currentLanguage := langCode
    return true
}

; === 從INI檔案載入語言數據 ===
LoadLanguageFromINI(langFile) {
    result := Map()
    
    try {
        fileContent := FileRead(langFile, "UTF-8")
        lines := StrSplit(fileContent, "`n", "`r")
        
        for line in lines {
            trimmed := Trim(line)
            
            if (trimmed = "" || SubStr(trimmed, 1, 1) = ";" || SubStr(trimmed, 1, 1) = "#")
                continue
            
            pos := InStr(trimmed, "=")
            if (pos) {
                key := SubStr(trimmed, 1, pos - 1)
                value := SubStr(trimmed, pos + 1)
                value := StrReplace(value, "``n", "`n")
                result[Trim(key)] := value
            }
        }
    } catch {
    }
    
    return result
}

; === 獲取語言文字 ===
GetText(key) {
    global languageData
    
    if (languageData.Has(key)) {
        return languageData[key]
    } else {
        return key  ; 如果找不到，返回key本身
    }
}

; === 語言切換處理 ===
SwitchLanguage(langCode) {
    global mainGui, languageDropdown
    
    ; 載入新語言
    if (LoadLanguage(langCode)) {
        ; 重新創建GUI以應用新語言
        mainGui.Destroy()
        CreateMainGUI()
        
        ; 顯示切換成功提示
        ShowTooltip("✅ " . GetText("settings_saved"), 1500)
    } else {
        ; 語言載入失敗
        ShowTooltip(GetText("tooltip_language_load_fail"), 2000)
    }
}

; === F1: 恢復預設座標 ===
F1::RestoreDefaultCoordinates()

RestoreDefaultCoordinates() {
    global leftBtn, rightBtn, rapidHit, defaultCoords, showOverlay
    
    ; 恢復預設座標
    leftBtn.x1 := defaultCoords.leftBtn.x1
    leftBtn.y1 := defaultCoords.leftBtn.y1
    leftBtn.x2 := defaultCoords.leftBtn.x2
    leftBtn.y2 := defaultCoords.leftBtn.y2
    
    rightBtn.x1 := defaultCoords.rightBtn.x1
    rightBtn.y1 := defaultCoords.rightBtn.y1
    rightBtn.x2 := defaultCoords.rightBtn.x2
    rightBtn.y2 := defaultCoords.rightBtn.y2
    
    rapidHit.x1 := defaultCoords.rapidHit.x1
    rapidHit.y1 := defaultCoords.rapidHit.y1
    rapidHit.x2 := defaultCoords.rapidHit.x2
    rapidHit.y2 := defaultCoords.rapidHit.y2
    
    ; 儲存設定
    SaveSettings()
    
    ; 如果紅框正在顯示，重新建立以反映新座標
    if (showOverlay) {
        DestroyAllOverlays()
        Sleep(100)
        CreateResizableOverlay("Left", leftBtn, GetText("left_button"))
        CreateResizableOverlay("Right", rightBtn, GetText("right_button")) 
        CreateResizableOverlay("Rapid", rapidHit, GetText("rapid_hit"))
    }
    
    ShowTooltip(GetText("tooltip_restore"), 3000)
}

; === 建立主GUI介面 ===
CreateMainGUI() {
    global mainGui, colorVariation, variationSlider, variationText, statusBar, languageDropdown
    
    ; 先載入語言包
    LoadLanguage(currentLanguage)
    
    ; 建立主視窗
    mainGui := Gui("+Resize -MaximizeBox", GetText("title") . " " . GetText("version"))
    mainGui.OnEvent("Close", (*) => SafeExit())
    mainGui.OnEvent("Size", GuiResizeHandler)
    
    ; 設定現代化字體
    mainGui.SetFont("s10", "Microsoft JhengHei")
    
    ; === 標題區域 ===
    titleText := mainGui.Add("Text", "x20 y15 w460 Center cNavy", "🎮 " . GetText("title") . " 🎮")
    titleText.SetFont("s12 Bold")
    
    ; === 語言選擇 ===
    mainGui.Add("GroupBox", "x20 y45 w460 h40", GetText("language"))
    languageDropdown := mainGui.Add("DropDownList", "x30 y60 w150 Choose" . (currentLanguage = "zh-TW" ? "1" : "2"), ["zh-TW|繁體中文", "en-US|English"])
    languageDropdown.OnEvent("Change", LanguageChangeHandler)
    
    ; === 系統需求說明 ===
    mainGui.Add("GroupBox", "x20 y95 w460 h90", GetText("system_requirements"))
    mainGui.Add("Text", "x30 y115 cBlue", "• " . GetText("resolution"))
    mainGui.Add("Text", "x30 y135 cBlue", "• " . GetText("difficulty"))
    mainGui.Add("Text", "x30 y155 cBlue", "• " . GetText("permissions"))
    
    ; === 控制說明區域 ===
    mainGui.Add("GroupBox", "x20 y195 w460 h150", GetText("controls"))
    mainGui.Add("Text", "x30 y215 cGreen", GetText("f1_help"))
    mainGui.Add("Text", "x30 y235 cGreen", GetText("f3_help"))
    mainGui.Add("Text", "x30 y255 cGreen", GetText("f4_help")) 
    mainGui.Add("Text", "x30 y275 cGreen", GetText("f12_help"))
    mainGui.Add("Text", "x30 y295 cRed", GetText("warning"))
    mainGui.Add("Text", "x30 y315 cPurple", GetText("drag_help"))
    
    ; === 參數調整區域 ===
    mainGui.Add("GroupBox", "x20 y355 w460 h80", GetText("parameters"))
    mainGui.Add("Text", "x30 y375 w120", GetText("color_tolerance"))
    variationSlider := mainGui.Add("Slider", "x150 y375 w200 h30 Range1-50 ToolTip", colorVariation)
    variationText := mainGui.Add("Text", "x360 y375 w60 Center Border", colorVariation)
    mainGui.Add("Text", "x30 y405 cGray", GetText("tolerance_hint"))
    
    ; 設定滑桿事件處理
    variationSlider.OnEvent("Change", UpdateVariation)
    
    ; === 狀態顯示區域 ===  
    statusBar := mainGui.Add("StatusBar", "", GetText("status_text") . ": " . GetText("status_ready") . " | " . GetText("color_tolerance") . ": " . colorVariation . " | " . GetText("version") . " 製作 by 考你媽台清交(Sid)")
    
    ; 顯示主視窗
    mainGui.Show("w500 h470")
}

; === 語言切換處理函數 ===
LanguageChangeHandler(*) {
    global languageDropdown
    
    ; 獲取選擇的語言代碼
    selectedLang := languageDropdown.Text
    
    ; 提取語言代碼（格式：zh-TW|繁體中文）
    langCode := StrSplit(selectedLang, "|")[1]
    
    ; 切換語言
    SwitchLanguage(langCode)
}

; === GUI視窗大小調整處理 ===
GuiResizeHandler(GuiObj, MinMax, Width, Height) {
    ; 當視窗大小改變時的處理邏輯 (預留擴展)
}

; === 更新容錯率數值 ===
UpdateVariation(*) {
    global colorVariation, loopRunning, variationSlider, variationText, statusBar
    
    ; 獲取滑桿當前數值  
    colorVariation := variationSlider.Value
    
    ; 更新顯示文字
    variationText.Text := colorVariation
    
    ; 儲存設定
    SaveSettings()
    
    ; 更新狀態列資訊
    statusText := GetText("status_text") . ": " . (loopRunning ? GetText("status_running") : GetText("status_stopped")) . " | " . GetText("color_tolerance") . ": " . colorVariation . " | " . GetText("version") . " 製作 by 考你媽台清交(Sid)"
    statusBar.Text := statusText
}

; === F3: 顯示/隱藏偵測範圍 ===
F3::ToggleOverlay()

ToggleOverlay() {
    global showOverlay, leftBtn, rightBtn, rapidHit, overlayMap
    
    showOverlay := !showOverlay
    
    if (showOverlay) {
        CreateResizableOverlay("Left", leftBtn, GetText("left_button"))
        CreateResizableOverlay("Right", rightBtn, GetText("right_button")) 
        CreateResizableOverlay("Rapid", rapidHit, GetText("rapid_hit"))
        
        ShowTooltip(GetText("tooltip_overlay_show"), 5000)
    } else {
        DestroyAllOverlays()
        SaveSettings()  ; 隱藏時儲存設定
        ShowTooltip(GetText("tooltip_overlay_hide"), 2000)
    }
}

; === 建立可調整大小的偵測範圍紅框 ===
CreateResizableOverlay(name, area, description := "") {
    global overlayMap, leftBtn, rightBtn, rapidHit
    
    ; 如果該名稱的overlay已存在，先安全銷毀
    if (overlayMap.Has(name)) {
        try {
            overlayMap[name].gui.Destroy()
        }
        overlayMap.Delete(name)
    }
    
    ; 計算區域尺寸
    width := area.x2 - area.x1
    height := area.y2 - area.y1
    
    ; 建立可調整大小的透明視窗
    overlayGui := Gui("+AlwaysOnTop -Caption +ToolWindow", "Overlay_" . name)
    overlayGui.BackColor := "Black"
    overlayGui.MarginX := 0
    overlayGui.MarginY := 0
    
    ; 儲存區域引用和原始資訊
    overlayData := {
        gui: overlayGui,
        name: name,
        areaRef: (name = "Left") ? leftBtn : (name = "Right") ? rightBtn : rapidHit,
        width: width,
        height: height,
        description: description,
        isDragging: false,
        startMouseX: 0,
        startMouseY: 0,
        startWinX: 0,
        startWinY: 0,
        originalWidth: width,
        originalHeight: height
    }
    
    ; 建立拖拽區域 (中央區域用於移動)
    ; 使用動態邊距以確保拖拽區域始終具有最小尺寸
    minDragSize := 20
    centerMarginX := Min(15, Max(0, (width - minDragSize) / 2))
    centerMarginY := Min(15, Max(0, (height - minDragSize) / 2))
    dragWidth := Max(minDragSize, width - centerMarginX * 2)
    dragHeight := Max(minDragSize, height - centerMarginY * 2)
    
    dragArea := overlayGui.Add("Text", "x" . centerMarginX . " y" . centerMarginY . " w" . dragWidth . " h" . dragHeight . " BackgroundTrans")
    dragArea.OnEvent("Click", (*)=> HandleOverlayMove(overlayData))
    
    ; 建立四個角落的調整大小控制點
    cornerSize := 15
    
    ; 左上角
    tlCorner := overlayGui.Add("Text", "x0 y0 w" . cornerSize . " h" . cornerSize . " BackgroundTrans")
    tlCorner.OnEvent("Click", (*)=> HandleOverlayResize(overlayData, "tl"))
    
    ; 右上角  
    trCorner := overlayGui.Add("Text", "x" . (width-cornerSize) . " y0 w" . cornerSize . " h" . cornerSize . " BackgroundTrans")
    trCorner.OnEvent("Click", (*)=> HandleOverlayResize(overlayData, "tr"))
    
    ; 左下角
    blCorner := overlayGui.Add("Text", "x0 y" . (height-cornerSize) . " w" . cornerSize . " h" . cornerSize . " BackgroundTrans")
    blCorner.OnEvent("Click", (*)=> HandleOverlayResize(overlayData, "bl"))
    
    ; 右下角
    brCorner := overlayGui.Add("Text", "x" . (width-cornerSize) . " y" . (height-cornerSize) . " w" . cornerSize . " h" . cornerSize . " BackgroundTrans")
    brCorner.OnEvent("Click", (*)=> HandleOverlayResize(overlayData, "br"))
    
    ; 繪製邊框和角落指示器
    CreateResizableBorderFrames(overlayGui, width, height)
    
    ; 添加說明文字
    if (description != "") {
        textX := Max(5, (width - StrLen(description) * 7) / 2)  
        textY := Max(5, height / 2 - 8)
        labelText := overlayGui.Add("Text", "x" . textX . " y" . textY . " cLime BackgroundTrans", description)
        labelText.SetFont("s9 Bold", "Microsoft JhengHei")
    }
    
    ; 顯示視窗
    overlayGui.Show("x" . area.x1 . " y" . area.y1 . " w" . width . " h" . height . " NoActivate")
    
    ; 設定透明度
    Sleep(50)
    try {
        WinSetTransparent(200, overlayGui.Hwnd)
    }
    
    ; 儲存到Map中
    overlayMap[name] := overlayData
}

; === 建立可調整大小的邊框 ===
CreateResizableBorderFrames(gui, width, height) {
    borderWidth := 3
    cornerSize := 15
    
    ; 邊框
    gui.Add("Progress", "x0 y0 w" . width . " h" . borderWidth . " cRed BackgroundRed", 100)  ; 上
    gui.Add("Progress", "x0 y" . (height-borderWidth) . " w" . width . " h" . borderWidth . " cRed BackgroundRed", 100)  ; 下
    gui.Add("Progress", "x0 y0 w" . borderWidth . " h" . height . " cRed BackgroundRed", 100)  ; 左
    gui.Add("Progress", "x" . (width-borderWidth) . " y0 w" . borderWidth . " h" . height . " cRed BackgroundRed", 100)  ; 右
    
    ; 角落調整大小指示器 (更明顯的顏色)
    gui.Add("Progress", "x0 y0 w" . cornerSize . " h" . cornerSize . " cYellow BackgroundYellow", 100)  ; 左上
    gui.Add("Progress", "x" . (width-cornerSize) . " y0 w" . cornerSize . " h" . cornerSize . " cYellow BackgroundYellow", 100)  ; 右上
    gui.Add("Progress", "x0 y" . (height-cornerSize) . " w" . cornerSize . " h" . cornerSize . " cYellow BackgroundYellow", 100)  ; 左下
    gui.Add("Progress", "x" . (width-cornerSize) . " y" . (height-cornerSize) . " w" . cornerSize . " h" . cornerSize . " cYellow BackgroundYellow", 100)  ; 右下
    
    ; 角落拖拽提示符號
    gui.Add("Text", "x2 y2 w11 h11 Center cBlack BackgroundTrans", "↖")
    gui.Add("Text", "x" . (width-13) . " y2 w11 h11 Center cBlack BackgroundTrans", "↗")
    gui.Add("Text", "x2 y" . (height-13) . " w11 h11 Center cBlack BackgroundTrans", "↙")
    gui.Add("Text", "x" . (width-13) . " y" . (height-13) . " w11 h11 Center cBlack BackgroundTrans", "↘")
}

; === 處理Overlay移動 ===
HandleOverlayMove(overlayData) {
    global isDraggingAny, currentDragOverlay, dragMode
    
    if (isDraggingAny) {
        return
    }
    
    StartDragOperation(overlayData, "move")
}

; === 處理Overlay調整大小 ===
HandleOverlayResize(overlayData, corner) {
    global isDraggingAny, currentDragOverlay, dragMode, resizeCorner
    
    if (isDraggingAny) {
        return
    }
    
    resizeCorner := corner
    StartDragOperation(overlayData, "resize")
}

; === 開始拖拽操作 ===
StartDragOperation(overlayData, mode) {
    global isDraggingAny, currentDragOverlay, dragMode
    global lastSmoothX, lastSmoothY, targetX, targetY
    global lastSmoothWidth, lastSmoothHeight, targetWidth, targetHeight
    
    isDraggingAny := true
    currentDragOverlay := overlayData
    dragMode := mode
    overlayData.isDragging := true
    
    ; 重置平滑拖拽變數
    lastSmoothX := 0
    lastSmoothY := 0
    targetX := 0
    targetY := 0
    lastSmoothWidth := 0
    lastSmoothHeight := 0
    targetWidth := 0
    targetHeight := 0
    
    ; 重置overlay的平滑位置變數
    if (HasProp(overlayData, "lastSmoothPosX")) {
        overlayData.DeleteProp("lastSmoothPosX")
        overlayData.DeleteProp("lastSmoothPosY")
    }
    
    ; 記錄起始位置
    MouseGetPos(&mouseX, &mouseY)
    overlayData.gui.GetPos(&winX, &winY, &winW, &winH)
    
    overlayData.startMouseX := mouseX
    overlayData.startMouseY := mouseY
    overlayData.startWinX := winX
    overlayData.startWinY := winY
    overlayData.originalWidth := winW
    overlayData.originalHeight := winH
    
    ; 改變視覺反饋
    try {
        WinSetTransparent(150, overlayData.gui.Hwnd)
    }
    
    modeText := (mode = "move") ? GetText("tooltip_move") : GetText("tooltip_resize")
    ShowTooltip(StrReplace(modeText, "{desc}", overlayData.description), 2000)
    
    ; 註冊更新循環和結束事件
    SetTimer(DragUpdateLoop, 33)  ; 約30FPS，減少抖動
    Hotkey("~LButton", EndDrag, "On")
    Hotkey("~RButton", EndDrag, "On")
}

; === 拖拽更新循環 (平滑版本) ===
DragUpdateLoop() {
    global isDraggingAny, currentDragOverlay, dragMode, resizeCorner
    global lastSmoothX, lastSmoothY, targetX, targetY, smoothingFactor
    
    if (!isDraggingAny || !currentDragOverlay || !currentDragOverlay.isDragging) {
        SetTimer(DragUpdateLoop, 0)
        return
    }
    
    MouseGetPos(&currentMouseX, &currentMouseY)
    
    if (dragMode = "move") {
        ; 移動模式 - 使用平滑插值
        offsetX := currentMouseX - currentDragOverlay.startMouseX
        offsetY := currentMouseY - currentDragOverlay.startMouseY
        
        ; 計算目標位置
        targetX := currentDragOverlay.startWinX + offsetX
        targetY := currentDragOverlay.startWinY + offsetY
        
        ; 邊界檢查
        targetX := Max(0, Min(targetX, A_ScreenWidth - currentDragOverlay.originalWidth))
        targetY := Max(0, Min(targetY, A_ScreenHeight - currentDragOverlay.originalHeight))
        
        ; 初始化平滑位置
        if (lastSmoothX = 0 && lastSmoothY = 0) {
            lastSmoothX := targetX
            lastSmoothY := targetY
        }
        
        ; 平滑插值計算
        smoothX := lastSmoothX + (targetX - lastSmoothX) * smoothingFactor
        smoothY := lastSmoothY + (targetY - lastSmoothY) * smoothingFactor
        
        ; 只有當移動距離超過1像素時才更新，避免微小抖動
        if (Abs(smoothX - lastSmoothX) > 0.5 || Abs(smoothY - lastSmoothY) > 0.5) {
            try {
                currentDragOverlay.gui.Move(Round(smoothX), Round(smoothY))
                lastSmoothX := smoothX
                lastSmoothY := smoothY
            } catch {
                EndDrag()
            }
        }
        
    } else if (dragMode = "resize") {
        ; 調整大小模式 - 使用平滑插值
        global lastSmoothWidth, lastSmoothHeight, targetWidth, targetHeight, resizeSmoothingFactor
        
        offsetX := currentMouseX - currentDragOverlay.startMouseX
        offsetY := currentMouseY - currentDragOverlay.startMouseY
        
        ; 計算目標座標和大小
        targetNewX := currentDragOverlay.startWinX
        targetNewY := currentDragOverlay.startWinY
        targetWidth := currentDragOverlay.originalWidth
        targetHeight := currentDragOverlay.originalHeight
        
        ; 根據角落調整座標和大小
        switch resizeCorner {
            case "tl":  ; 左上角
                targetNewX := currentDragOverlay.startWinX + offsetX
                targetNewY := currentDragOverlay.startWinY + offsetY
                targetWidth := currentDragOverlay.originalWidth - offsetX
                targetHeight := currentDragOverlay.originalHeight - offsetY
                
            case "tr":  ; 右上角
                targetNewX := currentDragOverlay.startWinX  ; X位置保持不變
                targetNewY := currentDragOverlay.startWinY + offsetY
                targetWidth := currentDragOverlay.originalWidth + offsetX
                targetHeight := currentDragOverlay.originalHeight - offsetY
                
            case "bl":  ; 左下角
                targetNewX := currentDragOverlay.startWinX + offsetX
                targetNewY := currentDragOverlay.startWinY  ; Y位置保持不變
                targetWidth := currentDragOverlay.originalWidth - offsetX
                targetHeight := currentDragOverlay.originalHeight + offsetY
                
            case "br":  ; 右下角
                targetNewX := currentDragOverlay.startWinX  ; X位置保持不變
                targetNewY := currentDragOverlay.startWinY  ; Y位置保持不變
                targetWidth := currentDragOverlay.originalWidth + offsetX
                targetHeight := currentDragOverlay.originalHeight + offsetY
        }
        
        ; 最小尺寸限制
        minWidth := 50
        minHeight := 30
        targetWidth := Max(minWidth, targetWidth)
        targetHeight := Max(minHeight, targetHeight)
        
        ; 邊界檢查
        targetNewX := Max(0, Min(targetNewX, A_ScreenWidth - targetWidth))
        targetNewY := Max(0, Min(targetNewY, A_ScreenHeight - targetHeight))
        
        ; 初始化平滑大小
        if (lastSmoothWidth = 0 && lastSmoothHeight = 0) {
            lastSmoothWidth := targetWidth
            lastSmoothHeight := targetHeight
        }
        
        ; 平滑插值計算
        smoothWidth := lastSmoothWidth + (targetWidth - lastSmoothWidth) * resizeSmoothingFactor
        smoothHeight := lastSmoothHeight + (targetHeight - lastSmoothHeight) * resizeSmoothingFactor
        
        ; 對於位置也需要平滑插值（除了左上角）
        if (resizeCorner != "tl") {
            ; 初始化平滑位置
            if (!HasProp(currentDragOverlay, "lastSmoothPosX")) {
                currentDragOverlay.lastSmoothPosX := targetNewX
                currentDragOverlay.lastSmoothPosY := targetNewY
            }
            
            smoothPosX := currentDragOverlay.lastSmoothPosX + (targetNewX - currentDragOverlay.lastSmoothPosX) * resizeSmoothingFactor
            smoothPosY := currentDragOverlay.lastSmoothPosY + (targetNewY - currentDragOverlay.lastSmoothPosY) * resizeSmoothingFactor
            
            currentDragOverlay.lastSmoothPosX := smoothPosX
            currentDragOverlay.lastSmoothPosY := smoothPosY
            
            finalX := Round(smoothPosX)
            finalY := Round(smoothPosY)
        } else {
            ; 左上角直接使用目標位置
            finalX := targetNewX
            finalY := targetNewY
        }
        
        ; 只有當變化超過1像素時才更新，避免微小抖動
        if (Abs(smoothWidth - lastSmoothWidth) > 0.5 || Abs(smoothHeight - lastSmoothHeight) > 0.5) {
            try {
                currentDragOverlay.gui.Move(finalX, finalY, Round(smoothWidth), Round(smoothHeight))
                currentDragOverlay.width := Round(smoothWidth)
                currentDragOverlay.height := Round(smoothHeight)
                lastSmoothWidth := smoothWidth
                lastSmoothHeight := smoothHeight
            } catch {
                EndDrag()
            }
        }
    }
}

; === 結束拖拽 ===
EndDrag(*) {
    global isDraggingAny, currentDragOverlay, dragMode
    global lastSmoothX, lastSmoothY, targetX, targetY
    global lastSmoothWidth, lastSmoothHeight, targetWidth, targetHeight
    
    if (!isDraggingAny || !currentDragOverlay) {
        return
    }
    
    ; 停止更新循環
    SetTimer(DragUpdateLoop, 0)
    
    ; 獲取最終位置和大小並更新座標
    try {
        currentDragOverlay.gui.GetPos(&finalX, &finalY, &finalW, &finalH)
        
        if (dragMode = "resize") {
            ; 更新偵測區域座標，但不重建overlay以避免延遲
            UpdateDetectionAreaWithSize(currentDragOverlay, finalX, finalY, finalW, finalH)
            
            ; 直接更新overlay的內部控制項位置和大小
            ; 傳遞正確的當前位置和大小
            UpdateOverlayControls(currentDragOverlay, finalW, finalH)
        } else {
            ; 只是移動位置
            UpdateDetectionArea(currentDragOverlay, finalX, finalY)
        }
        
        ; 儲存設定
        SaveSettings()
        
        ; 恢復透明度
        WinSetTransparent(200, currentDragOverlay.gui.Hwnd)
        
        modeText := (dragMode = "move") ? GetText("tooltip_position_updated") : GetText("tooltip_size_updated")
        ShowTooltip(StrReplace(modeText, "{desc}", currentDragOverlay.description), 2000)
    }
    
    ; 清除拖拽狀態
    currentDragOverlay.isDragging := false
    isDraggingAny := false
    currentDragOverlay := ""
    dragMode := ""
    
    ; 重置平滑拖拽變數
    lastSmoothX := 0
    lastSmoothY := 0
    targetX := 0
    targetY := 0
    lastSmoothWidth := 0
    lastSmoothHeight := 0
    targetWidth := 0
    targetHeight := 0
    
    ; 移除熱鍵
    try {
        Hotkey("~LButton", EndDrag, "Off")
        Hotkey("~RButton", EndDrag, "Off")
    }
}

; === 更新Overlay控制項 (調整大小後) ===
UpdateOverlayControls(overlayData, newWidth, newHeight) {
    ; 更新overlay數據中的尺寸
    overlayData.width := newWidth
    overlayData.height := newHeight
    overlayData.originalWidth := newWidth
    overlayData.originalHeight := newHeight
    
    ; 更新拖拽區域大小
    centerMargin := 15
    try {
        gui := overlayData.gui
        borderWidth := 3
        cornerSize := 15
        
        ; 邊框 Progress1-4
        ControlMove("Progress1", 0, 0, newWidth, borderWidth, gui.Hwnd)
        ControlMove("Progress2", 0, newHeight-borderWidth, newWidth, borderWidth, gui.Hwnd)
        ControlMove("Progress3", 0, 0, borderWidth, newHeight, gui.Hwnd)
        ControlMove("Progress4", newWidth-borderWidth, 0, borderWidth, newHeight, gui.Hwnd)
        
        ; 角落指示器 Progress5-8
        ControlMove("Progress5", 0, 0, cornerSize, cornerSize, gui.Hwnd)
        ControlMove("Progress6", newWidth-cornerSize, 0, cornerSize, cornerSize, gui.Hwnd)
        ControlMove("Progress7", 0, newHeight-cornerSize, cornerSize, cornerSize, gui.Hwnd)
        ControlMove("Progress8", newWidth-cornerSize, newHeight-cornerSize, cornerSize, cornerSize, gui.Hwnd)
        
        ; 四角點擊區域 Static2-5 (tl/tr/bl/brCorner)
        ControlMove("Static2", 0, 0, cornerSize, cornerSize, gui.Hwnd)
        ControlMove("Static3", newWidth-cornerSize, 0, cornerSize, cornerSize, gui.Hwnd)
        ControlMove("Static4", 0, newHeight-cornerSize, cornerSize, cornerSize, gui.Hwnd)
        ControlMove("Static5", newWidth-cornerSize, newHeight-cornerSize, cornerSize, cornerSize, gui.Hwnd)
        
        ; 角落箭頭文字 Static6-9 (↖↗↙↘)
        ControlMove("Static6", 2, 2, 11, 11, gui.Hwnd)
        ControlMove("Static7", newWidth-13, 2, 11, 11, gui.Hwnd)
        ControlMove("Static8", 2, newHeight-13, 11, 11, gui.Hwnd)
        ControlMove("Static9", newWidth-13, newHeight-13, 11, 11, gui.Hwnd)
        
        ; 中央拖拽區域 Static1 (dragArea)
        minDragSize := 20
        centerMarginX := Min(15, Max(0, (newWidth - minDragSize) / 2))
        centerMarginY := Min(15, Max(0, (newHeight - minDragSize) / 2))
        dragWidth := Max(minDragSize, newWidth - centerMarginX * 2)
        dragHeight := Max(minDragSize, newHeight - centerMarginY * 2)
        ControlMove("Static1", centerMarginX, centerMarginY, dragWidth, dragHeight, gui.Hwnd)
        
        ; 說明文字 Static10 (labelText)
        if (overlayData.description != "") {
            textX := Max(5, (newWidth - StrLen(overlayData.description) * 7) / 2)
            textY := Max(5, newHeight / 2 - 8)
            ControlMove("Static10", textX, textY, 150, 20, gui.Hwnd)
        }
    } catch as err {
        ; 如果控制項更新失敗，回退到重建方法
        ; 獲取當前位置並正確傳遞
        try {
            currentX := 0
            currentY := 0
            overlayData.gui.GetPos(&currentX, &currentY)
            RebuildOverlay(overlayData, currentX, currentY, newWidth, newHeight)
        } catch {
            ; 如果連位置都獲取不到，使用原始位置
            RebuildOverlay(overlayData, overlayData.startWinX, overlayData.startWinY, newWidth, newHeight)
        }
    }
}

; === 重新建立Overlay (調整大小後) ===
RebuildOverlay(overlayData, newX, newY, newWidth, newHeight) {
    global overlayMap
    
    name := overlayData.name
    description := overlayData.description
    
    ; 銷毀舊的GUI
    try {
        overlayData.gui.Destroy()
    }
    
    ; 從Map中移除
    if (overlayMap.Has(name)) {
        overlayMap.Delete(name)
    }
    
    ; 建立新的area物件
    newArea := {x1: newX, y1: newY, x2: newX + newWidth, y2: newY + newHeight}
    
    ; 重新建立overlay
    CreateResizableOverlay(name, newArea, description)
}

; === 更新偵測區域座標 ===
UpdateDetectionArea(overlayData, newX, newY) {
    global leftBtn, rightBtn, rapidHit
    
    ; 計算新的偵測區域座標
    newX2 := newX + overlayData.width
    newY2 := newY + overlayData.height
    
    ; 根據overlay名稱更新對應的全域座標變數
    switch overlayData.name {
        case "Left":
            leftBtn.x1 := newX
            leftBtn.y1 := newY
            leftBtn.x2 := newX2
            leftBtn.y2 := newY2
            
        case "Right":
            rightBtn.x1 := newX
            rightBtn.y1 := newY
            rightBtn.x2 := newX2
            rightBtn.y2 := newY2
            
        case "Rapid":
            rapidHit.x1 := newX
            rapidHit.y1 := newY
            rapidHit.x2 := newX2
            rapidHit.y2 := newY2
    }
}

; === 更新偵測區域座標(含大小) ===
UpdateDetectionAreaWithSize(overlayData, newX, newY, newWidth, newHeight) {
    global leftBtn, rightBtn, rapidHit
    
    ; 計算新的偵測區域座標
    newX2 := newX + newWidth
    newY2 := newY + newHeight
    
    ; 根據overlay名稱更新對應的全域座標變數
    switch overlayData.name {
        case "Left":
            leftBtn.x1 := newX
            leftBtn.y1 := newY
            leftBtn.x2 := newX2
            leftBtn.y2 := newY2
            
        case "Right":
            rightBtn.x1 := newX
            rightBtn.y1 := newY
            rightBtn.x2 := newX2
            rightBtn.y2 := newY2
            
        case "Rapid":
            rapidHit.x1 := newX
            rapidHit.y1 := newY
            rapidHit.x2 := newX2
            rapidHit.y2 := newY2
    }
}

; === 銷毀所有紅框覆蓋 (改進清理) ===  
DestroyAllOverlays() {
    global overlayMap, isDraggingAny, currentDragOverlay
    
    ; 停止任何進行中的拖拽
    if (isDraggingAny) {
        SetTimer(DragUpdateLoop, 0)
        isDraggingAny := false
        currentDragOverlay := ""
        try {
            Hotkey("~LButton", EndDrag, "Off")
            Hotkey("~RButton", EndDrag, "Off")
        }
    }
    
    ; 安全遍歷並銷毀所有overlay
    for name, overlayData in overlayMap.Clone() {
        try {
            if (Type(overlayData) = "Object" && overlayData.HasProp("gui")) {
                overlayData.gui.Destroy()
            }
        } catch {
            ; 忽略銷毀錯誤
        }
    }
    
    ; 清空Map容器
    overlayMap.Clear()
}

; === F4: 開關主循環 ===
F4::ToggleAutomation()

ToggleAutomation() {
    global loopRunning, loopActive
    
    loopRunning := !loopRunning
    
    ; 更新GUI狀態顯示
    UpdateVariation()
    
    if (loopRunning) {
        ShowTooltip(GetText("tooltip_automation_start"), 2000)
        
        ; 避免重複啟動多個循環實例
        if (!loopActive) {
            loopActive := true
            ; 使用SetTimer異步啟動主循環，避免阻塞GUI
            SetTimer(StartMainLoop, -50)
        }
    } else {
        ShowTooltip(GetText("tooltip_automation_stop"), 1500)
        ; 確保所有按鍵都釋放
        ReleaseAllKeys()
    }
}

; === F12: 改進的安全退出處理 ===
F12::SafeExit()

SafeExit() {
    static exiting := false
    if exiting
        return
    exiting := true
    
    global overlayMap, mainGui, loopRunning, isDraggingAny
    
    try {
        ; 停止所有自動化操作
        loopRunning := false
        
        ; 停止拖拽操作
        if (isDraggingAny) {
            SetTimer(DragUpdateLoop, 0)
            isDraggingAny := false
            try {
                Hotkey("~LButton", EndDrag, "Off")
                Hotkey("~RButton", EndDrag, "Off")
            }
        }
        
        ; 釋放所有按鍵
        ReleaseAllKeys()
        
        ; 清理所有覆蓋視窗
        DestroyAllOverlays()
        
        ; 最後儲存設定
        SaveSettings()
        
        ; 銷毀主GUI
        if (mainGui && Type(mainGui) = "Gui") {
            try {
                mainGui.Destroy()
            }
        }
        
        ; 清理定時器
        SetTimer(DragUpdateLoop, 0)
        SetTimer(StartMainLoop, 0)
        
        ; 友好的退出提示
        ShowTooltip(GetText("tooltip_exit"), 2000)
        
        ; 延遲退出以顯示提示
        SetTimer(() => ExitApp(), -2500)
        
    } catch as err {
        ; 如果正常退出失敗，強制退出
        try {
            MsgBox("退出過程中發生錯誤: " . err.Message . "`n將強制關閉程式", "退出錯誤", "OK Icon48 T3")
        }
        ExitApp()
    }
}

; === 主要遊戲邏輯循環 ===  
StartMainLoop() {
    global loopRunning, loopActive, leftBtn, rightBtn, rapidHit, colorVariation
    global foundX, foundY, COLOR_BLUE, COLOR_PINK, COLOR_GREEN, COLOR_BLACK
    
    ; 設定像素座標模式為螢幕絕對座標
    CoordMode("Pixel", "Screen")
    
    ; 主循環執行
    while (loopRunning) {
        try {
            ; === 優先順序1: 連擊模式 (最高優先級) ===
            if (PixelSearch(&foundX, &foundY, rapidHit.x1, rapidHit.y1, rapidHit.x2, rapidHit.y2, COLOR_BLACK, colorVariation)) {
                ExecuteRapidHit()
                continue
            }
            
            ; === 優先順序2: 長按模式 ===
            ; 左側粉色長按
            if (PixelSearch(&foundX, &foundY, leftBtn.x1, leftBtn.y1, leftBtn.x2, leftBtn.y2, COLOR_PINK, colorVariation)) {
                ExecuteLongPress("left")
                Sleep(10)
                continue
            }
            
            ; 右側粉色長按
            if (PixelSearch(&foundX, &foundY, rightBtn.x1, rightBtn.y1, rightBtn.x2, rightBtn.y2, COLOR_PINK, colorVariation)) {
                ExecuteLongPress("right")
                Sleep(10)
                continue
            }
            
            ; === 優先順序3: 單擊模式 ===
            ; 左側藍色單擊
            if (PixelSearch(&foundX, &foundY, leftBtn.x1, leftBtn.y1, leftBtn.x2, leftBtn.y2, COLOR_BLUE, colorVariation)) {
                ExecuteSingleTap("left")
                Sleep(8)
                continue
            }
            
            ; 右側藍色單擊
            if (PixelSearch(&foundX, &foundY, rightBtn.x1, rightBtn.y1, rightBtn.x2, rightBtn.y2, COLOR_BLUE, colorVariation)) {
                ExecuteSingleTap("right")
                Sleep(8)
                continue
            }
            
            ; === 優先順序4: 持續按住模式 ===
            ; 左側綠色持續
            if (PixelSearch(&foundX, &foundY, leftBtn.x1, leftBtn.y1, leftBtn.x2, leftBtn.y2, COLOR_GREEN, colorVariation)) {
                ExecuteHoldPress("left")
                continue
            }
            
            ; 右側綠色持續
            if (PixelSearch(&foundX, &foundY, rightBtn.x1, rightBtn.y1, rightBtn.x2, rightBtn.y2, COLOR_GREEN, colorVariation)) {
                ExecuteHoldPress("right")
                continue
            }
            
        } catch as err {
            errorMsg := A_Now . " | PixelSearch錯誤: " . err.Message
            try {
                FileAppend(errorMsg . "`n", A_ScriptDir . "\error.log")
            }
            Sleep(100)
        }
        
        ; 循環間隔，降低CPU使用率
        Sleep(6)
    }
    
    ; 循環結束清理工作
    ReleaseAllKeys()
    loopActive := false
}

; === 單擊操作處理 ===
ExecuteSingleTap(side) {
    ; 先確保所有按鍵都釋放
    SendInput("{z up}{/ up}")
    
    if (side = "left") {
        ; 左側按鈕: 按Z鍵
        SendInput("z")
    } else if (side = "right") {
        ; 右側按鈕: 按/鍵
        SendInput("/")
    }
}

; === 長按操作處理 ===
ExecuteLongPress(side) {
    global loopRunning
    
    ; 先釋放所有按鍵
    SendInput("{z up}{/ up}{x up}{. up}")
    
    if (side = "left") {
        ; 左側長按序列: Z + X
        SendInput("{z down}")
        Sleep(25)
        if (!loopRunning) {
            ReleaseAllKeys()
            return
        }
        
        SendInput("{x down}")  
        Sleep(25)
        if (!loopRunning) {
            ReleaseAllKeys()
            return
        }
        
        SendInput("{z up}{x up}")
        
    } else if (side = "right") {
        ; 右側長按序列: / + .
        SendInput("{/ down}")
        Sleep(25)
        if (!loopRunning) {
            ReleaseAllKeys()
            return
        }
        
        SendInput("{. down}")
        Sleep(25)  
        if (!loopRunning) {
            ReleaseAllKeys()
            return
        }
        
        SendInput("{/ up}{. up}")
    }
}

; === 持續按住處理 ===
ExecuteHoldPress(side) {
    ; 先釋放對方按鍵
    SendInput("{z up}{/ up}")
    
    if (side = "left") {
        ; 左側綠色: 持續按住Z鍵
        SendInput("{z down}")
    } else if (side = "right") {
        ; 右側綠色: 持續按住/鍵  
        SendInput("{/ down}")
    }
}

; === 連擊序列處理 ===
ExecuteRapidHit() {
    global loopRunning, rapidHit, colorVariation, foundX, foundY, COLOR_BLACK
    
    zPressed := false
    slashPressed := false
    hitCount := 0
    maxHits := 80
    
    ; 開始連擊循環
    Loop maxHits {
        ; 檢查停止條件
        if (!loopRunning) {
            break
        }
        
        ; 檢查黑色連擊區域是否還存在
        if (!PixelSearch(&foundX, &foundY, rapidHit.x1, rapidHit.y1, rapidHit.x2, rapidHit.y2, COLOR_BLACK, colorVariation)) {
            break  
        }
        
        ; Z鍵交替按壓
        if (!zPressed) {
            SendInput("{z down}")
            zPressed := true
        } else {
            SendInput("{z up}")  
            zPressed := false
        }
        Sleep(10)
        
        ; /鍵交替按壓
        if (!slashPressed) {
            SendInput("{/ down}")
            slashPressed := true  
        } else {
            SendInput("{/ up}")
            slashPressed := false
        }
        Sleep(10)
        
        hitCount++
    }
    
    ; 確保連擊結束後所有按鍵都釋放
    SendInput("{z up}{/ up}")
}

; === 釋放所有按鍵 ===
ReleaseAllKeys() {
    try {
        SendInput("{z up}{/ up}{x up}{. up}")
    }
}

; === 顯示提示訊息 ===
ShowTooltip(message, duration := 2000) {
    try {
        CoordMode("ToolTip", "Screen")
        ToolTip(message, , , 1)
        SetTimer(_ClearTooltip, 0)
        SetTimer(_ClearTooltip, -duration)
    }
}

_ClearTooltip() {
    ToolTip(, , , 1)
}

; === 託盤圖示事件處理函數 ===
TrayIconHandler(wParam, lParam, msg, hwnd) {
    global mainGui
    
    ; 處理託盤圖示點擊事件
    switch lParam {
        case 0x202:  ; WM_LBUTTONUP - 左鍵點擊
            if (mainGui && Type(mainGui) = "Gui") {
                try {
                    mainGui.Show()
                    mainGui.Focus()
                }
            }
        case 0x205:  ; WM_RBUTTONUP - 右鍵點擊
            ShowTooltip("右鍵點擊託盤圖示`n左鍵點擊可恢復主視窗", 2000)
    }
}

; === 程式初始化 ===
try {
    ; 載入設定檔
    LoadSettings()
    
    ; 註冊託盤圖示事件處理器
    OnMessage(0x0404, TrayIconHandler)
    
    ; 建立主GUI介面
    CreateMainGUI()
    
    ; 程式啟動成功提示
    ShowTooltip(GetText("tooltip_startup"), 6000)
    
} catch as err {
    ; 初始化失敗處理
    MsgBox("程式初始化失敗:`n" . err.Message, "錯誤", "OK Icon16")
    ExitApp()

}
