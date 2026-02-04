#Requires AutoHotkey v2.0
#SingleInstance Force
SetWorkingDir(A_ScriptDir)
SetTitleMatchMode("RegEx")
CoordMode("Mouse")
Persistent

APP_VERSION := 1.0
SETTINGS_DIR := A_ScriptDir . "/EzScreenshot.ini"

pToken := Gdip_Startup()

DS_ValidateDatastoreExists()

;##################################################################################### Hotkeys

<!LButton::Hotkey_Screenshot()
<!<+LButton::Hotkey_WindowScreenshot()
<!<^LButton::Hotkey_CaptureGIF()

HotIfWinActive("EzScreenshot_SS.*")
Hotkey("<^C", Hotkey_CopyScreenshot)
Hotkey("<^S", Hotkey_SaveScreenshot)
Hotkey("RButton", Hotkey_CloseScreenshot)

;##################################################################################### Hotkey Callback Functions

Hotkey_Screenshot()
{
	area := StartSelectArea("PIC", 5000)
	if !area
		return

	bitmap := Gdip_BitmapFromScreen(area)

	Gdip_SetBitmapToClipboard(bitmap)

	if DS_ReadDatastore("PIC_AutoSaveScreenshot")
		Gdip_SaveBitmapToFile(bitmap, DS_ReadDatastore("PIC_SaveLocation") . "/EzSS_" . A_Year . A_Mon . A_MDay . A_Hour . A_Min . A_Sec . A_Msec . ".png", 100)

	Gdip_DisposeImage(bitmap)
}

Hotkey_WindowScreenshot()
{
	area := StartSelectArea("PIC", 5000)
	if !area
		return

	bitmap := Gdip_BitmapFromScreen(area)

	Gdip_SetBitmapToClipboard(bitmap)

	if DS_ReadDatastore("PIC_AutoSaveScreenshot")
		Gdip_SaveBitmapToFile(bitmap, DS_ReadDatastore("PIC_SaveLocation") . "/EzSS_" . A_Year . A_Mon . A_MDay . A_Hour . A_Min . A_Sec . A_Msec . ".png", 100)

	splitArea := StrSplit(area, "|")
	
	resizable := DS_ReadDatastore("PIC_ScreenshotWindowResizable")

	displayGUI := Gui("-Caption +ToolWindow +Border -DPIScale " . (DS_ReadDatastore("PIC_TopMostScreenshot") ? "+" : "-") . "AlwaysOnTop " . (resizable ? "+" : "-") . "Resize " . (resizable ? "+MinSize50x50 +MaxSize" . splitArea[3] . "x" . splitArea[4] : ""))
	displayGUI.Title := "EzScreenshot_SS_" . resizable
	ctl_picture := displayGUI.Add("Picture", "x0 y0 w" . splitArea[3] . " h" . splitArea[4], "HBITMAP:" Gdip_CreateHBITMAPFromBitmap(bitmap))
	ctl_picture.OnEvent("Click", (*) => ( PostMessage(0xA1, 2,,, "A") ))
	displayGUI.Show("NoActivate NA x" . splitArea[1] - (resizable ? 8 : 1) . " y" . splitArea[2] - (resizable ? 8 : 1) . " w" . splitArea[3] . " h" . splitArea[4])

	Gdip_DisposeImage(bitmap)
}

Hotkey_CaptureGIF()
{
	area := StartSelectArea("GIF")
	if !area
		return
	
	premature_gif_cancel := false
	splitArea := StrSplit(area, "|")
	w := splitArea[3] + 4
	h := splitArea[4] + 4
	
	gifFPS := DS_ReadDatastore("GIF_FramesPerSeconds")
	gifDuration := DS_ReadDatastore("GIF_Duration")
	
	frameGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
	frameGUI.Title := "EzScreenshot_GIFFRAME"
	frameGUI.BackColor := "FF0000"
	frameGUI.Show("NoActivate NA x" . splitArea[1] - 2 . " y" . splitArea[2] - 2 . " w" . w . " h" . h)
	WinSetRegion("0-0 " . w . "-0 " . w . "-" . h . " 0-" . h . " 0-0 " . 2 . "-" . 2 . " " . w - 2 . "-" . 2 . " " . w - 2 . "-" . h - 2 . " " . 2 . "-" . h - 2 . " " . 2 . "-" . w, "EzScreenshot_GIFFRAME")

	infoGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20 -DPIScale")
	infoGUI.Title := "EzScreenshot_GIFFRAME_INFO"
	ctl_frame := infoGUI.Add("Text", "x2 y2 w80 h20 0x200 Center", "Frame: 0/0")
	ctl_time := infoGUI.Add("Text", "x84 y2 w80 h20 0x200 Center", "Time: 0/0s")
	infoGUI.Add("Button", "x166 y2 w80 h20", "Stop").OnEvent("Click", (*) => ( premature_gif_cancel := true ))
	infoGUI.Show("NoActivate NA w248 h24 x" . splitArea[1] - 2 . " y" . splitArea[2] - 2 + h)

	frames := []
	loop gifFPS * gifDuration {
		if premature_gif_cancel
			break

		startTime := A_TickCount

		ctl_frame.Value := "Frame: " . A_Index . "/" . gifFpS * gifDuration
		ctl_time.Value := "Time: " . Round(A_Index * (1 / gifFPS), 1) . "/" . gifDuration . "s"

		frames.Push(Gdip_BitmapFromScreen(area))

		Sleep((1000 / gifFPS) - Max(0, A_TickCount - startTime))
	}

	frameGUI.BackColor := "00FF00"
	
	SaveBitmapsAsGIF(frames, gifFPS)
	
	infoGUI.Destroy
	frameGUI.Destroy()

	premature_gif_cancel := false
}

Hotkey_CopyScreenshot(*)
{
	if !WinActive("EzScreenshot_SS.*")
		return

	title := WinGetTitle("A")
	resizable := Integer(SubStr(title, StrLen(WinGetTitle("A")), StrLen(WinGetTitle("A"))))

	x := y := w := h := 0
	WinGetPos(&x, &y, &w, &h, "A")

	bitmap := Gdip_BitmapFromScreen(x + (resizable ? 8 : 1) . "|" . y + (resizable ? 8 : 1) . "|" . w + (resizable ? -16 : -2) . "|" . h + (resizable ? -16 : -2))

	Gdip_SetBitmapToClipboard(bitmap)

	Gdip_DisposeImage(bitmap)
}

Hotkey_SaveScreenshot(*)
{
	if !WinActive("EzScreenshot_SS.*")
		return

	title := WinGetTitle("A")
	resizable := Integer(SubStr(title, StrLen(WinGetTitle("A")), StrLen(WinGetTitle("A"))))

	x := y := w := h := 0
	WinGetPos(&x, &y, &w, &h, "A")

	bitmap := Gdip_BitmapFromScreen(x + (resizable ? 8 : 1) . "|" . y + (resizable ? 8 : 1) . "|" . w + (resizable ? -16 : -2) . "|" . h + (resizable ? -16 : -2))

	Gdip_SaveBitmapToFile(bitmap, DS_ReadDatastore("PIC_SaveLocation") . "/EzSS_" . A_Year . A_Mon . A_MDay . A_Hour . A_Min . A_Sec . A_Msec . ".png", 100)

	Gdip_DisposeImage(bitmap)
}

Hotkey_CloseScreenshot(*)
{
	if !WinActive("EzScreenshot_SS.*")
		return

	if DS_ReadDatastore("PIC_ScreenshotClosePrompt") {
		if MsgBox("Are you sure you want to close the screenshot window?`n`nThis is irreversible.", "EzScreenshot v" . APP_VERSION . " - Close Prompt", 0x34) == "Yes"
			WinClose("A")
	} else
		WinClose("A")
}

;##################################################################################### Functions

CopyFileToClipboard(filePath) {
	RunWait('powershell.exe -WindowStyle Hidden -NoProfile -ExecutionPolicy Bypass "' . A_WorkingDir . '\copyToClipboard.ps1" "' . filePath . '"',, "Hide")
}

SaveBitmapsAsGIF(frames, fps)
{
	tempFolder := A_WorkingDir . "\temp_frames"
	DirCreate(tempFolder)

	tempFiles := []
	for index, bitmap in frames {
		tempFile := tempFolder . "\f" . index . ".png"
		
		Gdip_SaveBitmapToFile(bitmap, tempFile)
		
		tempFiles.push(".\temp_frames\f" . index . ".png")
	}
	
	outputGIF := '"' . DS_ReadDatastore("GIF_SaveLocation") . "/EzGIF_" . A_Year . A_Mon . A_MDay . A_Hour . A_Min . A_Sec . A_Msec . '.gif"'
	command := '"' . A_WorkingDir . '/magick.exe" -delay ' . 100 / fps
	for file in tempFiles
		command .= ' "' . file . '"'
	command .= " " . outputGIF

	RunWait(command,, "Hide")

	for file in tempFiles
		FileDelete(file)
	DirDelete(tempFolder, 1)

	for bitmap in frames
		Gdip_DisposeImage(bitmap)

	CopyFileToClipboard(SubStr(outputGIF, 2, StrLen(outputGIF) - 2))

	if DS_ReadDatastore("GIF_OpenPostGIF")
		RunWait(outputGIF)
}

StartSelectArea(mode:="PIC", max_size:=1000)
{
	startMouseX := startMouseY := 0
	MouseGetPos(&startMouseX, &startMouseY)

	visualizerGUI := Gui("+AlwaysOnTop -Resize -Caption +Border -DPIScale +ToolWindow +E0x20") ; E0x20 = CLICK_THORUGH_GUI
	visualizerGUI.Title := "EzScreenshot_VISUALIZER"
	visualizerGUI.BackColor := DS_ReadDatastore(mode . "_OverlayColor")
	visualizerGUI.Show("w-1000 y-1000 NoActivate NA")
	WinSetTransparent(Round(DS_ReadDatastore(mode . "_Transparency") * 255 / 100), "EzScreenshot_VISUALIZER")

	guideLines := DS_ReadDatastore(mode . "_GuideLines")
	if guideLines {
		xCrosshairGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
		xCrosshairGUI.BackColor := "ff0000"
		xCrosshairGUI.Show("NoActivate NA")

		yCrosshairGUI := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x20")
		yCrosshairGUI.BackColor := "ff0000"
		yCrosshairGUI.Show("NoActivate NA")
	}

	step := DS_ReadDatastore(mode . "_SizeStep")
	while GetKeyState("LButton", "P") {
		Sleep(5)

		currentMouseX := currentMouseY := 0
		MouseGetPos(&currentMouseX, &currentMouseY)

		if guideLines {
			xCrosshairGUI.Move(0, currentMouseY, A_ScreenWidth, 1)
			yCrosshairGUI.Move(currentMouseX, 0, 1, A_ScreenHeight)
		}

		w := Min(Ceil(Abs(startMouseX - currentMouseX) / step) * step, max_size)
		h := Min(Ceil(Abs(startMouseY - currentMouseY) / step) * step, max_size)
		x := (currentMouseX < startMouseX) ? startMouseX - w : startMouseX
		y := (currentMouseY < startMouseY) ? startMouseY - h : startMouseY

		ToolTip((w < 20 or h < 20) ? "Exit" : "w" . w . " h" . h)

		visualizerGUI.Move(x, y, w, h)
	}
	ToolTip()

	if guideLines {
		xCrosshairGUI.Destroy()
		yCrosshairGUI.Destroy()
	}

	if w < 20 or h < 20 {
		visualizerGUI.Destroy()
		return
	}

	delay := DS_ReadDatastore(mode . "_Delay")
	if delay > 0 {
		visualizerGUI.SetFont("s" . Round(Min(h, w) / 2))
		ctl_text := visualizerGUI.Add("Text", "Center 0x200 x0 y0 w" . w " h" h . " c" . InvertHEX(DS_ReadDatastore(mode . "_OverlayColor")))

		loop delay {
			ctl_text.Value := Round(delay - A_Index + 1)
			Sleep(1000)
		}
	}

	if mode == "PIC" and DS_ReadDatastore("PIC_ScreenshotFlashEffect") {
		visualizerGUI.BackColor := "FFFFFF"
		WinSetTransparent(255, "EzScreenshot_VISUALIZER")
		Sleep(10)
	}

	visualizerGUI.Destroy()

	return x . "|" . y . "|" . w . "|" . h
}

InvertHEX(hex) {
    hex := RegExReplace(hex, "^0x", "")
    num := "0x" . hex
    bitSize := StrLen(hex) * 4
    inverted := ~num & (2**bitSize - 1)
    return "0x" Format("{:X}", inverted)
}

;##################################################################################### Tray Menu

trayMenu := A_TrayMenu
trayMenu.Delete()
trayMenu.Add("Open Configuration Menu", (*) => ( configGUI.Show("w1055 h490") ))
trayMenu.Add("Suspend", (*) => (
	trayMenu.ToggleCheck("Suspend")
	Suspend()
))
trayMenu.Add("Reload", (*) => ( Reload() ))
trayMenu.Add()
trayMenu.Add("Exit - EzScreenshot v" . APP_VERSION, (*) => (
	Gdip_Shutdown(pToken)
	ExitApp()
))
trayMenu.Default := "Exit - EzScreenshot v" . APP_VERSION

;##################################################################################### Configuration GUI

configGUI := Gui("+AlwaysOnTop -Resize")
configGUI.Title := "EzScreenshot v" . APP_VERSION . " - Configuration"

configGUI.SetFont("s13")

configGUI.Add("GroupBox", "x5 y5 w520 h370", "IMG Configuration")
configGUI.Add("GroupBox", "x530 y5 w520 h370", "GIF Configuration")

configGUI.SetFont("s11")

configGUI.Add("Text", "x15 y30 w95 h30 0x200 Right", "Size Step:")
ctl_PIC_SizeStep := configGUI.Add("Slider", "x115 y30 w400 h30 Range1-100 Thick20 TickInterval5 Tooltip", DS_ReadDatastore("PIC_SizeStep"))
ctl_PIC_SizeStep.OnEvent("Change", (*) => ( DS_UpdateDatastore("PIC_SizeStep", ctl_PIC_SizeStep.Value) ))

