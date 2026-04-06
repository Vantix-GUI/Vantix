local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer and not RunService:IsStudio() then return end

-----------------------------------------------------------------
-- // VANTIX THEME CONFIGURATION // --
-----------------------------------------------------------------
local Theme = {
	MainBackground = Color3.fromRGB(12, 12, 14),
	SidebarBackground = Color3.fromRGB(16, 16, 18),
	ElementBackground = Color3.fromRGB(22, 22, 26),
	ElementHover = Color3.fromRGB(30, 30, 36),
	ElementActive = Color3.fromRGB(40, 40, 48),
	
	Accent = Color3.fromRGB(90, 20, 160), -- Brighter, more vibrant purple
	AccentHover = Color3.fromRGB(110, 35, 185),
	
	Text = Color3.fromRGB(240, 240, 245),
	TextMuted = Color3.fromRGB(140, 140, 150),
	Stroke = Color3.fromRGB(35, 35, 40),
	
	Success = Color3.fromRGB(45, 200, 95),
	Warning = Color3.fromRGB(240, 180, 40),
	Error = Color3.fromRGB(240, 60, 60),
	
	CornerRadius = UDim.new(0, 6),
	AnimSpeed = 0.2
}

-----------------------------------------------------------------
-- // UTILITY FUNCTIONS // --
-----------------------------------------------------------------
local function Tween(instance, properties, duration, style, direction)
	local tweenInfo = TweenInfo.new(
		duration or Theme.AnimSpeed, 
		style or Enum.EasingStyle.Quint, 
		direction or Enum.EasingDirection.Out
	)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

local function MakeDraggable(topbar, window)
	local dragging, dragInput, dragStart, startPos
	local targetPos = window.Position

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			targetPos = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
	
	-- Smooth dragging loop
	RunService.RenderStepped:Connect(function()
		if window.Position ~= targetPos then
			window.Position = window.Position:Lerp(targetPos, 0.2)
		end
	end)
end

-----------------------------------------------------------------
-- // THE LIBRARY // --
-----------------------------------------------------------------
local Vantix = {
	Instances = {},
	Connections = {}
}

-- Cleanup function to prevent GUI stacking during development
function Vantix:Unload()
	for _, inst in pairs(self.Instances) do
		if inst and inst.Parent then inst:Destroy() end
	end
	for _, conn in pairs(self.Connections) do
		if conn then conn:Disconnect() end
	end
	table.clear(self.Instances)
	table.clear(self.Connections)
end

