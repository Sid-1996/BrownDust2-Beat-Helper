#Requires AutoHotkey v2.0
#SingleInstance Force

; @Purpose: 棕色塵埃2 
; @Author: Sid  
; @Version: 2.0
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
        
    } catch {
        ; 儲存失敗處理
        ShowTooltip("⚠️ 設定檔儲存失敗", 2000)
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
        CreateResizableOverlay("Left", leftBtn, "左側按鈕區域")
        CreateResizableOverlay("Right", rightBtn, "右側按鈕區域") 
        CreateResizableOverlay("Rapid", rapidHit, "連擊偵測區域")
    }
    
    ShowTooltip("🔄 座標已恢復為預設值 (1920×1080)`n💾 設定已儲存", 3000)
}

; === 建立主GUI介面 ===
CreateMainGUI() {
    global mainGui, colorVariation, variationSlider, variationText, statusBar
    
    ; 建立主視窗
    mainGui := Gui("+Resize -MaximizeBox", "棕色塵埃2 音遊手殘救星 v2.0")
    mainGui.OnEvent("Close", (*) => SafeExit())
    mainGui.OnEvent("Size", GuiResizeHandler)
    
    ; 設定現代化字體
    mainGui.SetFont("s10", "Microsoft JhengHei")
    
    ; === 標題區域 ===
    titleText := mainGui.Add("Text", "x20 y15 w460 Center cNavy", "🎮 棕色塵埃2 屁股達人 🎮")
    titleText.SetFont("s12 Bold")
    
    ; === 系統需求說明 ===
    mainGui.Add("GroupBox", "x20 y45 w460 h90", "系統需求")
    mainGui.Add("Text", "x30 y65 cBlue", "• 解析度: 1920×1080 全螢幕模式")
    mainGui.Add("Text", "x30 y85 cBlue", "• 遊戲難度: Normal 難度 × 1倍速")
    mainGui.Add("Text", "x30 y105 cBlue", "• 權限: 管理員權限 (已獲取)")
    
    ; === 控制說明區域 ===
    mainGui.Add("GroupBox", "x20 y145 w460 h150", "操作說明")
    mainGui.Add("Text", "x30 y165 cGreen", "F1 鍵: 恢復預設座標 (1920×1080)")
    mainGui.Add("Text", "x30 y185 cGreen", "F3 鍵: 顯示/隱藏偵測範圍紅框(可自訂調整)")
    mainGui.Add("Text", "x30 y205 cGreen", "F4 鍵: 開啟/關閉自動化功能") 
    mainGui.Add("Text", "x30 y225 cGreen", "F12 鍵: 安全退出腳本程式")
    mainGui.Add("Text", "x30 y245 cRed", "⚠️ 請先按F3確認偵測範圍正確")
    mainGui.Add("Text", "x30 y265 cPurple", "🔧 拖拽: 點擊中央移動 | 點擊角落調整大小")
    
    ; === 參數調整區域 ===
    mainGui.Add("GroupBox", "x20 y305 w460 h80", "參數調整")
    mainGui.Add("Text", "x30 y325 w120", "顏色容錯率:")
    variationSlider := mainGui.Add("Slider", "x150 y325 w200 h30 Range1-50 ToolTip", colorVariation)
    variationText := mainGui.Add("Text", "x360 y325 w60 Center Border", colorVariation)
    mainGui.Add("Text", "x30 y355 cGray", "數值越高越容易觸發 (建議: 10-25)")
    
    ; 設定滑桿事件處理
    variationSlider.OnEvent("Change", UpdateVariation)
    
    ; === 狀態顯示區域 ===  
    statusBar := mainGui.Add("StatusBar", "", "狀態: 就緒 | 顏色容錯率: " . colorVariation . " | 版本: v2.0 製作 by 考你媽台清交(Sid)")
    
    ; 顯示主視窗
    mainGui.Show("w500 h420")
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
    statusText := "狀態: " . (loopRunning ? "🟢 運行中" : "🔴 停止中") . " | 顏色容錯率: " . colorVariation . " | 版本: v2.0 製作 by 考你媽台清交(Sid)"
    statusBar.Text := statusText
}