configGUI.Add("Text", "x15 y65 w95 h30 0x200 Right", "Transparency:")
ctl_PIC_Transparency := configGUI.Add("Slider", "x115 y65 w400 h30 Range0-99 Thick20 TickInterval5 Tooltip", 100 - DS_ReadDatastore("PIC_Transparency"))
ctl_PIC_Transparency.OnEvent("Change", (*) => ( DS_UpdateDatastore("PIC_Transparency", 100 - ctl_PIC_Transparency.Value) ))

configGUI.Add("Text", "x15 y100 w95 h30 0x200 Right", "Delay (sec):")
ctl_PIC_Delay := configGUI.Add("Slider", "x115 y100 w400 h30 Range0-10 Thick20 TickInterval1 Tooltip", DS_ReadDatastore("PIC_Delay"))
ctl_PIC_Delay.OnEvent("Change", (*) => ( DS_UpdateDatastore("PIC_Delay", ctl_PIC_Delay.Value) ))

configGUI.Add("Text", "x6 y150 w522 0x10")

configGUI.Add("Text", "x15 y165 w95 h30 0x200 Right", "Overlay Color:")
ctl_PIC_OverlayColor_indicator := configGUI.Add("Text", "x115 y175 w300 h10 0x200 Border Background" . DS_ReadDatastore("PIC_OverlayColor"))
ctl_PIC_OverlayColor := configGUI.Add("Edit", "x420 y169 w95 h21 Limit6 Center", DS_ReadDatastore("PIC_OverlayColor"))
ctl_PIC_OverlayColor.OnEvent("Change", (*) => (
	RegExMatch(ctl_PIC_OverlayColor.Value, "^[0-9A-Fa-f]{6}$")
	? (ctl_PIC_OverlayColor_indicator.Opt("Background" . ctl_PIC_OverlayColor.Value)
		ctl_PIC_OverlayColor_indicator.Redraw()
		DS_UpdateDatastore("PIC_OverlayColor", ctl_PIC_OverlayColor.Value))
	: ""
))

configGUI.Add("Text", "x15 y200 w95 h30 0x200 Right", "Save Location:")
ctl_PIC_SaveLocation_indicator := configGUI.Add("Text", "x115 y200 w300 h30 0x200 Center", DS_ReadDatastore("PIC_SaveLocation"))
ctl_PIC_SaveLocation := configGUI.Add("Button", "x420 y200 w95 h30", "Change")
ctl_PIC_SaveLocation.OnEvent("click", ctl_PIC_SaveLocation_callback)
ctl_PIC_SaveLocation_callback(*)
{
	location := FileSelect("D", DS_ReadDatastore("PIC_SaveLocation"))

	if !DirExist(location)
		return

	ctl_PIC_SaveLocation_indicator.Value := location
	DS_UpdateDatastore("PIC_SaveLocation", location)
}

configGUI.Add("Text", "x6 y245 w522 0x10")

ctl_PIC_AutoSaveScreenshot := configGUI.Add("CheckBox", "x30 y260 w200 h30 0x8000 Checked" . DS_ReadDatastore("PIC_AutoSaveScreenshot"), "Auto Save Screenshot")
ctl_PIC_AutoSaveScreenshot.OnEvent("Click", (*) => ( DS_UpdateDatastore("PIC_AutoSaveScreenshot", ctl_PIC_AutoSaveScreenshot.Value) ))

ctl_PIC_ScreenshotClosePrompt := configGUI.Add("CheckBox", "x300 y260 w200 h30 0x8000 Checked" . DS_ReadDatastore("PIC_ScreenshotClosePrompt"), "Show Close Prompt")
ctl_PIC_ScreenshotClosePrompt.OnEvent("Click", (*) => ( DS_UpdateDatastore("PIC_ScreenshotClosePrompt", ctl_PIC_ScreenshotClosePrompt.Value) ))

ctl_PIC_TopMostScreenshot := configGUI.Add("CheckBox", "x30 y295 w200 h30 0x8000 Checked" . DS_ReadDatastore("PIC_TopMostScreenshot"), "TopMost Screenshot")
ctl_PIC_TopMostScreenshot.OnEvent("Click", (*) => ( DS_UpdateDatastore("PIC_TopMostScreenshot", ctl_PIC_TopMostScreenshot.Value) ))

ctl_PIC_ScreenshotWindowResizable := configGUI.Add("CheckBox", "x300 y295 w200 h30 0x8000 Checked" . DS_ReadDatastore("PIC_ScreenshotWindowResizable"), "Screenshot Window Resizable")
ctl_PIC_ScreenshotWindowResizable.OnEvent("Click", (*) => ( DS_UpdateDatastore("PIC_ScreenshotWindowResizable", ctl_PIC_ScreenshotWindowResizable.Value) ))

ctl_PIC_ScreenshotFlashEffect := configGUI.Add("CheckBox", "x30 y330 w200 h30 0x8000 Checked" . DS_ReadDatastore("PIC_ScreenshotFlashEffect"), "Enable Flash Effect")
ctl_PIC_ScreenshotFlashEffect.OnEvent("Click", (*) => ( DS_UpdateDatastore("PIC_ScreenshotFlashEffect", ctl_PIC_ScreenshotFlashEffect.Value) ))

ctl_PIC_GuideLines := configGUI.Add("CheckBox", "x300 y330 w200 h30 0x8000 Checked" . DS_ReadDatastore("PIC_GuideLines"), "Enable Guide Lines")
ctl_PIC_GuideLines.OnEvent("Click", (*) => ( DS_UpdateDatastore("PIC_GuideLines", ctl_PIC_GuideLines.Value) ))

configGUI.Add("Text", "x540 y30 w95 h30 0x200 Right", "Size Step:")
ctl_GIF_SizeStep := configGUI.Add("Slider", "x640 y30 w400 h30 Range1-100 Thick20 TickInterval5 Tooltip", DS_ReadDatastore("GIF_SizeStep"))
ctl_GIF_SizeStep.OnEvent("Change", (*) => ( DS_UpdateDatastore("GIF_SizeStep", ctl_GIF_SizeStep.Value) ))

configGUI.Add("Text", "x540 y65 w95 h30 0x200 Right", "Transparency:")
ctl_GIF_Transparency := configGUI.Add("Slider", "x640 y65 w400 h30 Range0-99 Thick20 TickInterval5 Tooltip", 100 - DS_ReadDatastore("GIF_Transparency"))
ctl_GIF_Transparency.OnEvent("Change", (*) => ( DS_UpdateDatastore("GIF_Transparency", 100 - ctl_GIF_Transparency.Value) ))

configGUI.Add("Text", "x540 y100 w95 h30 0x200 Right", "Delay (sec):")
ctl_GIF_Delay := configGUI.Add("Slider", "x640 y100 w400 h30 Range0-10 Thick20 TickInterval1 Tooltip", DS_ReadDatastore("GIF_Delay"))
ctl_GIF_Delay.OnEvent("Change", (*) => ( DS_UpdateDatastore("GIF_Delay", ctl_GIF_Delay.Value) ))

configGUI.Add("Text", "x540 y135 w95 h30 0x200 Right", "Capture FPS:")
ctl_GIF_FramesPerSeconds := configGUI.Add("Slider", "x640 y135 w400 h30 Range1-30 Thick20 TickInterval1 Tooltip", DS_ReadDatastore("GIF_FramesPerSeconds"))
ctl_GIF_FramesPerSeconds.OnEvent("Change", (*) => ( DS_UpdateDatastore("GIF_FramesPerSeconds", ctl_GIF_FramesPerSeconds.Value) ))

configGUI.Add("Text", "x540 y170 w95 h30 0x200 Right", "Duration (sec):")
ctl_GIF_Duration := configGUI.Add("Slider", "x640 y170 w400 h30 Range1-20 Thick20 TickInterval1 Tooltip", DS_ReadDatastore("GIF_Duration"))
ctl_GIF_Duration.OnEvent("Change", (*) => ( DS_UpdateDatastore("GIF_Duration", ctl_GIF_Duration.Value) ))

configGUI.Add("Text", "x531 y220 w522 0x10")

configGUI.Add("Text", "x540 y235 w95 h30 0x200 Right", "Overlay Color:")
ctl_GIF_OverlayColor_indicator := configGUI.Add("Text", "x640 y245 w300 h10 0x200 Border Background" . DS_ReadDatastore("GIF_OverlayColor"))
ctl_GIF_OverlayColor := configGUI.Add("Edit", "x945 y239 w95 h21 Limit6 Center", DS_ReadDatastore("GIF_OverlayColor"))
ctl_GIF_OverlayColor.OnEvent("Change", (*) => (
	RegExMatch(ctl_GIF_OverlayColor.Value, "^[0-9A-Fa-f]{6}$")
	? (ctl_GIF_OverlayColor_indicator.Opt("Background" . ctl_GIF_OverlayColor.Value)
		ctl_GIF_OverlayColor_indicator.Redraw()
		DS_UpdateDatastore("GIF_OverlayColor", ctl_GIF_OverlayColor.Value))
	: ""
))

configGUI.Add("Text", "x540 y270 w95 h30 0x200 Right", "Save Location:")
ctl_GIF_SaveLocation_indicator := configGUI.Add("Text", "x640 y270 w300 h30 0x200 Center", DS_ReadDatastore("GIF_SaveLocation"))
ctl_GIF_SaveLocation := configGUI.Add("Button", "x945 y270 w95 h30", "Change")
ctl_GIF_SaveLocation.OnEvent("click", ctl_GIF_SaveLocation_callback)
ctl_GIF_SaveLocation_callback(*)
{
	location := FileSelect("D", DS_ReadDatastore("PIC_SaveLocation"))

	if !DirExist(location)
		return
	
	ctl_GIF_SaveLocation_indicator.Value := location
	DS_UpdateDatastore("PIC_SaveLocation", location)
}

configGUI.Add("Text", "x531 y315 w522 0x10")

ctl_GIF_OpenPostGIF := configGUI.Add("CheckBox", "x555 y330 w200 h30 0x8000 Checked" . DS_ReadDatastore("GIF_OpenPostGIF"), "Open GIF After Capture")
ctl_GIF_OpenPostGIF.OnEvent("Click", (*) => ( DS_UpdateDatastore("GIF_OpenPostGIF", ctl_GIF_OpenPostGIF.Value) ))

ctl_GIF_GuideLines := configGUI.Add("CheckBox", "x855 y330 w200 h30 0x8000 Checked" . DS_ReadDatastore("GIF_GuideLines"), "Enable Guide Lines")
ctl_GIF_GuideLines.OnEvent("Click", (*) => ( DS_UpdateDatastore("GIF_GuideLines", ctl_GIF_GuideLines.Value) ))

configGUI.Add("Text", "x20 y380 w490 h30 0x200 Center", "Alt + Left Mouse Drag = Screenshot")
configGUI.Add("Text", "x20 y415 w490 h30 0x200 Center", "Alt + Shift + Left Mouse Drag = Screenshot + Window")
configGUI.Add("Text", "x20 y450 w490 h30 0x200 Center", "Alt + Ctrl + Left Mouse Drag = Start GIF Capture")

configGUI.Add("Text", "x545 y380 w490 h30 0x200 Center", "Ctrl + C = Copy Screenshot In Window")
configGUI.Add("Text", "x545 y415 w490 h30 0x200 Center", "Ctrl + S = Save Screenshot In Window")
configGUI.Add("Text", "x545 y450 w490 h30 0x200 Center", "Right Click = Close Screenshot Window")

;##################################################################################### Datastore functions

DS_ValidateDatastoreExists()
{
	if !FileExist(SETTINGS_DIR) {
		DS_UpdateDatastore("PIC_SizeStep", 1)
		DS_UpdateDatastore("PIC_Transparency", 15)
		DS_UpdateDatastore("PIC_Delay", 0)
		DS_UpdateDatastore("PIC_OverlayColor", "FFFFFF")
		DS_UpdateDatastore("PIC_SaveLocation", A_Desktop)
		DS_UpdateDatastore("PIC_AutoSaveScreenshot", 0)
		DS_UpdateDatastore("PIC_ScreenshotClosePrompt", 0)
		DS_UpdateDatastore("PIC_TopMostScreenshot", 1)
		DS_UpdateDatastore("PIC_ScreenshotWindowResizable", 0)
		DS_UpdateDatastore("PIC_ScreenshotFlashEffect", 1)
		DS_UpdateDatastore("PIC_GuideLines", 0)

		DS_UpdateDatastore("GIF_SizeStep", 1)
		DS_UpdateDatastore("GIF_Transparency", 15)
		DS_UpdateDatastore("GIF_Delay", 0)
		DS_UpdateDatastore("GIF_FramesPerSeconds", 5)
		DS_UpdateDatastore("GIF_Duration", 5)
		DS_UpdateDatastore("GIF_OverlayColor", "5555FF")
		DS_UpdateDatastore("GIF_SaveLocation", A_Desktop)
		DS_UpdateDatastore("GIF_OpenPostGIF", 1)
		DS_UpdateDatastore("GIF_GuideLines", 0)
	}
}

DS_ReadDatastore(key)
{
	return IniRead(SETTINGS_DIR, "Settings", key)
}

DS_UpdateDatastore(key, value)
{
	IniWrite(value, SETTINGS_DIR, "Settings", key)
}

;##################################################################################### GDI+ v1.62

UpdateLayeredWindow(hwnd, hdc, x:="", y:="", w:="", h:="", Alpha:=255)
{
	if ((x != "") && (y != "")) {
		pt := Buffer(8)
		NumPut("UInt", x, "UInt", y, pt)
	}

	if (w = "") || (h = "") {
		WinGetRect(hwnd,,, &w, &h)
	}

	return DllCall("UpdateLayeredWindow"
		, "UPtr", hwnd
		, "UPtr", 0
		, "UPtr", ((x = "") && (y = "")) ? 0 : pt.Ptr
		, "Int64*", w|h<<32
		, "UPtr", hdc
		, "Int64*", 0
		, "UInt", 0
		, "UInt*", Alpha<<16|1<<24
		, "UInt", 2)
}

BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, Raster:="")
{
	return DllCall("gdi32\BitBlt"
					, "UPtr", dDC
					, "Int", dx
					, "Int", dy
					, "Int", dw
					, "Int", dh
					, "UPtr", sDC
					, "Int", sx
					, "Int", sy
					, "UInt", Raster ? Raster : 0x00CC0020)
}

StretchBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, sw, sh, Raster:="")
{
	return DllCall("gdi32\StretchBlt"
					, "UPtr", ddc
					, "Int", dx
					, "Int", dy
					, "Int", dw
					, "Int", dh
					, "UPtr", sdc
					, "Int", sx
					, "Int", sy
					, "Int", sw
					, "Int", sh
					, "UInt", Raster ? Raster : 0x00CC0020)
}

SetStretchBltMode(hdc, iStretchMode:=4)
{
	return DllCall("gdi32\SetStretchBltMode"
					, "UPtr", hdc
					, "Int", iStretchMode)
}

SetImage(hwnd, hBitmap)
{
	_E := DllCall( "SendMessage", "UPtr", hwnd, "UInt", 0x172, "UInt", 0x0, "UPtr", hBitmap )
	DeleteObject(_E)
	return _E
}

SetSysColorToControl(hwnd, SysColor:=15)
{
	WinGetRect(hwnd,,, &w, &h)
	bc := DllCall("GetSysColor", "Int", SysColor, "UInt")
	pBrushClear := Gdip_BrushCreateSolid(0xff000000 | (bc >> 16 | bc & 0xff00 | (bc & 0xff) << 16))
	pBitmap := Gdip_CreateBitmap(w, h), G := Gdip_GraphicsFromImage(pBitmap)
	Gdip_FillRectangle(G, pBrushClear, 0, 0, w, h)
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	SetImage(hwnd, hBitmap)
	Gdip_DeleteBrush(pBrushClear)
	Gdip_DeleteGraphics(G), Gdip_DisposeImage(pBitmap), DeleteObject(hBitmap)
	return 0
}

Gdip_BitmapFromScreen(Screen:=0, Raster:="")
{
	hhdc := 0
	if (Screen = 0) {
		_x := DllCall( "GetSystemMetrics", "Int", 76 )
		_y := DllCall( "GetSystemMetrics", "Int", 77 )
		_w := DllCall( "GetSystemMetrics", "Int", 78 )
		_h := DllCall( "GetSystemMetrics", "Int", 79 )
	}
	else if (SubStr(Screen, 1, 5) = "hwnd:") {
		Screen := SubStr(Screen, 6)
		if !WinExist("ahk_id " Screen) {
			return -2
		}
		WinGetRect(Screen,,, &_w, &_h)
		_x := _y := 0
		hhdc := GetDCEx(Screen, 3)
	}
	else if IsInteger(Screen) {
		M := GetMonitorInfo(Screen)
		_x := M.Left, _y := M.Top, _w := M.Right-M.Left, _h := M.Bottom-M.Top
	}
	else {
		S := StrSplit(Screen, "|")
		_x := S[1], _y := S[2], _w := S[3], _h := S[4]
	}

	if (_x = "") || (_y = "") || (_w = "") || (_h = "") {
		return -1
	}

	chdc := CreateCompatibleDC()
	hbm := CreateDIBSection(_w, _h, chdc)
	obm := SelectObject(chdc, hbm)
	hhdc := hhdc ? hhdc : GetDC()
	BitBlt(chdc, 0, 0, _w, _h, hhdc, _x, _y, Raster)
	ReleaseDC(hhdc)

	pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)

	SelectObject(chdc, obm)
	DeleteObject(hbm)
	DeleteDC(hhdc)
	DeleteDC(chdc)
	return pBitmap
}