function Vantix.CreateWindow(titleText)
	local Window = {Tabs = {}}

	-- GUI Setup
	local TargetGuiParent
	pcall(function() TargetGuiParent = CoreGui end)
	if not TargetGuiParent then TargetGuiParent = LocalPlayer:WaitForChild("PlayerGui", 5) end
	if not TargetGuiParent then return end

	-- Ensure clean state
	local existingGui = TargetGuiParent:FindFirstChild("VantixGui")
	if existingGui then existingGui:Destroy() end
	local existingNotif = TargetGuiParent:FindFirstChild("VantixNotifications")
	if existingNotif then existingNotif:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "VantixGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = TargetGuiParent
	table.insert(Vantix.Instances, ScreenGui)
	
	-- Notifications GUI Setup
	local NotifGui = Instance.new("ScreenGui")
	NotifGui.Name = "VantixNotifications"
	NotifGui.ResetOnSpawn = false
	NotifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	NotifGui.IgnoreGuiInset = true
	NotifGui.Parent = TargetGuiParent
	table.insert(Vantix.Instances, NotifGui)
	
	local NotifContainer = Instance.new("Frame")
	NotifContainer.Size = UDim2.new(0, 300, 1, -20)
	NotifContainer.Position = UDim2.new(1, -320, 0, 10)
	NotifContainer.BackgroundTransparency = 1
	NotifContainer.Parent = NotifGui
	
	local NotifLayout = Instance.new("UIListLayout")
	NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
	NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	NotifLayout.Padding = UDim.new(0, 10)
	NotifLayout.Parent = NotifContainer

	-- Toggle Button (Minimized State)
	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.new(0, 50, 0, 50)
	ToggleButton.Position = UDim2.new(0, 15, 0.5, -25)
	ToggleButton.BackgroundColor3 = Theme.ElementBackground
	ToggleButton.Text = "V"
	ToggleButton.TextColor3 = Theme.Text
	ToggleButton.Font = Enum.Font.GothamBold
	ToggleButton.TextSize = 20
	ToggleButton.Visible = false 
	ToggleButton.Parent = ScreenGui

	Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0) 
	local ToggleStroke = Instance.new("UIStroke", ToggleButton)
	ToggleStroke.Color = Theme.Accent
	ToggleStroke.Thickness = 2

	-- Main Window Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0, 600, 0, 400) 
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5) 
	MainFrame.BackgroundColor3 = Theme.MainBackground
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = false
	MainFrame.Parent = ScreenGui

	local WindowScale = Instance.new("UIScale", MainFrame)
	WindowScale.Scale = 1

	-- Shadow
	local Shadow = Instance.new("ImageLabel")
	Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	Shadow.Size = UDim2.new(1, 60, 1, 60) 
	Shadow.BackgroundTransparency = 1
	Shadow.Image = "rbxassetid://13169262844" 
	Shadow.ImageColor3 = Color3.new(0, 0, 0)
	Shadow.ImageTransparency = 0.4
	Shadow.ScaleType = Enum.ScaleType.Slice
	Shadow.SliceCenter = Rect.new(116, 116, 116, 116)
	Shadow.ZIndex = -1
	Shadow.Parent = MainFrame

	Instance.new("UICorner", MainFrame).CornerRadius = Theme.CornerRadius
	local MainStroke = Instance.new("UIStroke", MainFrame)
	MainStroke.Color = Theme.Stroke
	MainStroke.Thickness = 1

	-- Topbar
	local TopBar = Instance.new("TextButton")
	TopBar.Size = UDim2.new(1, 0, 0, 45)
	TopBar.BackgroundTransparency = 1
	TopBar.Text = ""
	TopBar.Parent = MainFrame

	local Logo = Instance.new("ImageLabel")
	Logo.Name = "VantixLogo"
	Logo.Size = UDim2.new(0, 24, 0, 24)
	Logo.Position = UDim2.new(0, 15, 0.5, -12)
	Logo.BackgroundTransparency = 1
	Logo.Parent = TopBar
	Window.LogoImage = Logo

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -100, 1, 0)
	Title.Position = UDim2.new(0, 50, 0, 0) 
	Title.BackgroundTransparency = 1
	Title.Text = titleText
	Title.TextColor3 = Theme.Text
	Title.TextSize = 14
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = TopBar

	local CloseButton = Instance.new("TextButton")
	CloseButton.Size = UDim2.new(0, 45, 0, 45)
	CloseButton.Position = UDim2.new(1, -45, 0, 0)
	CloseButton.BackgroundTransparency = 1
	CloseButton.Text = "—"
	CloseButton.TextColor3 = Theme.TextMuted
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.TextSize = 14
	CloseButton.Parent = TopBar

	-- Window Interactions
	CloseButton.MouseEnter:Connect(function() Tween(CloseButton, {TextColor3 = Theme.Text}, 0.2) end)
	CloseButton.MouseLeave:Connect(function() Tween(CloseButton, {TextColor3 = Theme.TextMuted}, 0.2) end)

	CloseButton.MouseButton1Click:Connect(function()
		Tween(WindowScale, {Scale = 0.9}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		Tween(MainFrame, {GroupTransparency = 1}, 0.2)
		task.wait(0.2)
		MainFrame.Visible = false
		ToggleButton.Visible = true
		Tween(ToggleButton, {Size = UDim2.new(0, 50, 0, 50)}, 0.3, Enum.EasingStyle.Back)
	end)

	ToggleButton.MouseButton1Click:Connect(function()
		Tween(ToggleButton, {Size = UDim2.new(0, 0, 0, 0)}, 0.2, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.2)
		ToggleButton.Visible = false
		MainFrame.Visible = true
		MainFrame.GroupTransparency = 1
		WindowScale.Scale = 0.9
		Tween(WindowScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		Tween(MainFrame, {GroupTransparency = 0}, 0.2)
	end)

	MakeDraggable(TopBar, MainFrame)

	-- Sidebar Elements
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 160, 1, -45) 
	Sidebar.Position = UDim2.new(0, 0, 0, 45)
	Sidebar.BackgroundColor3 = Theme.SidebarBackground
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = MainFrame
	
	Instance.new("UICorner", Sidebar).CornerRadius = Theme.CornerRadius
	
	-- Sidebar square fix (to connect to topbar and right side properly)
	local SidebarFix1 = Instance.new("Frame", Sidebar)
	SidebarFix1.Size = UDim2.new(1, 0, 0, 10)
	SidebarFix1.BackgroundColor3 = Theme.SidebarBackground
	SidebarFix1.BorderSizePixel = 0
	local SidebarFix2 = Instance.new("Frame", Sidebar)
	SidebarFix2.Size = UDim2.new(0, 10, 1, 0)
	SidebarFix2.Position = UDim2.new(1, -10, 0, 0)
	SidebarFix2.BackgroundColor3 = Theme.SidebarBackground
	SidebarFix2.BorderSizePixel = 0

	local Separator = Instance.new("Frame")
	Separator.Size = UDim2.new(0, 1, 1, 0)
	Separator.Position = UDim2.new(1, -1, 0, 0)
	Separator.BackgroundColor3 = Theme.Stroke
	Separator.BorderSizePixel = 0
	Separator.Parent = Sidebar

	local TabContainer = Instance.new("ScrollingFrame")
	TabContainer.Size = UDim2.new(1, -1, 1, 0)
	TabContainer.BackgroundTransparency = 1
	TabContainer.BorderSizePixel = 0
	TabContainer.ScrollBarThickness = 0 
	TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	TabContainer.Parent = Sidebar

	local TabListLayout = Instance.new("UIListLayout", TabContainer)
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 4)
	TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

	local SidebarPadding = Instance.new("UIPadding", TabContainer)
	SidebarPadding.PaddingTop = UDim.new(0, 10)
	SidebarPadding.PaddingBottom = UDim.new(0, 10)

	local ContentContainer = Instance.new("Frame")
	ContentContainer.Size = UDim2.new(1, -160, 1, -45) 
	ContentContainer.Position = UDim2.new(0, 160, 0, 45)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.ClipsDescendants = true 
	ContentContainer.Parent = MainFrame

	-----------------------------------------------------------------
	-- // NOTIFICATION METHOD // --
	-----------------------------------------------------------------
	function Window:Notify(title, text, duration)
		duration = duration or 3
		
		local NotifFrame = Instance.new("Frame")
		NotifFrame.Size = UDim2.new(1, 0, 0, 65)
		NotifFrame.BackgroundColor3 = Theme.ElementBackground
		NotifFrame.Position = UDim2.new(1, 20, 0, 0) -- Start offscreen right
		NotifFrame.Parent = NotifContainer
		
		Instance.new("UICorner", NotifFrame).CornerRadius = Theme.CornerRadius
		local NStroke = Instance.new("UIStroke", NotifFrame)
		NStroke.Color = Theme.Stroke
		
		local AccentLine = Instance.new("Frame")
		AccentLine.Size = UDim2.new(0, 3, 1, -16)
		AccentLine.Position = UDim2.new(0, 8, 0.5, 0)
		AccentLine.AnchorPoint = Vector2.new(0, 0.5)
		AccentLine.BackgroundColor3 = Theme.Accent
		AccentLine.BorderSizePixel = 0
		AccentLine.Parent = NotifFrame
		Instance.new("UICorner", AccentLine).CornerRadius = UDim.new(1,0)
		
		local NTitle = Instance.new("TextLabel")
		NTitle.Size = UDim2.new(1, -30, 0, 20)
		NTitle.Position = UDim2.new(0, 20, 0, 10)
		NTitle.BackgroundTransparency = 1
		NTitle.Text = title
		NTitle.TextColor3 = Theme.Text
		NTitle.Font = Enum.Font.GothamBold
		NTitle.TextSize = 13
		NTitle.TextXAlignment = Enum.TextXAlignment.Left
		NTitle.Parent = NotifFrame
		
		local NText = Instance.new("TextLabel")
		NText.Size = UDim2.new(1, -30, 1, -30)
		NText.Position = UDim2.new(0, 20, 0, 25)
		NText.BackgroundTransparency = 1
		NText.Text = text
		NText.TextColor3 = Theme.TextMuted
		NText.Font = Enum.Font.Gotham
		NText.TextSize = 12
		NText.TextXAlignment = Enum.TextXAlignment.Left
		NText.TextYAlignment = Enum.TextYAlignment.Top
		NText.TextWrapped = true
		NText.Parent = NotifFrame
		
		-- Animate In
		Tween(NotifFrame, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		
		-- Destroy after duration
		task.delay(duration, function()
			local outAnim = Tween(NotifFrame, {Position = UDim2.new(1, 20, 0, 0), GroupTransparency = 1}, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
			outAnim.Completed:Wait()
			NotifFrame:Destroy()
		end)
	end

	-----------------------------------------------------------------
	-- // TAB CREATION // --
	-----------------------------------------------------------------
	function Window.CreateTab(tabName)
		local Tab = {}
		
		local TabButton = Instance.new("TextButton")
		TabButton.Size = UDim2.new(1, -20, 0, 34)
		TabButton.BackgroundColor3 = Theme.SidebarBackground
		TabButton.Text = ""
		TabButton.AutoButtonColor = false
		TabButton.Parent = TabContainer

		Instance.new("UICorner", TabButton).CornerRadius = Theme.CornerRadius

		local TabLabel = Instance.new("TextLabel")
		TabLabel.Size = UDim2.new(1, -15, 1, 0)
		TabLabel.Position = UDim2.new(0, 15, 0, 0)
		TabLabel.BackgroundTransparency = 1
		TabLabel.Text = tabName
		TabLabel.TextColor3 = Theme.TextMuted
		TabLabel.Font = Enum.Font.GothamSemibold
		TabLabel.TextSize = 13
		TabLabel.TextXAlignment = Enum.TextXAlignment.Left
		TabLabel.Parent = TabButton

		local TabPage = Instance.new("ScrollingFrame")
		TabPage.Size = UDim2.new(1, 0, 1, 0)
		TabPage.BackgroundTransparency = 1
		TabPage.BorderSizePixel = 0
		TabPage.ScrollBarThickness = 2
		TabPage.ScrollBarImageColor3 = Theme.Stroke
		TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y 
		TabPage.Visible = false
		TabPage.Parent = ContentContainer

		local PageLayout = Instance.new("UIListLayout", TabPage)
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 8)
		PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

		local PagePadding = Instance.new("UIPadding", TabPage)
		PagePadding.PaddingTop = UDim.new(0, 15)
		PagePadding.PaddingBottom = UDim.new(0, 15)
		
		-- Tab Selection Logic
		TabButton.MouseButton1Click:Connect(function()
			for _, otherTab in pairs(Window.Tabs) do
				otherTab.Page.Visible = false
				Tween(otherTab.Button, {BackgroundColor3 = Theme.SidebarBackground}, 0.2)
				Tween(otherTab.Label, {TextColor3 = Theme.TextMuted}, 0.2)
			end
			
			TabPage.Visible = true
			TabPage.Position = UDim2.new(0, 10, 0, 0)
			TabPage.GroupTransparency = 1
			Tween(TabPage, {Position = UDim2.new(0, 0, 0, 0), GroupTransparency = 0}, 0.3)

			Tween(TabButton, {BackgroundColor3 = Theme.Accent}, 0.2)
			Tween(TabLabel, {TextColor3 = Theme.Text}, 0.2)
		end)
		
		-- Hover Effects
		TabButton.MouseEnter:Connect(function()
			if TabPage.Visible then return end
			Tween(TabButton, {BackgroundColor3 = Theme.ElementBackground}, 0.2)
			Tween(TabLabel, {TextColor3 = Theme.Text}, 0.2)
		end)
		TabButton.MouseLeave:Connect(function()
			if TabPage.Visible then return end
			Tween(TabButton, {BackgroundColor3 = Theme.SidebarBackground}, 0.2)
			Tween(TabLabel, {TextColor3 = Theme.TextMuted}, 0.2)
		end)

		-- Select first tab automatically
		if #Window.Tabs == 0 then
			TabPage.Visible = true
			TabButton.BackgroundColor3 = Theme.Accent
			TabLabel.TextColor3 = Theme.Text
		end

		table.insert(Window.Tabs, {Button = TabButton, Label = TabLabel, Page = TabPage})

		-----------------------------------------------------------------
		-- // COMPONENT: PARAGRAPH / LABEL // --
		-----------------------------------------------------------------
		function Tab.CreateLabel(titleText, descText)
			local LabelFrame = Instance.new("Frame")
			LabelFrame.Size = UDim2.new(1, -30, 0, 0)
			LabelFrame.BackgroundColor3 = Theme.MainBackground
			LabelFrame.BackgroundTransparency = 0.5
			LabelFrame.Parent = TabPage
			
			Instance.new("UICorner", LabelFrame).CornerRadius = Theme.CornerRadius
			local LStroke = Instance.new("UIStroke", LabelFrame)
			LStroke.Color = Theme.Stroke
			
			local LTitle = Instance.new("TextLabel")
			LTitle.Size = UDim2.new(1, -20, 0, 20)
			LTitle.Position = UDim2.new(0, 10, 0, 8)
			LTitle.BackgroundTransparency = 1
			LTitle.Text = titleText
			LTitle.TextColor3 = Theme.Accent
			LTitle.Font = Enum.Font.GothamBold
			LTitle.TextSize = 13
			LTitle.TextXAlignment = Enum.TextXAlignment.Left
			LTitle.Parent = LabelFrame
			
			local LDesc = Instance.new("TextLabel")
			LDesc.Size = UDim2.new(1, -20, 0, 0)
			LDesc.Position = UDim2.new(0, 10, 0, 28)
			LDesc.BackgroundTransparency = 1
			LDesc.Text = descText or ""
			LDesc.TextColor3 = Theme.TextMuted
			LDesc.Font = Enum.Font.Gotham
			LDesc.TextSize = 12
			LDesc.TextXAlignment = Enum.TextXAlignment.Left
			LDesc.TextYAlignment = Enum.TextYAlignment.Top
			LDesc.TextWrapped = true
			LDesc.AutomaticSize = Enum.AutomaticSize.Y
			LDesc.Parent = LabelFrame
			
			-- Adjust parent frame size based on text size
			task.spawn(function()
				task.wait()
				LabelFrame.Size = UDim2.new(1, -30, 0, LDesc.AbsoluteSize.Y + 40)
			end)
		end

		-----------------------------------------------------------------
		-- // COMPONENT: BUTTON // --
		-----------------------------------------------------------------
		function Tab.CreateButton(btnText, callback)
			local ButtonFrame = Instance.new("TextButton")
			ButtonFrame.Size = UDim2.new(1, -30, 0, 40)
			ButtonFrame.BackgroundColor3 = Theme.ElementBackground
			ButtonFrame.Text = btnText
			ButtonFrame.TextColor3 = Theme.Text
			ButtonFrame.Font = Enum.Font.GothamSemibold
			ButtonFrame.TextSize = 13
			ButtonFrame.AutoButtonColor = false
			ButtonFrame.Parent = TabPage

			Instance.new("UICorner", ButtonFrame).CornerRadius = Theme.CornerRadius
			local BtnStroke = Instance.new("UIStroke", ButtonFrame)
			BtnStroke.Color = Theme.Stroke
			BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

			ButtonFrame.MouseEnter:Connect(function() Tween(ButtonFrame, {BackgroundColor3 = Theme.ElementHover}, 0.2) end)
			ButtonFrame.MouseLeave:Connect(function() Tween(ButtonFrame, {BackgroundColor3 = Theme.ElementBackground}, 0.2) Tween(BtnStroke, {Color = Theme.Stroke}, 0.2) end)
			
			ButtonFrame.MouseButton1Down:Connect(function()
				Tween(ButtonFrame, {BackgroundColor3 = Theme.ElementActive}, 0.1)
				Tween(BtnStroke, {Color = Theme.Accent}, 0.1)
			end)
			
			ButtonFrame.MouseButton1Up:Connect(function()
				Tween(ButtonFrame, {BackgroundColor3 = Theme.ElementHover}, 0.1)
				Tween(BtnStroke, {Color = Theme.Stroke}, 0.1)
				if callback then task.spawn(callback) end
			end)
		end

		-----------------------------------------------------------------
		-- // COMPONENT: TOGGLE SWITCH // --
		-----------------------------------------------------------------
		function Tab.CreateToggle(toggleText, defaultState, callback)
			local toggled = defaultState or false

			local ToggleFrame = Instance.new("TextButton")
			ToggleFrame.Size = UDim2.new(1, -30, 0, 40)
			ToggleFrame.BackgroundColor3 = Theme.ElementBackground
			ToggleFrame.Text = ""
			ToggleFrame.AutoButtonColor = false
			ToggleFrame.Parent = TabPage

			Instance.new("UICorner", ToggleFrame).CornerRadius = Theme.CornerRadius
			local TglStroke = Instance.new("UIStroke", ToggleFrame)
			TglStroke.Color = Theme.Stroke

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -60, 1, 0)
			Label.Position = UDim2.new(0, 15, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = toggleText
			Label.TextColor3 = Theme.Text
			Label.Font = Enum.Font.GothamSemibold
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = ToggleFrame

			local SwitchBg = Instance.new("Frame")
			SwitchBg.Size = UDim2.new(0, 36, 0, 18)
			SwitchBg.Position = UDim2.new(1, -50, 0.5, -9)
			SwitchBg.BackgroundColor3 = toggled and Theme.Accent or Theme.MainBackground
			SwitchBg.Parent = ToggleFrame

			Instance.new("UICorner", SwitchBg).CornerRadius = UDim.new(1, 0)
			local SwitchStroke = Instance.new("UIStroke", SwitchBg)
			SwitchStroke.Color = Theme.Stroke

			local Circle = Instance.new("Frame")
			Circle.Size = UDim2.new(0, 14, 0, 14)
			Circle.Position = toggled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
			Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Circle.Parent = SwitchBg
			Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

			ToggleFrame.MouseEnter:Connect(function() Tween(ToggleFrame, {BackgroundColor3 = Theme.ElementHover}, 0.2) end)
			ToggleFrame.MouseLeave:Connect(function() Tween(ToggleFrame, {BackgroundColor3 = Theme.ElementBackground}, 0.2) end)

			local function SetState(state)
				toggled = state
				if toggled then
					Tween(SwitchBg, {BackgroundColor3 = Theme.Accent}, 0.2)
					Tween(SwitchStroke, {Color = Theme.Accent}, 0.2)
					Tween(Circle, {Position = UDim2.new(1, -16, 0.5, -7)}, 0.2, Enum.EasingStyle.Back)
				else
					Tween(SwitchBg, {BackgroundColor3 = Theme.MainBackground}, 0.2)
					Tween(SwitchStroke, {Color = Theme.Stroke}, 0.2)
					Tween(Circle, {Position = UDim2.new(0, 2, 0.5, -7)}, 0.2, Enum.EasingStyle.Back)
				end
				if callback then task.spawn(callback, toggled) end
			end

			ToggleFrame.MouseButton1Click:Connect(function()
				SetState(not toggled)
			end)
		end

		-----------------------------------------------------------------
		-- // COMPONENT: SLIDER (WITH PRECISE INPUT) // --
		-----------------------------------------------------------------
		function Tab.CreateSlider(sliderText, min, max, default, callback)
			local dragging = false
			local currentValue = default or min

			local SliderFrame = Instance.new("Frame")
			SliderFrame.Size = UDim2.new(1, -30, 0, 55)
			SliderFrame.BackgroundColor3 = Theme.ElementBackground
			SliderFrame.Parent = TabPage

			Instance.new("UICorner", SliderFrame).CornerRadius = Theme.CornerRadius
			local SldStroke = Instance.new("UIStroke", SliderFrame)
			SldStroke.Color = Theme.Stroke

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -80, 0, 25)
			Label.Position = UDim2.new(0, 15, 0, 5)
			Label.BackgroundTransparency = 1
			Label.Text = sliderText
			Label.TextColor3 = Theme.Text
			Label.Font = Enum.Font.GothamSemibold
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = SliderFrame

			local ValueBox = Instance.new("TextBox")
			ValueBox.Size = UDim2.new(0, 40, 0, 20)
			ValueBox.Position = UDim2.new(1, -55, 0, 8)
			ValueBox.BackgroundColor3 = Theme.MainBackground
			ValueBox.Text = tostring(currentValue)
			ValueBox.TextColor3 = Theme.Text
			ValueBox.Font = Enum.Font.GothamSemibold
			ValueBox.TextSize = 12
			ValueBox.Parent = SliderFrame
			
			Instance.new("UICorner", ValueBox).CornerRadius = UDim.new(0, 4)
			Instance.new("UIStroke", ValueBox).Color = Theme.Stroke

			local TrackBg = Instance.new("TextButton")
			TrackBg.Size = UDim2.new(1, -30, 0, 6)
			TrackBg.Position = UDim2.new(0, 15, 0, 38)
			TrackBg.BackgroundColor3 = Theme.MainBackground
			TrackBg.Text = ""
			TrackBg.AutoButtonColor = false
			TrackBg.Parent = SliderFrame

			Instance.new("UICorner", TrackBg).CornerRadius = UDim.new(1, 0)
			Instance.new("UIStroke", TrackBg).Color = Theme.Stroke

			local TrackFill = Instance.new("Frame")
			local startPercent = (currentValue - min) / (max - min)
			TrackFill.Size = UDim2.new(startPercent, 0, 1, 0)
			TrackFill.BackgroundColor3 = Theme.Accent
			TrackFill.Parent = TrackBg
			Instance.new("UICorner", TrackFill).CornerRadius = UDim.new(1, 0)

			local function updateSlider(value)
				currentValue = math.clamp(value, min, max)
				ValueBox.Text = tostring(currentValue)
				local percent = (currentValue - min) / (max - min)
				Tween(TrackFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
				if callback then task.spawn(callback, currentValue) end
			end

			TrackBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					local percent = math.clamp((input.Position.X - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X, 0, 1)
					updateSlider(math.floor(min + ((max - min) * percent)))
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					local percent = math.clamp((input.Position.X - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X, 0, 1)
					updateSlider(math.floor(min + ((max - min) * percent)))
				end
			end)
			
			ValueBox.FocusLost:Connect(function()
				local num = tonumber(ValueBox.Text)
				if num then updateSlider(num) else ValueBox.Text = tostring(currentValue) end
			end)
		end

		-----------------------------------------------------------------
		-- // COMPONENT: STRING INPUT // --
		-----------------------------------------------------------------
		function Tab.CreateInput(inputText, placeholder, callback)
			local InputFrame = Instance.new("Frame")
			InputFrame.Size = UDim2.new(1, -30, 0, 45)
			InputFrame.BackgroundColor3 = Theme.ElementBackground
			InputFrame.Parent = TabPage

			Instance.new("UICorner", InputFrame).CornerRadius = Theme.CornerRadius
			Instance.new("UIStroke", InputFrame).Color = Theme.Stroke

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0.4, 0, 1, 0)
			Label.Position = UDim2.new(0, 15, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = inputText
			Label.TextColor3 = Theme.Text
			Label.Font = Enum.Font.GothamSemibold
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = InputFrame

			local TextBox = Instance.new("TextBox")
			TextBox.Size = UDim2.new(0.5, -10, 0, 28)
			TextBox.Position = UDim2.new(0.5, 0, 0.5, -14)
			TextBox.BackgroundColor3 = Theme.MainBackground
			TextBox.PlaceholderText = placeholder or "Type here..."
			TextBox.Text = ""
			TextBox.TextColor3 = Theme.Text
			TextBox.Font = Enum.Font.Gotham
			TextBox.TextSize = 12
			TextBox.ClearTextOnFocus = false
			TextBox.ClipsDescendants = true
			TextBox.Parent = InputFrame

			Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)
			local BoxStroke = Instance.new("UIStroke", TextBox)
			BoxStroke.Color = Theme.Stroke

			TextBox.Focused:Connect(function() Tween(BoxStroke, {Color = Theme.Accent}, 0.2) end)
			TextBox.FocusLost:Connect(function()
				Tween(BoxStroke, {Color = Theme.Stroke}, 0.2)
				if callback then task.spawn(callback, TextBox.Text) end
			end)
		end
		
		-----------------------------------------------------------------
		-- // COMPONENT: DROPDOWN // --
		-----------------------------------------------------------------
		function Tab.CreateDropdown(title, options, default, callback)
			local expanded = false
			local currentSelection = default or options[1] or ""
			
			local DropdownFrame = Instance.new("Frame")
			DropdownFrame.Size = UDim2.new(1, -30, 0, 40)
			DropdownFrame.BackgroundColor3 = Theme.ElementBackground
			DropdownFrame.ClipsDescendants = true
			DropdownFrame.Parent = TabPage
			
			Instance.new("UICorner", DropdownFrame).CornerRadius = Theme.CornerRadius
			local DdStroke = Instance.new("UIStroke", DropdownFrame)
			DdStroke.Color = Theme.Stroke
			
			local DropdownBtn = Instance.new("TextButton")
			DropdownBtn.Size = UDim2.new(1, 0, 0, 40)
			DropdownBtn.BackgroundTransparency = 1
			DropdownBtn.Text = ""
			DropdownBtn.Parent = DropdownFrame
			
			local TitleLabel = Instance.new("TextLabel")
			TitleLabel.Size = UDim2.new(0.5, 0, 1, 0)
			TitleLabel.Position = UDim2.new(0, 15, 0, 0)
			TitleLabel.BackgroundTransparency = 1
			TitleLabel.Text = title
			TitleLabel.TextColor3 = Theme.Text
			TitleLabel.Font = Enum.Font.GothamSemibold
			TitleLabel.TextSize = 13
			TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
			TitleLabel.Parent = DropdownBtn
			
			local SelectedLabel = Instance.new("TextLabel")
			SelectedLabel.Size = UDim2.new(0.5, -35, 1, 0)
			SelectedLabel.Position = UDim2.new(0.5, 0, 0, 0)
			SelectedLabel.BackgroundTransparency = 1
			SelectedLabel.Text = currentSelection
			SelectedLabel.TextColor3 = Theme.Accent
			SelectedLabel.Font = Enum.Font.GothamSemibold
			SelectedLabel.TextSize = 12
			SelectedLabel.TextXAlignment = Enum.TextXAlignment.Right
			SelectedLabel.Parent = DropdownBtn
			
			local Icon = Instance.new("TextLabel")
			Icon.Size = UDim2.new(0, 20, 0, 20)
			Icon.Position = UDim2.new(1, -25, 0.5, -10)
			Icon.BackgroundTransparency = 1
			Icon.Text = "+"
			Icon.TextColor3 = Theme.TextMuted
			Icon.Font = Enum.Font.GothamBold
			Icon.TextSize = 16
			Icon.Parent = DropdownBtn
			
			local OptionsContainer = Instance.new("Frame")
			OptionsContainer.Size = UDim2.new(1, -20, 0, 0)
			OptionsContainer.Position = UDim2.new(0, 10, 0, 40)
			OptionsContainer.BackgroundTransparency = 1
			OptionsContainer.Parent = DropdownFrame
			
			local OptLayout = Instance.new("UIListLayout", OptionsContainer)
			OptLayout.SortOrder = Enum.SortOrder.LayoutOrder
			OptLayout.Padding = UDim.new(0, 4)
			
			local function BuildOptions()
				for _, child in ipairs(OptionsContainer:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end
				
				for i, opt in ipairs(options) do
					local OptBtn = Instance.new("TextButton")
					OptBtn.Size = UDim2.new(1, 0, 0, 30)
					OptBtn.BackgroundColor3 = Theme.MainBackground
					OptBtn.Text = "  " .. opt
					OptBtn.TextColor3 = (opt == currentSelection) and Theme.Accent or Theme.TextMuted
					OptBtn.Font = Enum.Font.Gotham
					OptBtn.TextSize = 12
					OptBtn.TextXAlignment = Enum.TextXAlignment.Left
					OptBtn.AutoButtonColor = false
					OptBtn.Parent = OptionsContainer
					
					Instance.new("UICorner", OptBtn).CornerRadius = UDim.new(0, 4)
					
					OptBtn.MouseEnter:Connect(function() Tween(OptBtn, {BackgroundColor3 = Theme.ElementHover}, 0.2) end)
					OptBtn.MouseLeave:Connect(function() Tween(OptBtn, {BackgroundColor3 = Theme.MainBackground}, 0.2) end)
					
					OptBtn.MouseButton1Click:Connect(function()
						currentSelection = opt
						SelectedLabel.Text = opt
						
						-- Close
						expanded = false
						Tween(DropdownFrame, {Size = UDim2.new(1, -30, 0, 40)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
						Tween(Icon, {Rotation = 0}, 0.3)
						
						BuildOptions() -- Rebuild to update color
						if callback then task.spawn(callback, currentSelection) end
					end)
				end
			end
			
			BuildOptions()
			
			DropdownBtn.MouseButton1Click:Connect(function()
				expanded = not expanded
				if expanded then
					local requiredHeight = 40 + (OptLayout.AbsoluteContentSize.Y) + 10
					Tween(DropdownFrame, {Size = UDim2.new(1, -30, 0, requiredHeight)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					Tween(Icon, {Rotation = 45}, 0.3)
				else
					Tween(DropdownFrame, {Size = UDim2.new(1, -30, 0, 40)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
					Tween(Icon, {Rotation = 0}, 0.3)
				end
			end)
		end
		
		-----------------------------------------------------------------
		-- // COMPONENT: KEYBIND // --
		-----------------------------------------------------------------
		function Tab.CreateKeybind(text, defaultKey, callback)
			local currentKey = defaultKey
			local isBinding = false
			
			local KeyFrame = Instance.new("Frame")
			KeyFrame.Size = UDim2.new(1, -30, 0, 40)
			KeyFrame.BackgroundColor3 = Theme.ElementBackground
			KeyFrame.Parent = TabPage
			
			Instance.new("UICorner", KeyFrame).CornerRadius = Theme.CornerRadius
			Instance.new("UIStroke", KeyFrame).Color = Theme.Stroke
			
			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(0.6, 0, 1, 0)
			Label.Position = UDim2.new(0, 15, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.TextColor3 = Theme.Text
			Label.Font = Enum.Font.GothamSemibold
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = KeyFrame
			
			local BindBtn = Instance.new("TextButton")
			BindBtn.Size = UDim2.new(0, 80, 0, 24)
			BindBtn.Position = UDim2.new(1, -95, 0.5, -12)
			BindBtn.BackgroundColor3 = Theme.MainBackground
			BindBtn.Text = currentKey and currentKey.Name or "None"
			BindBtn.TextColor3 = Theme.TextMuted
			BindBtn.Font = Enum.Font.GothamBold
			BindBtn.TextSize = 12
			BindBtn.Parent = KeyFrame
			
			Instance.new("UICorner", BindBtn).CornerRadius = UDim.new(0, 4)
			local BStroke = Instance.new("UIStroke", BindBtn)
			BStroke.Color = Theme.Stroke
			
			BindBtn.MouseButton1Click:Connect(function()
				isBinding = true
				BindBtn.Text = "..."
				Tween(BStroke, {Color = Theme.Accent}, 0.2)
			end)
			
			local inputConn
			inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
				if isBinding and input.UserInputType == Enum.UserInputType.Keyboard then
					currentKey = input.KeyCode
					BindBtn.Text = currentKey.Name
					isBinding = false
					Tween(BStroke, {Color = Theme.Stroke}, 0.2)
				elseif not isBinding and currentKey and input.KeyCode == currentKey and not gameProcessed then
					if callback then task.spawn(callback, currentKey) end
				end
			end)
			
			table.insert(Vantix.Connections, inputConn)
		end

		return Tab
	end

	return Window
end


-----------------------------------------------------------------
-- // EXAMPLE VANTIX v2 USAGE // --
-- Delete or comment this section out when using as a module
-----------------------------------------------------------------
local VantixWindow = Vantix.CreateWindow("Vantix Hub v2")

local MainTab = VantixWindow.CreateTab("Combat")
local VisualsTab = VantixWindow.CreateTab("Visuals")
local SettingsTab = VantixWindow.CreateTab("Settings")

-- Example usage of new features
MainTab.CreateLabel("Important Warning", "Aura features might flag the anti-cheat. Proceed with caution and don't use on your main account.")

MainTab.CreateToggle("Aimbot", false, function(state) 
	if state then
		VantixWindow:Notify("Aimbot Activated", "Locking onto nearest targets.", 3)
	end
end)

MainTab.CreateDropdown("Hitbox Override", {"Head", "Torso", "Random"}, "Torso", function(selection)
	print("Hitbox set to: " .. selection)
end)

VisualsTab.CreateToggle("ESP Boxes", true, function(state) print(state) end)
VisualsTab.CreateSlider("ESP Distance", 100, 2000, 500, function(val) print(val) end)

SettingsTab.CreateKeybind("Toggle GUI", Enum.KeyCode.RightShift, function()
	-- Put toggle logic here
	print("Key pressed!")
end)

SettingsTab.CreateButton("Unload UI", function()
	Vantix:Unload()
end)

-- Auto-downloader for the logo (Optional)
pcall(function()
	if isfile and writefile and getcustomasset and game.HttpGet then
		local logoFileName = "VantixLogo.png"
		local logoUrl = "https://raw.githubusercontent.com/Vantix-GUI/Vantix/21a8d4550ffebd9f90672290901183036d3ced02/Vantix-logo.png"
		if not isfile(logoFileName) then
			writefile(logoFileName, game:HttpGet(logoUrl))
		end
		VantixWindow.LogoImage.Image = getcustomasset(logoFileName)
	end
end)