; === F3: 顯示/隱藏偵測範圍 ===
F3::ToggleOverlay()

ToggleOverlay() {
    global showOverlay, leftBtn, rightBtn, rapidHit, overlayMap
    
    showOverlay := !showOverlay
    
    if (showOverlay) {
        CreateResizableOverlay("Left", leftBtn, "左側按鈕區域")
        CreateResizableOverlay("Right", rightBtn, "右側按鈕區域") 
        CreateResizableOverlay("Rapid", rapidHit, "連擊偵測區域")
        
        ShowTooltip("✅ 可調整大小紅框已顯示`n🖱️ 點擊中央拖拽移動位置`n📐 點擊角落調整範圍大小`n💾 所有變更自動儲存", 5000)
    } else {
        DestroyAllOverlays()
        SaveSettings()  ; 隱藏時儲存設定
        ShowTooltip("❌ 紅框已隱藏`n💾 設定已儲存至 INI 檔案", 2000)
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
    centerMargin := 15
    dragArea := overlayGui.Add("Text", "x" . centerMargin . " y" . centerMargin . " w" . (width - centerMargin*2) . " h" . (height - centerMargin*2) . " BackgroundTrans")
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
    
    isDraggingAny := true
    currentDragOverlay := overlayData
    dragMode := mode
    overlayData.isDragging := true
    
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
    
    modeText := (mode = "move") ? "移動位置" : "調整大小"
    ShowTooltip("🔄 " . modeText . ": " . overlayData.description . "`n" . ((mode = "move") ? "拖拽到目標位置" : "拖拽調整範圍大小") . "`n點擊任意處結束", 2000)
    
    ; 註冊更新循環和結束事件
    SetTimer(DragUpdateLoop, 16)  ; 約60FPS
    Hotkey("~LButton", EndDrag, "On")
    Hotkey("~RButton", EndDrag, "On")
}

; === 拖拽更新循環 ===
DragUpdateLoop() {
    global isDraggingAny, currentDragOverlay, dragMode, resizeCorner
    
    if (!isDraggingAny || !currentDragOverlay || !currentDragOverlay.isDragging) {
        SetTimer(DragUpdateLoop, 0)
        return
    }
    
    MouseGetPos(&currentMouseX, &currentMouseY)
    
    if (dragMode = "move") {
        ; 移動模式
        offsetX := currentMouseX - currentDragOverlay.startMouseX
        offsetY := currentMouseY - currentDragOverlay.startMouseY
        
        newX := currentDragOverlay.startWinX + offsetX
        newY := currentDragOverlay.startWinY + offsetY
        
        ; 邊界檢查
        newX := Max(0, Min(newX, A_ScreenWidth - currentDragOverlay.originalWidth))
        newY := Max(0, Min(newY, A_ScreenHeight - currentDragOverlay.originalHeight))
        
        try {
            currentDragOverlay.gui.Move(newX, newY)
        } catch {
            EndDrag()
        }
        
    } else if (dragMode = "resize") {
        ; 調整大小模式
        offsetX := currentMouseX - currentDragOverlay.startMouseX
        offsetY := currentMouseY - currentDragOverlay.startMouseY
        
        newX := currentDragOverlay.startWinX
        newY := currentDragOverlay.startWinY
        newWidth := currentDragOverlay.originalWidth
        newHeight := currentDragOverlay.originalHeight
        
        ; 根據角落調整座標和大小
        switch resizeCorner {
            case "tl":  ; 左上角
                newX := currentDragOverlay.startWinX + offsetX
                newY := currentDragOverlay.startWinY + offsetY
                newWidth := currentDragOverlay.originalWidth - offsetX
                newHeight := currentDragOverlay.originalHeight - offsetY
                
            case "tr":  ; 右上角
                newY := currentDragOverlay.startWinY + offsetY
                newWidth := currentDragOverlay.originalWidth + offsetX
                newHeight := currentDragOverlay.originalHeight - offsetY
                
            case "bl":  ; 左下角
                newX := currentDragOverlay.startWinX + offsetX
                newWidth := currentDragOverlay.originalWidth - offsetX
                newHeight := currentDragOverlay.originalHeight + offsetY
                
            case "br":  ; 右下角
                newWidth := currentDragOverlay.originalWidth + offsetX
                newHeight := currentDragOverlay.originalHeight + offsetY
        }
        
        ; 最小尺寸限制
        minWidth := 50
        minHeight := 30
        newWidth := Max(minWidth, newWidth)
        newHeight := Max(minHeight, newHeight)
        
        ; 邊界檢查
        newX := Max(0, Min(newX, A_ScreenWidth - newWidth))
        newY := Max(0, Min(newY, A_ScreenHeight - newHeight))
        
        try {
            currentDragOverlay.gui.Move(newX, newY, newWidth, newHeight)
            currentDragOverlay.width := newWidth
            currentDragOverlay.height := newHeight
        } catch {
            EndDrag()
        }
    }
}

; === 結束拖拽 ===
EndDrag(*) {
    global isDraggingAny, currentDragOverlay, dragMode
    
    if (!isDraggingAny || !currentDragOverlay) {
        return
    }
    
    ; 停止更新循環
    SetTimer(DragUpdateLoop, 0)
    
    ; 獲取最終位置和大小並更新座標
    try {
        currentDragOverlay.gui.GetPos(&finalX, &finalY, &finalW, &finalH)
        
        if (dragMode = "resize") {
            ; 調整大小時需要重新建立GUI以更新內部控制項
            UpdateDetectionAreaWithSize(currentDragOverlay, finalX, finalY, finalW, finalH)
            RebuildOverlay(currentDragOverlay, finalX, finalY, finalW, finalH)
        } else {
            ; 只是移動位置
            UpdateDetectionArea(currentDragOverlay, finalX, finalY)
        }
        
        ; 儲存設定
        SaveSettings()
        
        ; 恢復透明度
        WinSetTransparent(200, currentDragOverlay.gui.Hwnd)
        
        modeText := (dragMode = "move") ? "位置" : "大小"
        ShowTooltip("✅ " . currentDragOverlay.description . " " . modeText . "已更新`n💾 設定已儲存", 2000)
    }
    
    ; 清除拖拽狀態
    currentDragOverlay.isDragging := false
    isDraggingAny := false
    currentDragOverlay := ""
    dragMode := ""
    
    ; 移除熱鍵
    try {
        Hotkey("~LButton", EndDrag, "Off")
        Hotkey("~RButton", EndDrag, "Off")
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
        ShowTooltip("🚀 自動化已啟動！`n開始監控遊戲畫面", 2000)
        
        ; 避免重複啟動多個循環實例
        if (!loopActive) {
            loopActive := true
            ; 使用SetTimer異步啟動主循環，避免阻塞GUI
            SetTimer(StartMainLoop, -50)
        }
    } else {
        ShowTooltip("⏹️ 自動化已停止", 1500)
        ; 確保所有按鍵都釋放
        ReleaseAllKeys()
    }
}

; === F12: 改進的安全退出處理 ===
F12::SafeExit()

SafeExit() {
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
        ShowTooltip("👋 祝我身體健康、運氣爆棚!`n💾 所有設定已儲存", 2000)
        
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
            ; 錯誤處理: 記錄到剪貼簿
            errorMsg := "PixelSearch錯誤: " . err.Message . "`n時間: " . A_Now
            try {
                A_Clipboard := errorMsg
            }
            ; 短暫暫停後繼續
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
        ToolTip(message, , , 1)
        SetTimer(() => ToolTip(, , , 1), -duration)
    }
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
    ShowTooltip("🎉 棕色塵埃2音遊手殘救星已啟動！`n`n📋 使用步驟:`n1. 按F1恢復預設座標`n2. 按F3顯示偵測範圍`n3. 拖拽調整位置/大小`n4. 按F4開始自動化`n5. 按F12安全退出`n`n💾 設定自動儲存至: Brown_Dust2_Settings.ini", 6000)
    
} catch as err {
    ; 初始化失敗處理
    MsgBox("程式初始化失敗:`n" . err.Message, "錯誤", "OK Icon16")
    ExitApp()

}