Gdip_BitmapFromHWND(hwnd)
{
	WinGetRect(hwnd,,, &Width, &Height)
	hbm := CreateDIBSection(Width, Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
	PrintWindow(hwnd, hdc)
	pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
	SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
	return pBitmap
}

CreateRectF(&RectF, x, y, w, h)
{
	RectF := Buffer(16)
	NumPut(
		"Float", x, 
		"Float", y, 
		"Float", w, 
		"Float", h, 
		RectF)
}

CreateRect(&Rect, x, y, w, h)
{
	Rect := Buffer(16)
	NumPut("UInt", x, "UInt", y, "UInt", w, "UInt", h, Rect)
}

CreateSizeF(&SizeF, w, h)
{
	SizeF := Buffer(8)
	NumPut("Float", w, "Float", h, SizeF)
}

CreatePointF(&PointF, x, y)
{
	PointF := Buffer(8)
	NumPut("Float", x, "Float", y, PointF)
}

CreateDIBSection(w, h, hdc:="", bpp:=32, &ppvBits:=0)
{
	hdc2 := hdc ? hdc : GetDC()
	bi := Buffer(40, 0)

	NumPut("UInt", 40, "UInt", w, "UInt", h, "ushort", 1, "ushort", bpp, "UInt", 0, bi)

	hbm := DllCall("CreateDIBSection"
					, "UPtr", hdc2
					, "UPtr", bi.Ptr
					, "UInt", 0
					, "UPtr*", &ppvBits
					, "UPtr", 0
					, "UInt", 0, "UPtr")

	if (!hdc) {
		ReleaseDC(hdc2)
	}
	return hbm
}

PrintWindow(hwnd, hdc, Flags:=0)
{
	return DllCall("PrintWindow", "UPtr", hwnd, "UPtr", hdc, "UInt", Flags)
}

DestroyIcon(hIcon)
{
	return DllCall("DestroyIcon", "UPtr", hIcon)
}

GetIconDimensions(hIcon, &Width:=0, &Height:=0) {
	ICONINFO := Buffer(size := 16 + 2 * A_PtrSize, 0)

	if !DllCall("user32\GetIconInfo", "UPtr", hIcon, "UPtr", ICONINFO.Ptr) {
		return -1
	}

	hbmMask := NumGet(ICONINFO.Ptr, 16, "UPtr")
	hbmColor := NumGet(ICONINFO.Ptr, 16 + A_PtrSize, "UPtr")
	BITMAP := Buffer(size, 0)

	if DllCall("gdi32\GetObject", "UPtr", hbmColor, "Int", size, "UPtr", BITMAP.Ptr) {
		Width := NumGet(BITMAP.Ptr, 4, "Int")
		Height := NumGet(BITMAP.Ptr, 8, "Int")
	}

	if !DllCall("gdi32\DeleteObject", "UPtr", hbmMask) {
		return -2
	}

	if !DllCall("gdi32\DeleteObject", "UPtr", hbmColor) {
		return -3
	}

	return 0
}

PaintDesktop(hdc)
{
	return DllCall("PaintDesktop", "UPtr", hdc)
}

CreateCompatibleBitmap(hdc, w, h)
{
	return DllCall("gdi32\CreateCompatibleBitmap", "UPtr", hdc, "Int", w, "Int", h)
}

CreateCompatibleDC(hdc:=0)
{
	return DllCall("CreateCompatibleDC", "UPtr", hdc)
}

SelectObject(hdc, hgdiobj)
{
	return DllCall("SelectObject", "UPtr", hdc, "UPtr", hgdiobj)
}

DeleteObject(hObject)
{
	return DllCall("DeleteObject", "UPtr", hObject)
}

GetDC(hwnd:=0)
{
	return DllCall("GetDC", "UPtr", hwnd)
}

GetDCEx(hwnd, flags:=0, hrgnClip:=0)
{
	return DllCall("GetDCEx", "UPtr", hwnd, "UPtr", hrgnClip, "Int", flags)
}

ReleaseDC(hdc, hwnd:=0)
{
	return DllCall("ReleaseDC", "UPtr", hwnd, "UPtr", hdc)
}

DeleteDC(hdc)
{
	return DllCall("DeleteDC", "UPtr", hdc)
}

Gdip_LibraryVersion()
{
	return 1.45
}

Gdip_LibrarySubVersion()
{
	return 1.54
}

Gdip_BitmapFromBRA(BRAFromMemIn, File, Alternate := 0) {
	if (!BRAFromMemIn) {
		return -1
	}

	Headers := StrSplit(StrGet(BRAFromMemIn.Ptr, 256, "CP0"), "`n")
	Header := StrSplit(Headers[1], "|")
	HeaderLength := Header.Length

	if (HeaderLength != 4) || (Header[2] != "BRA!") {
		return -2
	}

	_Info := StrSplit(Headers[2], "|")
	_InfoLength := _Info.Length

	if (_InfoLength != 3) {
		return -3
	}

	OffsetTOC := StrPut(Headers[1], "CP0") + StrPut(Headers[2], "CP0") ;  + 2
	OffsetData := _Info[2]
	SearchIndex := Alternate ? 1 : 2
	TOC := StrGet(BRAFromMemIn.Ptr + OffsetTOC, OffsetData - OffsetTOC - 1, "CP0")
	RX1 := "mi`n)^"
	Offset := Size := 0

	if RegExMatch(TOC, RX1 . (Alternate ? File "\|.+?" : "\d+\|" . File) . "\|(\d+)\|(\d+)$", &FileInfo:="") {
		Offset := OffsetData + FileInfo[1]
		Size := FileInfo[2]
	}

	if (Size = 0) {
		return -4
	}

	hData := DllCall("GlobalAlloc", "UInt", 2, "UInt", Size, "UPtr")
	pData := DllCall("GlobalLock", "Ptr", hData, "UPtr")
	DllCall("RtlMoveMemory", "Ptr", pData, "Ptr", BRAFromMemIn.Ptr + Offset, "Ptr", Size)
	DllCall("GlobalUnlock", "Ptr", hData)
	DllCall("Ole32.dll\CreateStreamOnHGlobal", "Ptr", hData, "Int", 1, "Ptr*", &pStream:=0)
	DllCall("Gdiplus.dll\GdipCreateBitmapFromStream", "Ptr", pStream, "Ptr*", &pBitmap:=0)
	ObjRelease(pStream)

	return pBitmap
}

Gdip_BitmapFromBase64(&Base64)
{
	; calculate the length of the buffer needed
	if !(DllCall("crypt32\CryptStringToBinary", "UPtr", StrPtr(Base64), "UInt", 0, "UInt", 0x01, "UPtr", 0, "UInt*", &DecLen:=0, "UPtr", 0, "UPtr", 0)) {
		return -1
	}

	Dec := Buffer(DecLen, 0)

	; decode the Base64 encoded string
	if !(DllCall("crypt32\CryptStringToBinary", "UPtr", StrPtr(Base64), "UInt", 0, "UInt", 0x01, "UPtr", Dec.Ptr, "UInt*", &DecLen, "UPtr", 0, "UPtr", 0)) {
		return -2
	}

	; create a memory stream
	if !(pStream := DllCall("shlwapi\SHCreateMemStream", "UPtr", Dec.Ptr, "UInt", DecLen, "UPtr")) {
		return -3
	}

	DllCall("gdiplus\GdipCreateBitmapFromStreamICM", "UPtr", pStream, "Ptr*", &pBitmap:=0)
	ObjRelease(pStream)

	return pBitmap
}

Gdip_EncodeBitmapTo64string(pBitmap, extension := "png", quality := "") {

    ; Fill a buffer with the available image codec info.
    DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", &count:=0, "uint*", &size:=0)
    DllCall("gdiplus\GdipGetImageEncoders", "uint", count, "uint", size, "ptr", ci := Buffer(size))

    ; struct ImageCodecInfo - http://www.jose.it-berater.org/gdiplus/reference/structures/imagecodecinfo.htm
    loop {
        if (A_Index > count)
        throw Error("Could not find a matching encoder for the specified file format.")

        idx := (48+7*A_PtrSize)*(A_Index-1)
    } until InStr(StrGet(NumGet(ci, idx+32+3*A_PtrSize, "ptr"), "UTF-16"), extension) ; FilenameExtension

    ; Get the pointer to the clsid of the matching encoder.
    pCodec := ci.ptr + idx ; ClassID

    ; JPEG default quality is 75. Otherwise set a quality value from [0-100].
    if (quality ~= "^-?\d+$") and ("image/jpeg" = StrGet(NumGet(ci, idx+32+4*A_PtrSize, "ptr"), "UTF-16")) { ; MimeType
        ; Use a separate buffer to store the quality as ValueTypeLong (4).
        v := Buffer(4)
		NumPut("uint", quality, v)

        ; struct EncoderParameter - http://www.jose.it-berater.org/gdiplus/reference/structures/encoderparameter.htm
        ; enum ValueType - https://docs.microsoft.com/en-us/dotnet/api/system.drawing.imaging.encoderparametervaluetype
        ; clsid Image Encoder Constants - http://www.jose.it-berater.org/gdiplus/reference/constants/gdipimageencoderconstants.htm
        ep := Buffer(24+2*A_PtrSize)                  ; sizeof(EncoderParameter) = ptr + n*(28, 32)
        NumPut(  "uptr",     1, ep,            0)  ; Count
        DllCall("ole32\CLSIDFromString", "wstr", "{1D5BE4B5-FA4A-452D-9CDD-5DB35105E7EB}", "ptr", ep.ptr+A_PtrSize, "HRESULT")
        NumPut(  "uint",     1, ep, 16+A_PtrSize)  ; Number of Values
        NumPut(  "uint",     4, ep, 20+A_PtrSize)  ; Type
        NumPut(   "ptr", v.ptr, ep, 24+A_PtrSize)  ; Value
    }

    ; Create a Stream.
    DllCall("ole32\CreateStreamOnHGlobal", "ptr", 0, "int", True, "ptr*", &pStream:=0, "HRESULT")
    DllCall("gdiplus\GdipSaveImageToStream", "ptr", pBitmap, "ptr", pStream, "ptr", pCodec, "ptr", IsSet(ep) ? ep : 0)

    ; Get a pointer to binary data.
    DllCall("ole32\GetHGlobalFromStream", "ptr", pStream, "ptr*", &hbin:=0, "HRESULT")
    bin := DllCall("GlobalLock", "ptr", hbin, "ptr")
    size := DllCall("GlobalSize", "uint", bin, "uptr")

    ; Calculate the length of the base64 string.
    flags := 0x40000001 ; CRYPT_STRING_NOCRLF | CRYPT_STRING_BASE64
    length := 4 * Ceil(size/3) + 1 ; An extra byte of padding is required.
    str := Buffer(length)

    ; Using CryptBinaryToStringA saves about 2MB in memory.
    DllCall("crypt32\CryptBinaryToStringA", "ptr", bin, "uint", size, "uint", flags, "ptr", str, "uint*", &length)

    ; Release binary data and stream.
    DllCall("GlobalUnlock", "ptr", hbin)
    ObjRelease(pStream)
    
    ; Return encoded string length minus 1.
    return StrGet(str, length, "CP0")
}

Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
{
	return DllCall("gdiplus\GdipDrawRectangle", "UPtr", pGraphics, "UPtr", pPen, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_DrawRoundedRectangle(pGraphics, pPen, x, y, w, h, r)
{
	Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
	_E := Gdip_DrawRectangle(pGraphics, pPen, x, y, w, h)
	Gdip_ResetClip(pGraphics)
	Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
	Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
	Gdip_DrawEllipse(pGraphics, pPen, x, y, 2*r, 2*r)
	Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y, 2*r, 2*r)
	Gdip_DrawEllipse(pGraphics, pPen, x, y+h-(2*r), 2*r, 2*r)
	Gdip_DrawEllipse(pGraphics, pPen, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
	Gdip_ResetClip(pGraphics)
	return _E
}

Gdip_DrawEllipse(pGraphics, pPen, x, y, w, h)
{
	return DllCall("gdiplus\GdipDrawEllipse", "UPtr", pGraphics, "UPtr", pPen, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_DrawBezier(pGraphics, pPen, x1, y1, x2, y2, x3, y3, x4, y4)
{
	return DllCall("gdiplus\GdipDrawBezier"
					, "UPtr", pgraphics
					, "UPtr", pPen
					, "Float", x1
					, "Float", y1
					, "Float", x2
					, "Float", y2
					, "Float", x3
					, "Float", y3
					, "Float", x4
					, "Float", y4)
}

Gdip_DrawArc(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle)
{
	return DllCall("gdiplus\GdipDrawArc"
					, "UPtr", pGraphics
					, "UPtr", pPen
					, "Float", x
					, "Float", y
					, "Float", w
					, "Float", h
					, "Float", StartAngle
					, "Float", SweepAngle)
}

Gdip_DrawPie(pGraphics, pPen, x, y, w, h, StartAngle, SweepAngle)
{
	return DllCall("gdiplus\GdipDrawPie", "UPtr", pGraphics, "UPtr", pPen, "Float", x, "Float", y, "Float", w, "Float", h, "Float", StartAngle, "Float", SweepAngle)
}

Gdip_DrawLine(pGraphics, pPen, x1, y1, x2, y2)
{
	return DllCall("gdiplus\GdipDrawLine"
					, "UPtr", pGraphics
					, "UPtr", pPen
					, "Float", x1
					, "Float", y1
					, "Float", x2
					, "Float", y2)
}

Gdip_DrawLines(pGraphics, pPen, points)
{
	points := StrSplit(points, "|")
	pointF := Buffer(8*points.Length)
	pointsLength := 0
	for point in points {
		coords := StrSplit(point, ",")
		if (coords.Length != 2) {
			if (coords.Length > 0) {
				MsgBox("Skipping wrong points of length " coords.Length)
			}
			continue
		}
		NumPut("Float", coords[1], pointF, 8*(A_Index-1))
		NumPut("Float", coords[2], pointF, (8*(A_Index-1))+4)
		pointsLength += 1
	}
	return DllCall("gdiplus\GdipDrawLines", "UPtr", pGraphics, "UPtr", pPen, "UPtr", pointF.Ptr, "Int", pointsLength)
}

Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
{
	return DllCall("gdiplus\GdipFillRectangle"
					, "UPtr", pGraphics
					, "UPtr", pBrush
					, "Float", x
					, "Float", y
					, "Float", w
					, "Float", h)
}

Gdip_FillRoundedRectangle(pGraphics, pBrush, x, y, w, h, r)
{
	Region := Gdip_GetClipRegion(pGraphics)
	Gdip_SetClipRect(pGraphics, x-r, y-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x+w-r, y-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x-r, y+h-r, 2*r, 2*r, 4)
	Gdip_SetClipRect(pGraphics, x+w-r, y+h-r, 2*r, 2*r, 4)
	_E := Gdip_FillRectangle(pGraphics, pBrush, x, y, w, h)
	Gdip_SetClipRegion(pGraphics, Region, 0)
	Gdip_SetClipRect(pGraphics, x-(2*r), y+r, w+(4*r), h-(2*r), 4)
	Gdip_SetClipRect(pGraphics, x+r, y-(2*r), w-(2*r), h+(4*r), 4)
	Gdip_FillEllipse(pGraphics, pBrush, x, y, 2*r, 2*r)
	Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y, 2*r, 2*r)
	Gdip_FillEllipse(pGraphics, pBrush, x, y+h-(2*r), 2*r, 2*r)
	Gdip_FillEllipse(pGraphics, pBrush, x+w-(2*r), y+h-(2*r), 2*r, 2*r)
	Gdip_SetClipRegion(pGraphics, Region, 0)
	Gdip_DeleteRegion(Region)
	return _E
}

Gdip_FillPolygon(pGraphics, pBrush, Points, FillMode:=0)
{
	Points := StrSplit(Points, "|")
	PointsLength := Points.Length
	PointF := Buffer(8*PointsLength)
	For eachPoint, Point in Points
	{
		Coord := StrSplit(Point, ",")
		NumPut("Float", Coord[1], PointF, 8*(A_Index-1))
		NumPut("Float", Coord[2], PointF, (8*(A_Index-1))+4)
	}
	return DllCall("gdiplus\GdipFillPolygon", "UPtr", pGraphics, "UPtr", pBrush, "UPtr", PointF.Ptr, "Int", PointsLength, "Int", FillMode)
}

Gdip_FillPie(pGraphics, pBrush, x, y, w, h, StartAngle, SweepAngle)
{
	return DllCall("gdiplus\GdipFillPie"
					, "UPtr", pGraphics
					, "UPtr", pBrush
					, "Float", x
					, "Float", y
					, "Float", w
					, "Float", h
					, "Float", StartAngle
					, "Float", SweepAngle)
}

Gdip_FillEllipse(pGraphics, pBrush, x, y, w, h)
{
	return DllCall("gdiplus\GdipFillEllipse", "UPtr", pGraphics, "UPtr", pBrush, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_FillRegion(pGraphics, pBrush, Region)
{
	return DllCall("gdiplus\GdipFillRegion", "UPtr", pGraphics, "UPtr", pBrush, "UPtr", Region)
}

Gdip_FillPath(pGraphics, pBrush, pPath)
{
	return DllCall("gdiplus\GdipFillPath", "UPtr", pGraphics, "UPtr", pBrush, "UPtr", pPath)
}

Gdip_DrawImagePointsRect(pGraphics, pBitmap, Points, sx:="", sy:="", sw:="", sh:="", Matrix:=1)
{
	Points := StrSplit(Points, "|")
	PointsLength := Points.Length
	PointF := Buffer(8*PointsLength)
	For eachPoint, Point in Points
	{
		Coord := StrSplit(Point, ",")
		NumPut("Float", Coord[1], PointF, 8*(A_Index-1))
		NumPut("Float", Coord[2], PointF, (8*(A_Index-1))+4)
	}

	if !IsNumber(Matrix)
		ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
	else if (Matrix != 1)
		ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
	else
		ImageAttr := 0

	if (sx = "" && sy = "" && sw = "" && sh = "")
	{
		sx := 0, sy := 0
		sw := Gdip_GetImageWidth(pBitmap)
		sh := Gdip_GetImageHeight(pBitmap)
	}

	_E := DllCall("gdiplus\GdipDrawImagePointsRect"
				, "UPtr", pGraphics
				, "UPtr", pBitmap
				, "UPtr", PointF.Ptr
				, "Int", PointsLength
				, "Float", sx
				, "Float", sy
				, "Float", sw
				, "Float", sh
				, "Int", 2
				, "UPtr", ImageAttr
				, "UPtr", 0
				, "UPtr", 0)
	if ImageAttr
		Gdip_DisposeImageAttributes(ImageAttr)
	return _E
}

Gdip_DrawImage(pGraphics, pBitmap, dx:="", dy:="", dw:="", dh:="", sx:="", sy:="", sw:="", sh:="", Matrix:=1)
{
	if !IsNumber(Matrix)
		ImageAttr := Gdip_SetImageAttributesColorMatrix(Matrix)
	else if (Matrix != 1)
		ImageAttr := Gdip_SetImageAttributesColorMatrix("1|0|0|0|0|0|1|0|0|0|0|0|1|0|0|0|0|0|" Matrix "|0|0|0|0|0|1")
	else
		ImageAttr := 0

	if (sx = "" && sy = "" && sw = "" && sh = "")
	{
		if (dx = "" && dy = "" && dw = "" && dh = "")
		{
			sx := dx := 0, sy := dy := 0
			sw := dw := Gdip_GetImageWidth(pBitmap)
			sh := dh := Gdip_GetImageHeight(pBitmap)
		}
		else
		{
			sx := sy := 0
			sw := Gdip_GetImageWidth(pBitmap)
			sh := Gdip_GetImageHeight(pBitmap)
		}
	}

	_E := DllCall("gdiplus\GdipDrawImageRectRect"
				, "UPtr", pGraphics
				, "UPtr", pBitmap
				, "Float", dx
				, "Float", dy
				, "Float", dw
				, "Float", dh
				, "Float", sx
				, "Float", sy
				, "Float", sw
				, "Float", sh
				, "Int", 2
				, "UPtr", ImageAttr
				, "UPtr", 0
				, "UPtr", 0)
	if ImageAttr
		Gdip_DisposeImageAttributes(ImageAttr)
	return _E
}

Gdip_SetImageAttributesColorMatrix(Matrix)
{
	ColourMatrix := Buffer(100, 0)
	Matrix := RegExReplace(RegExReplace(Matrix, "^[^\d-\.]+([\d\.])", "$1", , 1), "[^\d-\.]+", "|")
	Matrix := StrSplit(Matrix, "|")

	loop 25 {
		M := (Matrix[A_Index] != "") ? Matrix[A_Index] : Mod(A_Index-1, 6) ? 0 : 1
		NumPut("Float", M, ColourMatrix, (A_Index-1)*4)
	}

	DllCall("gdiplus\GdipCreateImageAttributes", "UPtr*", &ImageAttr:=0)
	DllCall("gdiplus\GdipSetImageAttributesColorMatrix", "UPtr", ImageAttr, "Int", 1, "Int", 1, "UPtr", ColourMatrix.Ptr, "UPtr", 0, "Int", 0)

	return ImageAttr
}

Gdip_GraphicsFromImage(pBitmap)
{
	DllCall("gdiplus\GdipGetImageGraphicsContext", "UPtr", pBitmap, "UPtr*", &pGraphics:=0)
	return pGraphics
}

Gdip_GraphicsFromHDC(hdc)
{
	DllCall("gdiplus\GdipCreateFromHDC", "UPtr", hdc, "UPtr*", &pGraphics:=0)
	return pGraphics
}

Gdip_GetDC(pGraphics)
{
	DllCall("gdiplus\GdipGetDC", "UPtr", pGraphics, "UPtr*", &hdc:=0)
	return hdc
}

Gdip_ReleaseDC(pGraphics, hdc)
{
	return DllCall("gdiplus\GdipReleaseDC", "UPtr", pGraphics, "UPtr", hdc)
}

Gdip_GraphicsClear(pGraphics, ARGB:=0x00ffffff)
{
	return DllCall("gdiplus\GdipGraphicsClear", "UPtr", pGraphics, "Int", ARGB)
}

Gdip_BlurBitmap(pBitmap, Blur)
{
	if (Blur > 100 || Blur < 1) {
		return -1
	}

	sWidth := Gdip_GetImageWidth(pBitmap), sHeight := Gdip_GetImageHeight(pBitmap)
	dWidth := sWidth//Blur, dHeight := sHeight//Blur

	pBitmap1 := Gdip_CreateBitmap(dWidth, dHeight)
	G1 := Gdip_GraphicsFromImage(pBitmap1)
	Gdip_SetInterpolationMode(G1, 7)
	Gdip_DrawImage(G1, pBitmap, 0, 0, dWidth, dHeight, 0, 0, sWidth, sHeight)

	Gdip_DeleteGraphics(G1)

	pBitmap2 := Gdip_CreateBitmap(sWidth, sHeight)
	G2 := Gdip_GraphicsFromImage(pBitmap2)
	Gdip_SetInterpolationMode(G2, 7)
	Gdip_DrawImage(G2, pBitmap1, 0, 0, sWidth, sHeight, 0, 0, dWidth, dHeight)

	Gdip_DeleteGraphics(G2)
	Gdip_DisposeImage(pBitmap1)

	return pBitmap2
}

Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality:=75)
{
	_p := 0

	SplitPath sOutput,,, &extension:=""
	if (!RegExMatch(extension, "^(?i:BMP|DIB|RLE|JPG|JPEG|JPE|JFIF|GIF|TIF|TIFF|PNG)$")) {
		return -1
	}
	extension := "." extension

	DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", &nCount:=0, "uint*", &nSize:=0)
	ci := Buffer(nSize)
	DllCall("gdiplus\GdipGetImageEncoders", "UInt", nCount, "UInt", nSize, "UPtr", ci.Ptr)
	if !(nCount && nSize) {
		return -2
	}

	loop nCount {
		address := NumGet(ci, (idx := (48+7*A_PtrSize)*(A_Index-1))+32+3*A_PtrSize, "UPtr")
		sString := StrGet(address, "UTF-16")
		if !InStr(sString, "*" extension)
			continue

		pCodec := ci.Ptr+idx
		break
	}

	if !pCodec {
		return -3
	}

	if (Quality != 75) {
		Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality

		if RegExMatch(extension, "^\.(?i:JPG|JPEG|JPE|JFIF)$") {
			DllCall("gdiplus\GdipGetEncoderParameterListSize", "UPtr", pBitmap, "UPtr", pCodec, "uint*", &nSize)
			EncoderParameters := Buffer(nSize, 0)
			DllCall("gdiplus\GdipGetEncoderParameterList", "UPtr", pBitmap, "UPtr", pCodec, "UInt", nSize, "UPtr", EncoderParameters.Ptr)
			nCount := NumGet(EncoderParameters, "UInt")
			loop nCount
			{
				elem := (24+(A_PtrSize ? A_PtrSize : 4))*(A_Index-1) + 4 + (pad := A_PtrSize = 8 ? 4 : 0)
				if (NumGet(EncoderParameters, elem+16, "UInt") = 1) && (NumGet(EncoderParameters, elem+20, "UInt") = 6)
				{
					_p := elem + EncoderParameters.Ptr - pad - 4
					NumPut("UInt", Quality, NumGet(NumPut("UInt", 4, NumPut("UInt", 1, _p+0)+20), "UInt"))
					break
				}
			}
		}
	}

	_E := DllCall("gdiplus\GdipSaveImageToFile", "UPtr", pBitmap, "UPtr", StrPtr(sOutput), "UPtr", pCodec, "UInt", _p ? _p : 0)

	return _E ? -5 : 0
}

Gdip_GetPixel(pBitmap, x, y)
{
	DllCall("gdiplus\GdipBitmapGetPixel", "UPtr", pBitmap, "Int", x, "Int", y, "uint*", &ARGB:=0)
	return ARGB
}

Gdip_SetPixel(pBitmap, x, y, ARGB)
{
	return DllCall("gdiplus\GdipBitmapSetPixel", "UPtr", pBitmap, "Int", x, "Int", y, "Int", ARGB)
}

Gdip_GetImageWidth(pBitmap)
{
	DllCall("gdiplus\GdipGetImageWidth", "UPtr", pBitmap, "uint*", &Width:=0)
	return Width
}

Gdip_GetImageHeight(pBitmap)
{
	DllCall("gdiplus\GdipGetImageHeight", "UPtr", pBitmap, "uint*", &Height:=0)
	return Height
}

Gdip_GetImageDimensions(pBitmap, &Width, &Height)
{
	DllCall("gdiplus\GdipGetImageWidth", "UPtr", pBitmap, "uint*", &Width:=0)
	DllCall("gdiplus\GdipGetImageHeight", "UPtr", pBitmap, "uint*", &Height:=0)
}

Gdip_GetDimensions(pBitmap, &Width, &Height)
{
	Gdip_GetImageDimensions(pBitmap, &Width, &Height)
}

Gdip_GetImagePixelFormat(pBitmap)
{
	DllCall("gdiplus\GdipGetImagePixelFormat", "UPtr", pBitmap, "UPtr*", &_Format:=0)
	return _Format
}

Gdip_GetDpiX(pGraphics)
{
	DllCall("gdiplus\GdipGetDpiX", "UPtr", pGraphics, "float*", &dpix:=0)
	return Round(dpix)
}

Gdip_GetDpiY(pGraphics)
{
	DllCall("gdiplus\GdipGetDpiY", "UPtr", pGraphics, "float*", &dpiy:=0)
	return Round(dpiy)
}

Gdip_GetImageHorizontalResolution(pBitmap)
{
	DllCall("gdiplus\GdipGetImageHorizontalResolution", "UPtr", pBitmap, "float*", &dpix:=0)
	return Round(dpix)
}

Gdip_GetImageVerticalResolution(pBitmap)
{
	DllCall("gdiplus\GdipGetImageVerticalResolution", "UPtr", pBitmap, "float*", &dpiy:=0)
	return Round(dpiy)
}

Gdip_BitmapSetResolution(pBitmap, dpix, dpiy)
{
	return DllCall("gdiplus\GdipBitmapSetResolution", "UPtr", pBitmap, "Float", dpix, "Float", dpiy)
}

Gdip_CreateBitmapFromFile(sFile, IconNumber:=1, IconSize:="")
{
	SplitPath sFile,,, &extension:=""
	if RegExMatch(extension, "^(?i:exe|dll)$") {
		Sizes := IconSize ? IconSize : 256 "|" 128 "|" 64 "|" 48 "|" 32 "|" 16
		BufSize := 16 + (2*(A_PtrSize ? A_PtrSize : 4))

		buf := Buffer(BufSize, 0)
		hIcon := 0

		for eachSize, Size in StrSplit( Sizes, "|" ) {
			DllCall("PrivateExtractIcons", "str", sFile, "Int", IconNumber-1, "Int", Size, "Int", Size, "UPtr*", &hIcon, "UPtr*", 0, "UInt", 1, "UInt", 0)

			if (!hIcon) {
				continue
			}

			if !DllCall("GetIconInfo", "UPtr", hIcon, "UPtr", buf.Ptr) {
				DestroyIcon(hIcon)
				continue
			}

			hbmMask  := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4))
			hbmColor := NumGet(buf, 12 + ((A_PtrSize ? A_PtrSize : 4) - 4) + (A_PtrSize ? A_PtrSize : 4))
			if !(hbmColor && DllCall("GetObject", "UPtr", hbmColor, "Int", BufSize, "UPtr", buf.Ptr))
			{
				DestroyIcon(hIcon)
				continue
			}
			break
		}

		if (!hIcon) {
			return -1
		}

		Width := NumGet(buf, 4, "Int"), Height := NumGet(buf, 8, "Int")
		hbm := CreateDIBSection(Width, -Height), hdc := CreateCompatibleDC(), obm := SelectObject(hdc, hbm)
		if !DllCall("DrawIconEx", "UPtr", hdc, "Int", 0, "Int", 0, "UPtr", hIcon, "UInt", Width, "UInt", Height, "UInt", 0, "UPtr", 0, "UInt", 3) {
			DestroyIcon(hIcon)
			return -2
		}

		dib := Buffer(104)
		DllCall("GetObject", "UPtr", hbm, "Int", A_PtrSize = 8 ? 104 : 84, "UPtr", dib.Ptr) ; sizeof(DIBSECTION) = 76+2*(A_PtrSize=8?4:0)+2*A_PtrSize
		Stride := NumGet(dib, 12, "Int"), Bits := NumGet(dib, 20 + (A_PtrSize = 8 ? 4 : 0)) ; padding
		DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", Width, "Int", Height, "Int", Stride, "Int", 0x26200A, "UPtr", Bits, "UPtr*", &pBitmapOld:=0)
		pBitmap := Gdip_CreateBitmap(Width, Height)
		_G := Gdip_GraphicsFromImage(pBitmap)
		, Gdip_DrawImage(_G, pBitmapOld, 0, 0, Width, Height, 0, 0, Width, Height)
		SelectObject(hdc, obm), DeleteObject(hbm), DeleteDC(hdc)
		Gdip_DeleteGraphics(_G), Gdip_DisposeImage(pBitmapOld)
		DestroyIcon(hIcon)

	} else {
		DllCall("gdiplus\GdipCreateBitmapFromFile", "UPtr", StrPtr(sFile), "UPtr*", &pBitmap:=0)
	}

	return pBitmap
}

Gdip_CreateBitmapFromHBITMAP(hBitmap, Palette:=0)
{
	DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "UPtr", hBitmap, "UPtr", Palette, "UPtr*", &pBitmap:=0)
	return pBitmap
}

Gdip_CreateHBITMAPFromBitmap(pBitmap, Background:=0xffffffff)
{
	DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "UPtr", pBitmap, "UPtr*", &hbm:=0, "Int", Background)
	return hbm
}

Gdip_CreateARGBBitmapFromHBITMAP(&hBitmap) {
	; struct BITMAP - https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmap
	dib := Buffer(76+2*(A_PtrSize=8?4:0)+2*A_PtrSize)
	DllCall("GetObject"
				,    "ptr", hBitmap
				,    "Int", dib.Size
				,    "ptr", dib.Ptr) ; sizeof(DIBSECTION) = 84, 104
		, width  := NumGet(dib, 4, "UInt")
		, height := NumGet(dib, 8, "UInt")
		, bpp    := NumGet(dib, 18, "ushort")

	; Fallback to built-in method if pixels are not 32-bit ARGB.
	if (bpp != 32) { ; This built-in version is 120% faster but ignores transparency.
		DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "ptr", hBitmap, "ptr", 0, "ptr*", &pBitmap:=0)
		return pBitmap
	}

	; Create a handle to a device context and associate the image.
	hdc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")             ; Creates a memory DC compatible with the current screen.
	obm := DllCall("SelectObject", "ptr", hdc, "ptr", hBitmap, "ptr") ; Put the (hBitmap) image onto the device context.

	; Create a device independent bitmap with negative height. All DIBs use the screen pixel format (pARGB).
	; Use hbm to buffer the image such that top-down and bottom-up images are mapped to this top-down buffer.
	cdc := DllCall("CreateCompatibleDC", "ptr", hdc, "ptr")
	bi := Buffer(40, 0)               ; sizeof(bi) = 40
	NumPut(
		"UInt", 	40, 	; Size
		"UInt", 	width,	; Width
		"Int", 		height, ; Height - Negative so (0, 0) is top-left.
		"ushort",	1, 		; Planes
		"ushort",	32, 	; BitCount / BitsPerPixel
		bi)
	hbm := DllCall("CreateDIBSection", "ptr", cdc, "ptr", bi.Ptr, "UInt", 0
				, "ptr*", &pBits:=0  ; pBits is the pointer to (top-down) pixel values.
				, "ptr", 0, "UInt", 0, "ptr")
	ob2 := DllCall("SelectObject", "ptr", cdc, "ptr", hbm, "ptr")

	; This is the 32-bit ARGB pBitmap (different from an hBitmap) that will receive the final converted pixels.
	DllCall("gdiplus\GdipCreateBitmapFromScan0"
				, "Int", width, "Int", height, "Int", 0, "Int", 0x26200A, "ptr", 0, "ptr*", &pBitmap:=0)

	; Create a Scan0 buffer pointing to pBits. The buffer has pixel format pARGB.
	Rect := Buffer(16, 0)              ; sizeof(Rect) = 16
	NumPut(
		"UInt",   width,	; Width
		"UInt",  height,	; Height
		Rect, 8)
	
	BitmapData := Buffer(16+2*A_PtrSize, 0)     ; sizeof(BitmapData) = 24, 32
	NumPut(
		"UInt", width, 		; Width
		"UInt", height, 	; Height
		"Int",  4 * width,	; Stride
		"Int",  0xE200B, 	; PixelFormat
		"ptr",  pBits, 	 	; Scan0
		BitmapData)

	; Use LockBits to create a writable buffer that converts pARGB to ARGB.
	DllCall("gdiplus\GdipBitmapLockBits"
				,    "ptr", pBitmap
				,    "ptr", Rect.Ptr
				,   "UInt", 6            ; ImageLockMode.UserInputBuffer | ImageLockMode.WriteOnly
				,    "Int", 0xE200B      ; Format32bppPArgb
				,    "ptr", BitmapData.Ptr) ; Contains the pointer (pBits) to the hbm.

	; Copies the image (hBitmap) to a top-down bitmap. Removes bottom-up-ness if present.
	DllCall("gdi32\BitBlt"
				, "ptr", cdc, "Int", 0, "Int", 0, "Int", width, "Int", height
				, "ptr", hdc, "Int", 0, "Int", 0, "UInt", 0x00CC0020) ; SRCCOPY

	; Convert the pARGB pixels copied into the device independent bitmap (hbm) to ARGB.
	DllCall("gdiplus\GdipBitmapUnlockBits", "ptr", pBitmap, "ptr", BitmapData.Ptr)

	; Cleanup the buffer and device contexts.
	DllCall("SelectObject", "ptr", cdc, "ptr", ob2)
	DllCall("DeleteObject", "ptr", hbm)
	DllCall("DeleteDC",     "ptr", cdc)
	DllCall("SelectObject", "ptr", hdc, "ptr", obm)
	DllCall("DeleteDC",     "ptr", hdc)

	return pBitmap
}

