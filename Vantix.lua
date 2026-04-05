local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- [SAFETY CHECK] Ensure we are on the client
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer and not RunService:IsStudio() then
	warn("[Vantix] ERROR: This must be run in a LocalScript or a Client environment!")
	return
end

-----------------------------------------------------------------
-- // VANTIX THEME CONFIGURATION // --
-----------------------------------------------------------------
local Theme = {
	-- Deep Blacks
	MainBackground = Color3.fromRGB(12, 12, 14),
	SidebarBackground = Color3.fromRGB(16, 16, 18),
	ElementBackground = Color3.fromRGB(22, 22, 26),
	ElementHover = Color3.fromRGB(30, 30, 36),
	
	-- Vantix Purple (#450083)
	Accent = Color3.fromRGB(69, 0, 131), 
	
	-- Text & Details
	Text = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(150, 150, 160),
	Stroke = Color3.fromRGB(40, 40, 45),
	
	-- Leave this blank here. You can set the Image property directly later using your custom file function.
	Logo = "", 
	
	CornerRadius = UDim.new(0, 6),
	AnimSpeed = 0.25
}

-- // THE LIBRARY // --
local Vantix = {}

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

local function MakeDraggable(dragArea, mainWindow)
	local dragging, dragInput, dragStart, startPos

	dragArea.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = mainWindow.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	dragArea.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			mainWindow.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Vantix.CreateWindow(titleText)
	local Window = {Tabs = {}}

	-- [ROBUST PARENTING] Finds the safest place to put the GUI (works in Studio & Executors)
	local TargetGuiParent
	pcall(function() TargetGuiParent = game:GetService("CoreGui") end)
	if not TargetGuiParent then
		TargetGuiParent = LocalPlayer:WaitForChild("PlayerGui", 5)
	end
	
	if not TargetGuiParent then
		warn("[Vantix] ERROR: Could not find PlayerGui or CoreGui!")
		return
	end

	-- [CLEANUP] Destroy any old Vantix GUIs to prevent overlapping/invisible blocks
	local existingGui = TargetGuiParent:FindFirstChild("VantixGui")
	if existingGui then existingGui:Destroy() end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "VantixGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.Parent = TargetGuiParent

	-- Floating Toggle Button
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

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(1, 0) 
	ToggleCorner.Parent = ToggleButton

	local ToggleStroke = Instance.new("UIStroke")
	ToggleStroke.Color = Theme.Accent
	ToggleStroke.Thickness = 2
	ToggleStroke.Parent = ToggleButton

	-- Main Window Frame
	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.new(0.9, 0, 0.8, 0) 
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5) 
	MainFrame.BackgroundColor3 = Theme.MainBackground
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = ScreenGui

	local WindowScale = Instance.new("UIScale")
	WindowScale.Scale = 1
	WindowScale.Parent = MainFrame

	local Shadow = Instance.new("ImageLabel")
	Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	Shadow.Size = UDim2.new(1, 40, 1, 40) 
	Shadow.BackgroundTransparency = 1
	Shadow.Image = "rbxassetid://13169262844" 
	Shadow.ImageColor3 = Color3.new(0, 0, 0)
	Shadow.ImageTransparency = 0.5
	Shadow.ScaleType = Enum.ScaleType.Slice
	Shadow.SliceCenter = Rect.new(116, 116, 116, 116)
	Shadow.ZIndex = -1
	Shadow.Parent = MainFrame

	local SizeConstraint = Instance.new("UISizeConstraint")
	SizeConstraint.MaxSize = Vector2.new(650, 420)
	SizeConstraint.Parent = MainFrame

	local MainCorner = Instance.new("UICorner")
	MainCorner.CornerRadius = Theme.CornerRadius
	MainCorner.Parent = MainFrame
	
	local MainStroke = Instance.new("UIStroke")
	MainStroke.Color = Theme.Stroke
	MainStroke.Thickness = 1
	MainStroke.Parent = MainFrame

	-- Top Bar
	local TopBar = Instance.new("TextButton")
	TopBar.Size = UDim2.new(1, 0, 0, 45)
	TopBar.BackgroundTransparency = 1
	TopBar.Text = ""
	TopBar.Parent = MainFrame

	-- Vantix Logo
	local Logo = Instance.new("ImageLabel")
	Logo.Name = "VantixLogo"
	Logo.Size = UDim2.new(0, 26, 0, 26)
	Logo.Position = UDim2.new(0, 15, 0.5, -13)
	Logo.BackgroundTransparency = 1
	Logo.Parent = TopBar
	
	-- Expose the Logo so you can safely set it using your custom file function later
	Window.LogoImage = Logo 

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -100, 1, 0)
	Title.Position = UDim2.new(0, 50, 0, 0) 
	Title.BackgroundTransparency = 1
	Title.Text = titleText
	Title.TextColor3 = Theme.Text
	Title.TextSize = 16
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = TopBar

	local CloseButton = Instance.new("TextButton")
	CloseButton.Size = UDim2.new(0, 45, 0, 45)
	CloseButton.Position = UDim2.new(1, -45, 0, 0)
	CloseButton.BackgroundTransparency = 1
	CloseButton.Text = "X"
	CloseButton.TextColor3 = Theme.TextMuted
	CloseButton.Font = Enum.Font.GothamBold
	CloseButton.TextSize = 16
	CloseButton.Parent = TopBar

	CloseButton.MouseEnter:Connect(function() Tween(CloseButton, {TextColor3 = Color3.fromRGB(255, 70, 70)}, 0.2) end)
	CloseButton.MouseLeave:Connect(function() Tween(CloseButton, {TextColor3 = Theme.TextMuted}, 0.2) end)

	CloseButton.MouseButton1Click:Connect(function()
		Tween(WindowScale, {Scale = 0}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In)
		task.wait(0.3)
		MainFrame.Visible = false
		ToggleButton.Visible = true
	end)

	ToggleButton.MouseButton1Click:Connect(function()
		ToggleButton.Visible = false
		MainFrame.Visible = true
		WindowScale.Scale = 0
		Tween(WindowScale, {Scale = 1}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	MakeDraggable(TopBar, MainFrame)

	-- Sidebar
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0.3, 0, 1, -45) 
	Sidebar.Position = UDim2.new(0, 0, 0, 45)
	Sidebar.BackgroundColor3 = Theme.SidebarBackground
	Sidebar.BorderSizePixel = 0
	Sidebar.Parent = MainFrame

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

	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 6)
	TabListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	TabListLayout.Parent = TabContainer

	local SidebarPadding = Instance.new("UIPadding")
	SidebarPadding.PaddingTop = UDim.new(0, 10)
	SidebarPadding.Parent = TabContainer

	-- Content Container
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Size = UDim2.new(0.7, 0, 1, -45) 
	ContentContainer.Position = UDim2.new(0.3, 0, 0, 45)
	ContentContainer.BackgroundTransparency = 1
	ContentContainer.ClipsDescendants = true 
	ContentContainer.Parent = MainFrame

	-- // WINDOW METHODS // --
	function Window.CreateTab(tabName, iconId)
		local Tab = {}
		
		local TabButton = Instance.new("TextButton")
		TabButton.Size = UDim2.new(1, -20, 0, 36)
		TabButton.BackgroundColor3 = Theme.SidebarBackground
		TabButton.Text = ""
		TabButton.AutoButtonColor = false
		TabButton.Parent = TabContainer

		local TabBtnCorner = Instance.new("UICorner")
		TabBtnCorner.CornerRadius = Theme.CornerRadius
		TabBtnCorner.Parent = TabButton

		local TextOffset = 15
		if iconId then
			local Icon = Instance.new("ImageLabel")
			Icon.Size = UDim2.new(0, 18, 0, 18)
			Icon.Position = UDim2.new(0, 10, 0.5, -9)
			Icon.BackgroundTransparency = 1
			Icon.Image = iconId
			Icon.ImageColor3 = Theme.TextMuted
			Icon.Parent = TabButton
			TextOffset = 35 
		end

		local TabLabel = Instance.new("TextLabel")
		TabLabel.Size = UDim2.new(1, -TextOffset, 1, 0)
		TabLabel.Position = UDim2.new(0, TextOffset, 0, 0)
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
		TabPage.ScrollBarImageColor3 = Theme.Accent
		TabPage.AutomaticCanvasSize = Enum.AutomaticSize.Y 
		TabPage.Visible = false
		TabPage.Parent = ContentContainer

		local PageLayout = Instance.new("UIListLayout")
		PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
		PageLayout.Padding = UDim.new(0, 8)
		PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		PageLayout.Parent = TabPage

		local PagePadding = Instance.new("UIPadding")
		PagePadding.PaddingTop = UDim.new(0, 15)
		PagePadding.PaddingBottom = UDim.new(0, 15)
		PagePadding.Parent = TabPage

		TabButton.MouseButton1Click:Connect(function()
			for _, otherTab in pairs(Window.Tabs) do
				otherTab.Page.Visible = false
				Tween(otherTab.Button, {BackgroundColor3 = Theme.SidebarBackground}, 0.3)
				Tween(otherTab.Label, {TextColor3 = Theme.TextMuted}, 0.3)
				if otherTab.Button:FindFirstChild("ImageLabel") then
					Tween(otherTab.Button.ImageLabel, {ImageColor3 = Theme.TextMuted}, 0.3)
				end
			end
			
			TabPage.Visible = true
			TabPage.Position = UDim2.new(0, 15, 0, 0)
			Tween(TabPage, {Position = UDim2.new(0, 0, 0, 0)}, 0.3)

			Tween(TabButton, {BackgroundColor3 = Theme.Accent}, 0.3)
			Tween(TabLabel, {TextColor3 = Theme.Text}, 0.3)
			if TabButton:FindFirstChild("ImageLabel") then
				Tween(TabButton.ImageLabel, {ImageColor3 = Theme.Text}, 0.3)
			end
		end)

		if #Window.Tabs == 0 then
			TabPage.Visible = true
			TabButton.BackgroundColor3 = Theme.Accent
			TabLabel.TextColor3 = Theme.Text
			if TabButton:FindFirstChild("ImageLabel") then TabButton.ImageLabel.ImageColor3 = Theme.Text end
		end

		table.insert(Window.Tabs, {Button = TabButton, Label = TabLabel, Page = TabPage})

		-- // COMPONENT: BUTTON // --
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

			local BtnCorner = Instance.new("UICorner")
			BtnCorner.CornerRadius = Theme.CornerRadius
			BtnCorner.Parent = ButtonFrame
			
			local BtnStroke = Instance.new("UIStroke")
			BtnStroke.Color = Theme.Stroke
			BtnStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			BtnStroke.Parent = ButtonFrame

			ButtonFrame.MouseEnter:Connect(function() Tween(ButtonFrame, {BackgroundColor3 = Theme.ElementHover}, 0.2) end)
			ButtonFrame.MouseLeave:Connect(function() Tween(ButtonFrame, {BackgroundColor3 = Theme.ElementBackground}, 0.2) end)
			ButtonFrame.MouseButton1Click:Connect(function()
				if callback then task.spawn(callback) end
			end)
		end

		-- // COMPONENT: TOGGLE SWITCH // --
		function Tab.CreateToggle(toggleText, defaultState, callback)
			local toggled = defaultState or false

			local ToggleFrame = Instance.new("TextButton")
			ToggleFrame.Size = UDim2.new(1, -30, 0, 40)
			ToggleFrame.BackgroundColor3 = Theme.ElementBackground
			ToggleFrame.Text = ""
			ToggleFrame.AutoButtonColor = false
			ToggleFrame.Parent = TabPage

			local TglCorner = Instance.new("UICorner")
			TglCorner.CornerRadius = Theme.CornerRadius
			TglCorner.Parent = ToggleFrame
			
			local TglStroke = Instance.new("UIStroke")
			TglStroke.Color = Theme.Stroke
			TglStroke.Parent = ToggleFrame

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
			SwitchBg.Size = UDim2.new(0, 40, 0, 20)
			SwitchBg.Position = UDim2.new(1, -55, 0.5, -10)
			SwitchBg.BackgroundColor3 = toggled and Theme.Accent or Theme.Stroke
			SwitchBg.Parent = ToggleFrame

			local SwitchCorner = Instance.new("UICorner")
			SwitchCorner.CornerRadius = UDim.new(1, 0)
			SwitchCorner.Parent = SwitchBg

			local Circle = Instance.new("Frame")
			Circle.Size = UDim2.new(0, 16, 0, 16)
			Circle.Position = toggled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
			Circle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			Circle.Parent = SwitchBg

			local CircleCorner = Instance.new("UICorner")
			CircleCorner.CornerRadius = UDim.new(1, 0)
			CircleCorner.Parent = Circle

			ToggleFrame.MouseEnter:Connect(function() Tween(ToggleFrame, {BackgroundColor3 = Theme.ElementHover}, 0.2) end)
			ToggleFrame.MouseLeave:Connect(function() Tween(ToggleFrame, {BackgroundColor3 = Theme.ElementBackground}, 0.2) end)

			ToggleFrame.MouseButton1Click:Connect(function()
				toggled = not toggled
				if toggled then
					Tween(SwitchBg, {BackgroundColor3 = Theme.Accent}, 0.2)
					Tween(Circle, {Position = UDim2.new(1, -18, 0.5, -8)}, 0.2, Enum.EasingStyle.Back)
				else
					Tween(SwitchBg, {BackgroundColor3 = Theme.Stroke}, 0.2)
					Tween(Circle, {Position = UDim2.new(0, 2, 0.5, -8)}, 0.2, Enum.EasingStyle.Back)
				end
				if callback then task.spawn(callback, toggled) end
			end)
		end

		-- // COMPONENT: SLIDER // --
		function Tab.CreateSlider(sliderText, min, max, default, callback)
			local dragging = false
			local currentValue = default or min

			local SliderFrame = Instance.new("Frame")
			SliderFrame.Size = UDim2.new(1, -30, 0, 55)
			SliderFrame.BackgroundColor3 = Theme.ElementBackground
			SliderFrame.Parent = TabPage

			local SldCorner = Instance.new("UICorner")
			SldCorner.CornerRadius = Theme.CornerRadius
			SldCorner.Parent = SliderFrame
			
			local SldStroke = Instance.new("UIStroke")
			SldStroke.Color = Theme.Stroke
			SldStroke.Parent = SliderFrame

			local Label = Instance.new("TextLabel")
			Label.Size = UDim2.new(1, -30, 0, 25)
			Label.Position = UDim2.new(0, 15, 0, 5)
			Label.BackgroundTransparency = 1
			Label.Text = sliderText
			Label.TextColor3 = Theme.Text
			Label.Font = Enum.Font.GothamSemibold
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Parent = SliderFrame

			local ValueLabel = Instance.new("TextLabel")
			ValueLabel.Size = UDim2.new(0, 50, 0, 25)
			ValueLabel.Position = UDim2.new(1, -65, 0, 5)
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.Text = tostring(currentValue)
			ValueLabel.TextColor3 = Theme.TextMuted
			ValueLabel.Font = Enum.Font.GothamSemibold
			ValueLabel.TextSize = 13
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValueLabel.Parent = SliderFrame

			local TrackBg = Instance.new("TextButton")
			TrackBg.Size = UDim2.new(1, -30, 0, 6)
			TrackBg.Position = UDim2.new(0, 15, 0, 35)
			TrackBg.BackgroundColor3 = Theme.MainBackground
			TrackBg.Text = ""
			TrackBg.AutoButtonColor = false
			TrackBg.Parent = SliderFrame

			local TrackCorner = Instance.new("UICorner")
			TrackCorner.CornerRadius = UDim.new(1, 0)
			TrackCorner.Parent = TrackBg

			local TrackFill = Instance.new("Frame")
			local startPercent = (currentValue - min) / (max - min)
			TrackFill.Size = UDim2.new(startPercent, 0, 1, 0)
			TrackFill.BackgroundColor3 = Theme.Accent
			TrackFill.Parent = TrackBg

			local FillCorner = Instance.new("UICorner")
			FillCorner.CornerRadius = UDim.new(1, 0)
			FillCorner.Parent = TrackFill

			local function updateSlider(input)
				local percent = math.clamp((input.Position.X - TrackBg.AbsolutePosition.X) / TrackBg.AbsoluteSize.X, 0, 1)
				currentValue = math.floor(min + ((max - min) * percent))
				ValueLabel.Text = tostring(currentValue)
				Tween(TrackFill, {Size = UDim2.new(percent, 0, 1, 0)}, 0.1)
				if callback then task.spawn(callback, currentValue) end
			end

			TrackBg.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateSlider(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateSlider(input)
				end
			end)
		end

		-- // COMPONENT: STRING INPUT // --
		function Tab.CreateInput(inputText, placeholder, callback)
			local InputFrame = Instance.new("Frame")
			InputFrame.Size = UDim2.new(1, -30, 0, 45)
			InputFrame.BackgroundColor3 = Theme.ElementBackground
			InputFrame.Parent = TabPage

			local InpCorner = Instance.new("UICorner")
			InpCorner.CornerRadius = Theme.CornerRadius
			InpCorner.Parent = InputFrame
			
			local InpStroke = Instance.new("UIStroke")
			InpStroke.Color = Theme.Stroke
			InpStroke.Parent = InputFrame

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
			TextBox.Size = UDim2.new(0.5, -10, 0, 25)
			TextBox.Position = UDim2.new(0.5, 0, 0.5, -12.5)
			TextBox.BackgroundColor3 = Theme.MainBackground
			TextBox.PlaceholderText = placeholder or "Type here..."
			TextBox.Text = ""
			TextBox.TextColor3 = Theme.Text
			TextBox.Font = Enum.Font.Gotham
			TextBox.TextSize = 12
			TextBox.ClearTextOnFocu