Gdip_CreateARGBHBITMAPFromBitmap(&pBitmap) {
	; This version is about 25% faster than Gdip_CreateHBITMAPFromBitmap().
	; Get Bitmap width and height.
	DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", &width:=0)
	DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", &height:=0)

	; Convert the source pBitmap into a hBitmap manually.
	; struct BITMAPINFOHEADER - https://docs.microsoft.com/en-us/windows/win32/api/wingdi/ns-wingdi-bitmapinfoheader
	hdc := DllCall("CreateCompatibleDC", "ptr", 0, "ptr")
	bi := Buffer(40, 0)               ; sizeof(bi) = 40
	NumPut(
		"UInt",     40,  		; Size
		"UInt",    	width,  	; Width
		"Int",  	-height,	; Height - Negative so (0, 0) is top-left.
		"ushort",   1, 			; Planes
		"ushort",   32,  		; BitCount / BitsPerPixel
		bi)
	hbm := DllCall("CreateDIBSection", "ptr", hdc, "ptr", bi.Ptr, "UInt", 0, "ptr*", &pBits:=0, "ptr", 0, "UInt", 0, "ptr")
	obm := DllCall("SelectObject", "ptr", hdc, "ptr", hbm, "ptr")

	; Transfer data from source pBitmap to an hBitmap manually.
	Rect := Buffer(16, 0)              ; sizeof(Rect) = 16
	NumPut(
		"UInt",   width,	; Width
		"UInt",  height, 	; Height
		Rect, 8)
	BitmapData := Buffer(16+2*A_PtrSize, 0)     ; sizeof(BitmapData) = 24, 32
	NumPut(
		"UInt",     width, 	; Width
		"UInt",    height, 	; Height
		"Int",  4 * width, 	; Stride
		"Int",    0xE200B, 	; PixelFormat
		"ptr",      pBits, 	; Scan0
		BitmapData)
	DllCall("gdiplus\GdipBitmapLockBits"
				,    "ptr", pBitmap
				,    "ptr", Rect.Ptr
				,   "UInt", 5            ; ImageLockMode.UserInputBuffer | ImageLockMode.ReadOnly
				,    "Int", 0xE200B      ; Format32bppPArgb
				,    "ptr", BitmapData.Ptr) ; Contains the pointer (pBits) to the hbm.
	DllCall("gdiplus\GdipBitmapUnlockBits", "ptr", pBitmap, "ptr", BitmapData.Ptr)

	; Cleanup the hBitmap and device contexts.
	DllCall("SelectObject", "ptr", hdc, "ptr", obm)
	DllCall("DeleteDC",     "ptr", hdc)

	return hbm
}

Gdip_CreateBitmapFromHICON(hIcon)
{
	DllCall("gdiplus\GdipCreateBitmapFromHICON", "UPtr", hIcon, "UPtr*", &pBitmap:=0)
	return pBitmap
}

Gdip_CreateHICONFromBitmap(pBitmap)
{
	DllCall("gdiplus\GdipCreateHICONFromBitmap", "UPtr", pBitmap, "UPtr*", &hIcon:=0)
	return hIcon
}

Gdip_CreateBitmap(Width, Height, Format:=0x26200A)
{
	DllCall("gdiplus\GdipCreateBitmapFromScan0", "Int", Width, "Int", Height, "Int", 0, "Int", Format, "UPtr", 0, "UPtr*", &pBitmap:=0)
	return pBitmap
}

Gdip_CreateBitmapFromClipboard()
{
	if !DllCall("IsClipboardFormatAvailable", "UInt", 8) {
		return -2
	}

	if !DllCall("OpenClipboard", "UPtr", 0) {
		return -1
	}

	hBitmap := DllCall("GetClipboardData", "UInt", 2, "UPtr")

	if !DllCall("CloseClipboard") {
		return -5
	}

	if !hBitmap {
		return -3
	}

	pBitmap := Gdip_CreateBitmapFromHBITMAP(hBitmap)
	if (!pBitmap) {
		return -4
	}

	DeleteObject(hBitmap)

	return pBitmap
}

Gdip_SetBitmapToClipboard(pBitmap)
{
	off1 := A_PtrSize = 8 ? 52 : 44, off2 := A_PtrSize = 8 ? 32 : 24
	hBitmap := Gdip_CreateHBITMAPFromBitmap(pBitmap)
	oi := Buffer(A_PtrSize = 8 ? 104 : 84, 0)
	DllCall("GetObject", "UPtr", hBitmap, "Int", oi.Size, "UPtr", oi.Ptr)
	hdib := DllCall("GlobalAlloc", "UInt", 2, "UPtr", 40+NumGet(oi, off1, "UInt"), "UPtr")
	pdib := DllCall("GlobalLock", "UPtr", hdib, "UPtr")
	DllCall("RtlMoveMemory", "UPtr", pdib, "UPtr", oi.Ptr+off2, "UPtr", 40)
	DllCall("RtlMoveMemory", "UPtr", pdib+40, "UPtr", NumGet(oi, off2 - (A_PtrSize ? A_PtrSize : 4), "UPtr"), "UPtr", NumGet(oi, off1, "UInt"))
	DllCall("GlobalUnlock", "UPtr", hdib)
	DllCall("DeleteObject", "UPtr", hBitmap)
	DllCall("OpenClipboard", "UPtr", 0)
	DllCall("EmptyClipboard")
	DllCall("SetClipboardData", "UInt", 8, "UPtr", hdib)
	DllCall("CloseClipboard")
}

Gdip_CloneBitmapArea(pBitmap, x, y, w, h, Format:=0x26200A)
{
	DllCall("gdiplus\GdipCloneBitmapArea"
					, "Float", x
					, "Float", y
					, "Float", w
					, "Float", h
					, "Int", Format
					, "UPtr", pBitmap
					, "UPtr*", &pBitmapDest:=0)
	return pBitmapDest
}

Gdip_CreatePen(ARGB, w)
{
	DllCall("gdiplus\GdipCreatePen1", "UInt", ARGB, "Float", w, "Int", 2, "UPtr*", &pPen:=0)
	return pPen
}

Gdip_CreatePenFromBrush(pBrush, w)
{
	DllCall("gdiplus\GdipCreatePen2", "UPtr", pBrush, "Float", w, "Int", 2, "UPtr*", &pPen:=0)
	return pPen
}

Gdip_BrushCreateSolid(ARGB:=0xff000000)
{
	DllCall("gdiplus\GdipCreateSolidFill", "UInt", ARGB, "UPtr*", &pBrush:=0)
	return pBrush
}

Gdip_BrushCreateHatch(ARGBfront, ARGBback, HatchStyle:=0)
{
	DllCall("gdiplus\GdipCreateHatchBrush", "Int", HatchStyle, "UInt", ARGBfront, "UInt", ARGBback, "UPtr*", &pBrush:=0)
	return pBrush
}

Gdip_CreateTextureBrush(pBitmap, WrapMode:=1, x:=0, y:=0, w:="", h:="")
{
	if !(w && h) {
		DllCall("gdiplus\GdipCreateTexture", "UPtr", pBitmap, "Int", WrapMode, "UPtr*", &pBrush:=0)
	} else {
		DllCall("gdiplus\GdipCreateTexture2", "UPtr", pBitmap, "Int", WrapMode, "Float", x, "Float", y, "Float", w, "Float", h, "UPtr*", &pBrush:=0)
	}

	return pBrush
}

Gdip_CreateLineBrush(x1, y1, x2, y2, ARGB1, ARGB2, WrapMode:=1)
{
	CreatePointF(&PointF1:="", x1, y1), CreatePointF(&PointF2:="", x2, y2)
	DllCall("gdiplus\GdipCreateLineBrush", "UPtr", PointF1.Ptr, "UPtr", PointF2.Ptr, "UInt", ARGB1, "UInt", ARGB2, "Int", WrapMode, "UPtr*", &LGpBrush:=0)
	return LGpBrush
}

Gdip_CreateLineBrushFromRect(x, y, w, h, ARGB1, ARGB2, LinearGradientMode:=1, WrapMode:=1)
{
	CreateRectF(&RectF:="", x, y, w, h)
	DllCall("gdiplus\GdipCreateLineBrushFromRect", "UPtr", RectF.Ptr, "Int", ARGB1, "Int", ARGB2, "Int", LinearGradientMode, "Int", WrapMode, "UPtr*", &LGpBrush:=0)
	return LGpBrush
}

Gdip_CloneBrush(pBrush)
{
	DllCall("gdiplus\GdipCloneBrush", "UPtr", pBrush, "UPtr*", &pBrushClone:=0)
	return pBrushClone
}

Gdip_DeletePen(pPen)
{
	return DllCall("gdiplus\GdipDeletePen", "UPtr", pPen)
}

Gdip_DeleteBrush(pBrush)
{
	return DllCall("gdiplus\GdipDeleteBrush", "UPtr", pBrush)
}

Gdip_DisposeImage(pBitmap)
{
	return DllCall("gdiplus\GdipDisposeImage", "UPtr", pBitmap)
}

Gdip_DeleteGraphics(pGraphics)
{
	return DllCall("gdiplus\GdipDeleteGraphics", "UPtr", pGraphics)
}

Gdip_DisposeImageAttributes(ImageAttr)
{
	return DllCall("gdiplus\GdipDisposeImageAttributes", "UPtr", ImageAttr)
}

Gdip_DeleteFont(hFont)
{
	return DllCall("gdiplus\GdipDeleteFont", "UPtr", hFont)
}

Gdip_DeleteStringFormat(hFormat)
{
	return DllCall("gdiplus\GdipDeleteStringFormat", "UPtr", hFormat)
}

Gdip_DeleteFontFamily(hFamily)
{
	return DllCall("gdiplus\GdipDeleteFontFamily", "UPtr", hFamily)
}

Gdip_DeleteMatrix(Matrix)
{
	return DllCall("gdiplus\GdipDeleteMatrix", "UPtr", Matrix)
}

Gdip_TextToGraphics(pGraphics, Text, Options, Font:="Arial", Width:="", Height:="", Measure:=0)
{
	IWidth := Width
	IHeight := Height
	PassBrush := 0


	pattern_opts := "i)"
	RegExMatch(Options, pattern_opts "X([\-\d\.]+)(p*)", &xpos:="")
	RegExMatch(Options, pattern_opts "Y([\-\d\.]+)(p*)", &ypos:="")
	RegExMatch(Options, pattern_opts "W([\-\d\.]+)(p*)", &Width:="")
	RegExMatch(Options, pattern_opts "H([\-\d\.]+)(p*)", &Height:="")
	RegExMatch(Options, pattern_opts "C(?!(entre|enter))([a-f\d]+)", &Colour:="")
	RegExMatch(Options, pattern_opts "Top|Up|Bottom|Down|vCentre|vCenter", &vPos:="")
	RegExMatch(Options, pattern_opts "NoWrap", &NoWrap:="")
	RegExMatch(Options, pattern_opts "R(\d)", &Rendering:="")
	RegExMatch(Options, pattern_opts "S(\d+)(p*)", &Size:="")

	if Colour && IsInteger(Colour[2]) && !Gdip_DeleteBrush(Gdip_CloneBrush(Colour[2])) {
		PassBrush := 1, pBrush := Colour[2]
	}

	if !(IWidth && IHeight) && ((xpos && xpos[2]) || (ypos && ypos[2]) || (Width && Width[2]) || (Height && Height[2]) || (Size && Size[2])) {
		return -1
	}

	Style := 0
	Styles := "Regular|Bold|Italic|BoldItalic|Underline|Strikeout"
	for eachStyle, valStyle in StrSplit( Styles, "|" ) {
		if RegExMatch(Options, "\b" valStyle)
			Style |= (valStyle != "StrikeOut") ? (A_Index-1) : 8
	}

	Align := 0
	Alignments := "Near|Left|Centre|Center|Far|Right"
	for eachAlignment, valAlignment in StrSplit( Alignments, "|" ) {
		if RegExMatch(Options, "\b" valAlignment) {
			Align |= A_Index*10//21	; 0|0|1|1|2|2
		}
	}

	xpos := (xpos && (xpos[1] != "")) ? xpos[2] ? IWidth*(xpos[1]/100) : xpos[1] : 0
	ypos := (ypos && (ypos[1] != "")) ? ypos[2] ? IHeight*(ypos[1]/100) : ypos[1] : 0
	Width := (Width && Width[1]) ? Width[2] ? IWidth*(Width[1]/100) : Width[1] : IWidth
	Height := (Height && Height[1]) ? Height[2] ? IHeight*(Height[1]/100) : Height[1] : IHeight

	if !PassBrush {
		Colour := "0x" (Colour && Colour[2] ? Colour[2] : "ff000000")
	}

	Rendering := (Rendering && (Rendering[1] >= 0) && (Rendering[1] <= 5)) ? Rendering[1] : 4
	Size := (Size && (Size[1] > 0)) ? Size[2] ? IHeight*(Size[1]/100) : Size[1] : 12

	hFamily := Gdip_FontFamilyCreate(Font)
	hFont := Gdip_FontCreate(hFamily, Size, Style)
	FormatStyle := NoWrap ? 0x4000 | 0x1000 : 0x4000
	hFormat := Gdip_StringFormatCreate(FormatStyle)
	pBrush := PassBrush ? pBrush : Gdip_BrushCreateSolid(Colour)

	if !(hFamily && hFont && hFormat && pBrush && pGraphics) {
		return !pGraphics ? -2 : !hFamily ? -3 : !hFont ? -4 : !hFormat ? -5 : !pBrush ? -6 : 0
	}

	CreateRectF(&RC:="", xpos, ypos, Width, Height)
	Gdip_SetStringFormatAlign(hFormat, Align)
	Gdip_SetTextRenderingHint(pGraphics, Rendering)
	ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, &RC)

	if vPos {
		ReturnRC := StrSplit(ReturnRC, "|")

		if (vPos[0] = "vCentre") || (vPos[0] = "vCenter")
			ypos += (Height-ReturnRC[4])//2
		else if (vPos[0] = "Top") || (vPos[0] = "Up")
			ypos := 0
		else if (vPos[0] = "Bottom") || (vPos[0] = "Down")
			ypos := Height-ReturnRC[4]

		CreateRectF(&RC, xpos, ypos, Width, ReturnRC[4])
		ReturnRC := Gdip_MeasureString(pGraphics, Text, hFont, hFormat, &RC)
	}

	if !Measure {
		ReturnRC := Gdip_DrawString(pGraphics, Text, hFont, hFormat, pBrush, &RC)
	}

	if !PassBrush {
		Gdip_DeleteBrush(pBrush)
	}

	Gdip_DeleteStringFormat(hFormat)
	Gdip_DeleteFont(hFont)
	Gdip_DeleteFontFamily(hFamily)

	return ReturnRC
}

Gdip_DrawString(pGraphics, sString, hFont, hFormat, pBrush, &RectF)
{
	return DllCall("gdiplus\GdipDrawString"
					, "UPtr", pGraphics
					, "UPtr", StrPtr(sString)
					, "Int", -1
					, "UPtr", hFont
					, "UPtr", RectF.Ptr
					, "UPtr", hFormat
					, "UPtr", pBrush)
}

Gdip_MeasureString(pGraphics, sString, hFont, hFormat, &RectF)
{
	RC := Buffer(16)
	DllCall("gdiplus\GdipMeasureString"
					, "UPtr", pGraphics
					, "UPtr", StrPtr(sString)
					, "Int", -1
					, "UPtr", hFont
					, "UPtr", RectF.Ptr
					, "UPtr", hFormat
					, "UPtr", RC.Ptr
					, "uint*", &Chars:=0
					, "uint*", &Lines:=0)

	return RC.Ptr ? NumGet(RC, 0, "Float") "|" NumGet(RC, 4, "Float") "|" NumGet(RC, 8, "Float") "|" NumGet(RC, 12, "Float") "|" Chars "|" Lines : 0
}

Gdip_SetStringFormatAlign(hFormat, Align)
{
	return DllCall("gdiplus\GdipSetStringFormatAlign", "UPtr", hFormat, "Int", Align)
}

Gdip_StringFormatCreate(Format:=0, Lang:=0)
{
	DllCall("gdiplus\GdipCreateStringFormat", "Int", Format, "Int", Lang, "UPtr*", &hFormat:=0)
	return hFormat
}

Gdip_FontCreate(hFamily, Size, Style:=0)
{
	DllCall("gdiplus\GdipCreateFont", "UPtr", hFamily, "Float", Size, "Int", Style, "Int", 0, "UPtr*", &hFont:=0)
	return hFont
}

Gdip_FontFamilyCreate(Font)
{
	DllCall("gdiplus\GdipCreateFontFamilyFromName"
					, "UPtr", StrPtr(Font)
					, "UInt", 0
					, "UPtr*", &hFamily:=0)

	return hFamily
}

Gdip_CreateAffineMatrix(m11, m12, m21, m22, x, y)
{
	DllCall("gdiplus\GdipCreateMatrix2", "Float", m11, "Float", m12, "Float", m21, "Float", m22, "Float", x, "Float", y, "UPtr*", &Matrix:=0)
	return Matrix
}

Gdip_CreateMatrix()
{
	DllCall("gdiplus\GdipCreateMatrix", "UPtr*", &Matrix:=0)
	return Matrix
}

Gdip_CreatePath(BrushMode:=0)
{
	DllCall("gdiplus\GdipCreatePath", "Int", BrushMode, "UPtr*", &pPath:=0)
	return pPath
}

Gdip_AddPathEllipse(pPath, x, y, w, h)
{
	return DllCall("gdiplus\GdipAddPathEllipse", "UPtr", pPath, "Float", x, "Float", y, "Float", w, "Float", h)
}

Gdip_AddPathPolygon(pPath, Points)
{
	Points := StrSplit(Points, "|")
	PointsLength := Points.Length
	PointF := Buffer(8*PointsLength)
	for eachPoint, Point in Points
	{
		Coord := StrSplit(Point, ",")
		NumPut("Float", Coord[1], PointF, 8*(A_Index-1))
		NumPut("Float", Coord[2], PointF, (8*(A_Index-1))+4)
	}

	return DllCall("gdiplus\GdipAddPathPolygon", "UPtr", pPath, "UPtr", PointF.Ptr, "Int", PointsLength)
}

Gdip_DeletePath(pPath)
{
	return DllCall("gdiplus\GdipDeletePath", "UPtr", pPath)
}

Gdip_SetTextRenderingHint(pGraphics, RenderingHint)
{
	return DllCall("gdiplus\GdipSetTextRenderingHint", "UPtr", pGraphics, "Int", RenderingHint)
}

Gdip_SetInterpolationMode(pGraphics, InterpolationMode)
{
	return DllCall("gdiplus\GdipSetInterpolationMode", "UPtr", pGraphics, "Int", InterpolationMode)
}

Gdip_SetSmoothingMode(pGraphics, SmoothingMode)
{
	return DllCall("gdiplus\GdipSetSmoothingMode", "UPtr", pGraphics, "Int", SmoothingMode)
}

Gdip_SetCompositingMode(pGraphics, CompositingMode:=0)
{
	return DllCall("gdiplus\GdipSetCompositingMode", "UPtr", pGraphics, "Int", CompositingMode)
}

Gdip_Startup()
{
	if (!DllCall("LoadLibrary", "str", "gdiplus", "UPtr")) {
		throw Error("Could not load GDI+ library")
	}

	si := Buffer(A_PtrSize = 4 ? 20:32, 0) ; sizeof(GdiplusStartupInputEx) = 20, 32
	NumPut("uint", 0x2, si)
	NumPut("uint", 0x4, si, A_PtrSize = 4 ? 16:24)
	DllCall("gdiplus\GdiplusStartup", "UPtr*", &pToken:=0, "Ptr", si, "UPtr", 0)
	if (!pToken) {
		throw Error("Gdiplus failed to start. Please ensure you have gdiplus on your system")
	}

	return pToken
}

Gdip_Shutdown(pToken)
{
	DllCall("gdiplus\GdiplusShutdown", "UPtr", pToken)
	hModule := DllCall("GetModuleHandle", "str", "gdiplus", "UPtr")
	if (!hModule) {
		throw Error("GDI+ library was unloaded before shutdown")
	}
	if (!DllCall("FreeLibrary", "UPtr", hModule)) {
		throw Error("Could not free GDI+ library")
	}

	return 0
}

Gdip_RotateWorldTransform(pGraphics, Angle, MatrixOrder:=0)
{
	return DllCall("gdiplus\GdipRotateWorldTransform", "UPtr", pGraphics, "Float", Angle, "Int", MatrixOrder)
}

Gdip_ScaleWorldTransform(pGraphics, x, y, MatrixOrder:=0)
{
	return DllCall("gdiplus\GdipScaleWorldTransform", "UPtr", pGraphics, "Float", x, "Float", y, "Int", MatrixOrder)
}

Gdip_TranslateWorldTransform(pGraphics, x, y, MatrixOrder:=0)
{
	return DllCall("gdiplus\GdipTranslateWorldTransform", "UPtr", pGraphics, "Float", x, "Float", y, "Int", MatrixOrder)
}

Gdip_ResetWorldTransform(pGraphics)
{
	return DllCall("gdiplus\GdipResetWorldTransform", "UPtr", pGraphics)
}

Gdip_GetRotatedTranslation(Width, Height, Angle, &xTranslation, &yTranslation)
{
	pi := 3.14159, TAngle := Angle*(pi/180)

	Bound := (Angle >= 0) ? Mod(Angle, 360) : 360-Mod(-Angle, -360)
	if ((Bound >= 0) && (Bound <= 90)) {
		xTranslation := Height*Sin(TAngle), yTranslation := 0
	} else if ((Bound > 90) && (Bound <= 180)) {
		xTranslation := (Height*Sin(TAngle))-(Width*Cos(TAngle)), yTranslation := -Height*Cos(TAngle)
	} else if ((Bound > 180) && (Bound <= 270)) {
		xTranslation := -(Width*Cos(TAngle)), yTranslation := -(Height*Cos(TAngle))-(Width*Sin(TAngle))
	} else if ((Bound > 270) && (Bound <= 360)) {
		xTranslation := 0, yTranslation := -Width*Sin(TAngle)
	}
}

Gdip_GetRotatedDimensions(Width, Height, Angle, &RWidth, &RHeight)
{
	pi := 3.14159, TAngle := Angle*(pi/180)

	if !(Width && Height) {
		return -1
	}

	RWidth := Ceil(Abs(Width*Cos(TAngle))+Abs(Height*Sin(TAngle)))
	RHeight := Ceil(Abs(Width*Sin(TAngle))+Abs(Height*Cos(Tangle)))
}

Gdip_ImageRotateFlip(pBitmap, RotateFlipType:=1)
{
	return DllCall("gdiplus\GdipImageRotateFlip", "UPtr", pBitmap, "Int", RotateFlipType)
}

Gdip_SetClipRect(pGraphics, x, y, w, h, CombineMode:=0)
{
	return DllCall("gdiplus\GdipSetClipRect",  "UPtr", pGraphics, "Float", x, "Float", y, "Float", w, "Float", h, "Int", CombineMode)
}

Gdip_SetClipPath(pGraphics, pPath, CombineMode:=0)
{
	return DllCall("gdiplus\GdipSetClipPath", "UPtr", pGraphics, "UPtr", pPath, "Int", CombineMode)
}

Gdip_ResetClip(pGraphics)
{
	return DllCall("gdiplus\GdipResetClip", "UPtr", pGraphics)
}

Gdip_GetClipRegion(pGraphics)
{
	Region := Gdip_CreateRegion()
	DllCall("gdiplus\GdipGetClip", "UPtr", pGraphics, "UInt", Region)
	return Region
}

Gdip_SetClipRegion(pGraphics, Region, CombineMode:=0)
{
	return DllCall("gdiplus\GdipSetClipRegion", "UPtr", pGraphics, "UPtr", Region, "Int", CombineMode)
}

Gdip_CreateRegion()
{
	DllCall("gdiplus\GdipCreateRegion", "UInt*", &Region:=0)
	return Region
}

Gdip_DeleteRegion(Region)
{
	return DllCall("gdiplus\GdipDeleteRegion", "UPtr", Region)
}

Gdip_LockBits(pBitmap, x, y, w, h, &Stride, &Scan0, &BitmapData, LockMode := 3, PixelFormat := 0x26200a)
{
	CreateRect(&_Rect:="", x, y, w, h)
	BitmapData := Buffer(16+2*(A_PtrSize ? A_PtrSize : 4), 0)
	_E := DllCall("Gdiplus\GdipBitmapLockBits", "UPtr", pBitmap, "UPtr", _Rect.Ptr, "UInt", LockMode, "Int", PixelFormat, "UPtr", BitmapData.Ptr)
	Stride := NumGet(BitmapData, 8, "Int")
	Scan0 := NumGet(BitmapData, 16, "UPtr")
	return _E
}

Gdip_UnlockBits(pBitmap, &BitmapData)
{
	return DllCall("Gdiplus\GdipBitmapUnlockBits", "UPtr", pBitmap, "UPtr", BitmapData.Ptr)
}

Gdip_SetLockBitPixel(ARGB, Scan0, x, y, Stride)
{
	Numput("UInt", ARGB, Scan0+0, (x*4)+(y*Stride))
}

Gdip_GetLockBitPixel(Scan0, x, y, Stride)
{
	return NumGet(Scan0+0, (x*4)+(y*Stride), "UInt")
}

Gdip_PixelateBitmap(pBitmap, &pBitmapOut, BlockSize)
{
	static PixelateBitmap := ""

	if (!PixelateBitmap)
	{
		if A_PtrSize != 8 ; x86 machine code
		MCode_PixelateBitmap := "
		(LTrim Join
		558BEC83EC3C8B4514538B5D1C99F7FB56578BC88955EC894DD885C90F8E830200008B451099F7FB8365DC008365E000894DC88955F08945E833FF897DD4
		397DE80F8E160100008BCB0FAFCB894DCC33C08945F88945FC89451C8945143BD87E608B45088D50028BC82BCA8BF02BF2418945F48B45E02955F4894DC4
		8D0CB80FAFCB03CA895DD08BD1895DE40FB64416030145140FB60201451C8B45C40FB604100145FC8B45F40FB604020145F883C204FF4DE475D6034D18FF
		4DD075C98B4DCC8B451499F7F98945148B451C99F7F989451C8B45FC99F7F98945FC8B45F899F7F98945F885DB7E648B450C8D50028BC82BCA83C103894D
		C48BC82BCA41894DF48B4DD48945E48B45E02955E48D0C880FAFCB03CA895DD08BD18BF38A45148B7DC48804178A451C8B7DF488028A45FC8804178A45F8
		8B7DE488043A83C2044E75DA034D18FF4DD075CE8B4DCC8B7DD447897DD43B7DE80F8CF2FEFFFF837DF0000F842C01000033C08945F88945FC89451C8945
		148945E43BD87E65837DF0007E578B4DDC034DE48B75E80FAF4D180FAFF38B45088D500203CA8D0CB18BF08BF88945F48B45F02BF22BFA2955F48945CC0F
		B6440E030145140FB60101451C0FB6440F010145FC8B45F40FB604010145F883C104FF4DCC75D8FF45E4395DE47C9B8B4DF00FAFCB85C9740B8B451499F7
		F9894514EB048365140033F63BCE740B8B451C99F7F989451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB
		038975F88975E43BDE7E5A837DF0007E4C8B4DDC034DE48B75E80FAF4D180FAFF38B450C8D500203CA8D0CB18BF08BF82BF22BFA2BC28B55F08955CC8A55
		1488540E038A551C88118A55FC88540F018A55F888140183C104FF4DCC75DFFF45E4395DE47CA68B45180145E0015DDCFF4DC80F8594FDFFFF8B451099F7
		FB8955F08945E885C00F8E450100008B45EC0FAFC38365DC008945D48B45E88945CC33C08945F88945FC89451C8945148945103945EC7E6085DB7E518B4D
		D88B45080FAFCB034D108D50020FAF4D18034DDC8BF08BF88945F403CA2BF22BFA2955F4895DC80FB6440E030145140FB60101451C0FB6440F010145FC8B
		45F40FB604080145F883C104FF4DC875D8FF45108B45103B45EC7CA08B4DD485C9740B8B451499F7F9894514EB048365140033F63BCE740B8B451C99F7F9
		89451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB038975F88975103975EC7E5585DB7E468B4DD88B450C
		0FAFCB034D108D50020FAF4D18034DDC8BF08BF803CA2BF22BFA2BC2895DC88A551488540E038A551C88118A55FC88540F018A55F888140183C104FF4DC8
		75DFFF45108B45103B45EC7CAB8BC3C1E0020145DCFF4DCC0F85CEFEFFFF8B4DEC33C08945F88945FC89451C8945148945103BC87E6C3945F07E5C8B4DD8
		8B75E80FAFCB034D100FAFF30FAF4D188B45088D500203CA8D0CB18BF08BF88945F48B45F02BF22BFA2955F48945C80FB6440E030145140FB60101451C0F
		B6440F010145FC8B45F40FB604010145F883C104FF4DC875D833C0FF45108B4DEC394D107C940FAF4DF03BC874068B451499F7F933F68945143BCE740B8B
		451C99F7F989451CEB0389751C3BCE740B8B45FC99F7F98945FCEB038975FC3BCE740B8B45F899F7F98945F8EB038975F88975083975EC7E63EB0233F639
		75F07E4F8B4DD88B75E80FAFCB034D080FAFF30FAF4D188B450C8D500203CA8D0CB18BF08BF82BF22BFA2BC28B55F08955108A551488540E038A551C8811
		8A55FC88540F018A55F888140883C104FF4D1075DFFF45088B45083B45EC7C9F5F5E33C05BC9C21800
		)"
		else ; x64 machine code
		MCode_PixelateBitmap := "
		(LTrim Join
		4489442418488954241048894C24085355565741544155415641574883EC28418BC1448B8C24980000004C8BDA99488BD941F7F9448BD0448BFA8954240C
		448994248800000085C00F8E9D020000418BC04533E4458BF299448924244C8954241041F7F933C9898C24980000008BEA89542404448BE889442408EB05
		4C8B5C24784585ED0F8E1A010000458BF1418BFD48897C2418450FAFF14533D233F633ED4533E44533ED4585C97E5B4C63BC2490000000418D040A410FAF
		C148984C8D441802498BD9498BD04D8BD90FB642010FB64AFF4403E80FB60203E90FB64AFE4883C2044403E003F149FFCB75DE4D03C748FFCB75D0488B7C
		24188B8C24980000004C8B5C2478418BC59941F7FE448BE8418BC49941F7FE448BE08BC59941F7FE8BE88BC69941F7FE8BF04585C97E4048639C24900000
		004103CA4D8BC1410FAFC94863C94A8D541902488BCA498BC144886901448821408869FF408871FE4883C10448FFC875E84803D349FFC875DA8B8C249800
		0000488B5C24704C8B5C24784183C20448FFCF48897C24180F850AFFFFFF8B6C2404448B2424448B6C24084C8B74241085ED0F840A01000033FF33DB4533
		DB4533D24533C04585C97E53488B74247085ED7E42438D0C04418BC50FAF8C2490000000410FAFC18D04814863C8488D5431028BCD0FB642014403D00FB6
		024883C2044403D80FB642FB03D80FB642FA03F848FFC975DE41FFC0453BC17CB28BCD410FAFC985C9740A418BC299F7F98BF0EB0233F685C9740B418BC3
		99F7F9448BD8EB034533DB85C9740A8BC399F7F9448BD0EB034533D285C9740A8BC799F7F9448BC0EB034533C033D24585C97E4D4C8B74247885ED7E3841
		8D0C14418BC50FAF8C2490000000410FAFC18D04814863C84A8D4431028BCD40887001448818448850FF448840FE4883C00448FFC975E8FFC2413BD17CBD
		4C8B7424108B8C2498000000038C2490000000488B5C24704503E149FFCE44892424898C24980000004C897424100F859EFDFFFF448B7C240C448B842480
		000000418BC09941F7F98BE8448BEA89942498000000896C240C85C00F8E3B010000448BAC2488000000418BCF448BF5410FAFC9898C248000000033FF33
		ED33F64533DB4533D24533C04585FF7E524585C97E40418BC5410FAFC14103C00FAF84249000000003C74898488D541802498BD90FB642014403D00FB602
		4883C2044403D80FB642FB03F00FB642FA03E848FFCB75DE488B5C247041FFC0453BC77CAE85C9740B418BC299F7F9448BE0EB034533E485C9740A418BC3
		99F7F98BD8EB0233DB85C9740A8BC699F7F9448BD8EB034533DB85C9740A8BC599F7F9448BD0EB034533D24533C04585FF7E4E488B4C24784585C97E3541
		8BC5410FAFC14103C00FAF84249000000003C74898488D540802498BC144886201881A44885AFF448852FE4883C20448FFC875E941FFC0453BC77CBE8B8C
		2480000000488B5C2470418BC1C1E00203F849FFCE0F85ECFEFFFF448BAC24980000008B6C240C448BA4248800000033FF33DB4533DB4533D24533C04585
		FF7E5A488B7424704585ED7E48418BCC8BC5410FAFC94103C80FAF8C2490000000410FAFC18D04814863C8488D543102418BCD0FB642014403D00FB60248
		83C2044403D80FB642FB03D80FB642FA03F848FFC975DE41FFC0453BC77CAB418BCF410FAFCD85C9740A418BC299F7F98BF0EB0233F685C9740B418BC399
		F7F9448BD8EB034533DB85C9740A8BC399F7F9448BD0EB034533D285C9740A8BC799F7F9448BC0EB034533C033D24585FF7E4E4585ED7E42418BCC8BC541
		0FAFC903CA0FAF8C2490000000410FAFC18D04814863C8488B442478488D440102418BCD40887001448818448850FF448840FE4883C00448FFC975E8FFC2
		413BD77CB233C04883C428415F415E415D415C5F5E5D5BC3
		)"

		PixelateBitmap := Buffer(StrLen(MCode_PixelateBitmap)//2)
		nCount := StrLen(MCode_PixelateBitmap)//2
		loop nCount {
			NumPut("UChar", "0x" SubStr(MCode_PixelateBitmap, (2*A_Index)-1, 2), PixelateBitmap, A_Index-1)
		}
		DllCall("VirtualProtect", "UPtr", PixelateBitmap.Ptr, "UPtr", PixelateBitmap.Size, "UInt", 0x40, "UPtr*", 0)
	}

	Gdip_GetImageDimensions(pBitmap, &Width:="", &Height:="")

	if (Width != Gdip_GetImageWidth(pBitmapOut) || Height != Gdip_GetImageHeight(pBitmapOut))
		return -1
	if (BlockSize > Width || BlockSize > Height)
		return -2

	E1 := Gdip_LockBits(pBitmap, 0, 0, Width, Height, &Stride1:="", &Scan01:="", &BitmapData1:="")
	E2 := Gdip_LockBits(pBitmapOut, 0, 0, Width, Height, &Stride2:="", &Scan02:="", &BitmapData2:="")
	if (E1 || E2)
		return -3

	; E := - unused exit code
	DllCall(PixelateBitmap.Ptr, "UPtr", Scan01, "UPtr", Scan02, "Int", Width, "Int", Height, "Int", Stride1, "Int", BlockSize)

	Gdip_UnlockBits(pBitmap, &BitmapData1), Gdip_UnlockBits(pBitmapOut, &BitmapData2)

	return 0
}

Gdip_ToARGB(A, R, G, B)
{
	return (A << 24) | (R << 16) | (G << 8) | B
}

Gdip_FromARGB(ARGB, &A, &R, &G, &B)
{
	A := (0xff000000 & ARGB) >> 24
	R := (0x00ff0000 & ARGB) >> 16
	G := (0x0000ff00 & ARGB) >> 8
	B := 0x000000ff & ARGB
}

Gdip_AFromARGB(ARGB)
{
	return (0xff000000 & ARGB) >> 24
}

Gdip_RFromARGB(ARGB)
{
	return (0x00ff0000 & ARGB) >> 16
}

Gdip_GFromARGB(ARGB)
{
	return (0x0000ff00 & ARGB) >> 8
}

Gdip_BFromARGB(ARGB)
{
	return 0x000000ff & ARGB
}

StrGetB(Address, Length:=-1, Encoding:=0)
{
	; Flexible parameter handling:
	if !IsInteger(Length) {
		Encoding := Length,  Length := -1
	}

	; Check for obvious errors.
	if (Address+0 < 1024) {
		return
	}

	; Ensure 'Encoding' contains a numeric identifier.
	if (Encoding = "UTF-16") {
		Encoding := 1200
	} else if (Encoding = "UTF-8") {
		Encoding := 65001
	} else if SubStr(Encoding,1,2)="CP" {
		Encoding := SubStr(Encoding,3)
	}

	if !Encoding { 	; "" or 0
		; No conversion necessary, but we might not want the whole string.
		if (Length == -1)
			Length := DllCall("lstrlen", "UInt", Address)
		VarSetStrCapacity(&myString, Length)
		DllCall("lstrcpyn", "str", myString, "UInt", Address, "Int", Length + 1)

	} else if (Encoding = 1200) { 	; UTF-16
		char_count := DllCall("WideCharToMultiByte", "UInt", 0, "UInt", 0x400, "UInt", Address, "Int", Length, "UInt", 0, "UInt", 0, "UInt", 0, "UInt", 0)
		VarSetStrCapacity(&myString, char_count)
		DllCall("WideCharToMultiByte", "UInt", 0, "UInt", 0x400, "UInt", Address, "Int", Length, "str", myString, "Int", char_count, "UInt", 0, "UInt", 0)

	} else if IsInteger(Encoding) {
		; Convert from target encoding to UTF-16 then to the active code page.
		char_count := DllCall("MultiByteToWideChar", "UInt", Encoding, "UInt", 0, "UInt", Address, "Int", Length, "UInt", 0, "Int", 0)
		VarSetStrCapacity(&myString, char_count * 2)
		char_count := DllCall("MultiByteToWideChar", "UInt", Encoding, "UInt", 0, "UInt", Address, "Int", Length, "UInt", myString.Ptr, "Int", char_count * 2)
		myString := StrGetB(myString.Ptr, char_count, 1200)
	}

	return myString
}

GetMonitorCount()
{
	Monitors := MDMF_Enum()
	for k,v in Monitors {
		count := A_Index
	}
	return count
}

GetMonitorInfo(MonitorNum)
{
	Monitors := MDMF_Enum()
	for k,v in Monitors {
		if (v.Num = MonitorNum) {
			return v
		}
	}
}

GetPrimaryMonitor()
{
	Monitors := MDMF_Enum()
	for k,v in Monitors {
		if (v.Primary) {
			return v.Num
		}
	}
}

MDMF_Enum(HMON := "") {
	static EnumProc := CallbackCreate(MDMF_EnumProc)
	static Monitors := Map()

	if (HMON = "") { 	; new enumeration
		Monitors := Map("TotalCount", 0)
		if !DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", EnumProc, "Ptr", ObjPtr(Monitors), "Int")
			return False
	}

	return (HMON = "") ? Monitors : Monitors.HasKey(HMON) ? Monitors[HMON] : False
}

MDMF_EnumProc(HMON, HDC, PRECT, ObjectAddr) {
	Monitors := ObjFromPtrAddRef(ObjectAddr)

	Monitors[HMON] := MDMF_GetInfo(HMON)
	Monitors["TotalCount"]++
	if (Monitors[HMON].Primary) {
		Monitors["Primary"] := HMON
	}

	return true
}

MDMF_FromHWND(HWND, Flag := 0) {
	return DllCall("User32.dll\MonitorFromWindow", "Ptr", HWND, "UInt", Flag, "Ptr")
}

MDMF_FromPoint(&X:="", &Y:="", Flag:=0) {
	if (X = "") || (Y = "") {
		PT := Buffer(8, 0)
		DllCall("User32.dll\GetCursorPos", "Ptr", PT.Ptr, "Int")

		if (X = "") {
			X := NumGet(PT, 0, "Int")
		}

		if (Y = "") {
			Y := NumGet(PT, 4, "Int")
		}
	}
	return DllCall("User32.dll\MonitorFromPoint", "Int64", (X & 0xFFFFFFFF) | (Y << 32), "UInt", Flag, "Ptr")
}

MDMF_FromRect(X, Y, W, H, Flag := 0) {
	RC := Buffer(16, 0)
	NumPut("Int", X, "Int", Y, "Int", X + W, "Int", Y + H, RC)
	return DllCall("User32.dll\MonitorFromRect", "Ptr", RC.Ptr, "UInt", Flag, "Ptr")
}

MDMF_GetInfo(HMON) {
	MIEX := Buffer(40 + (32 << !!1))
	NumPut("UInt", MIEX.Size, MIEX)
	if DllCall("User32.dll\GetMonitorInfo", "Ptr", HMON, "Ptr", MIEX.Ptr, "Int") {
		return {Name:      (Name := StrGet(MIEX.Ptr + 40, 32))  ; CCHDEVICENAME = 32
		      , Num:       RegExReplace(Name, ".*(\d+)$", "$1")
		      , Left:      NumGet(MIEX, 4, "Int")    ; display rectangle
		      , Top:       NumGet(MIEX, 8, "Int")    ; "
		      , Right:     NumGet(MIEX, 12, "Int")   ; "
		      , Bottom:    NumGet(MIEX, 16, "Int")   ; "
		      , WALeft:    NumGet(MIEX, 20, "Int")   ; work area
		      , WATop:     NumGet(MIEX, 24, "Int")   ; "
		      , WARight:   NumGet(MIEX, 28, "Int")   ; "
		      , WABottom:  NumGet(MIEX, 32, "Int")   ; "
		      , Primary:   NumGet(MIEX, 36, "UInt")} ; contains a non-zero value for the primary monitor.
	}
	return False
}

WinGetRect( hwnd, &x:="", &y:="", &w:="", &h:="" ) {
	Ptr := A_PtrSize ? "UPtr" : "UInt"
	CreateRect(&winRect, 0, 0, 0, 0) ;is 16 on both 32 and 64
	;VarSetCapacity( winRect, 16, 0 )	; Alternative of above two lines
	DllCall( "GetWindowRect", "Ptr", hwnd, "Ptr", winRect )
	x := NumGet(winRect,  0, "UInt")
	y := NumGet(winRect,  4, "UInt")
	w := NumGet(winRect,  8, "UInt") - x
	h := NumGet(winRect, 12, "UInt") - y
}