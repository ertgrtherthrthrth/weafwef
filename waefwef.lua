local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}
local Window = {}
local Tab = {}

Library.__index = Library
Window.__index = Window
Tab.__index = Tab

local TweenFast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local Themes = {
	Background = Color3.fromRGB(18, 18, 22),
	Topbar = Color3.fromRGB(24, 24, 28),
	Sidebar = Color3.fromRGB(22, 22, 26),
	Element = Color3.fromRGB(28, 28, 34),
	Accent = Color3.fromRGB(0, 140, 255),
	Text = Color3.fromRGB(245, 245, 245),
	TextDark = Color3.fromRGB(150, 150, 160),
	Border = Color3.fromRGB(36, 36, 44)
}

local function Create(className: string, properties: {[string]: any}): Instance
	local instance = Instance.new(className)
	for property, value in pairs(properties) do
		instance[property] = value
	end
	return instance
end

local function MakeDraggable(dragFrame: Frame, targetFrame: Frame)
	local dragging = false
	local dragInput, dragStart, startPos

	dragFrame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = targetFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	dragFrame.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			local delta = input.Position - dragStart
			targetFrame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function Library.CreateWindow(title: string)
	assert(typeof(title) == "string", "Window title must be a string")

	local self = setmetatable({}, Library)

	self.ScreenGui = Create("ScreenGui", {
		Name = "LuauUILibrary",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = PlayerGui
	})

	self.MainFrame = Create("Frame", {
		Name = "MainFrame",
		Size = UDim2.new(0, 525, 0, 360),
		Position = UDim2.new(0.5, -262, 0.5, -180),
		BackgroundColor3 = Themes.Background,
		BorderSizePixel = 0,
		Parent = self.ScreenGui
	})

	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.MainFrame })
	
	local stroke = Create("UIStroke", {
		Color = Themes.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = self.MainFrame
	})

	self.Topbar = Create("Frame", {
		Name = "Topbar",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Themes.Topbar,
		BorderSizePixel = 0,
		Parent = self.MainFrame
	})

	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Topbar })
	
	Create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 1, -10),
		BackgroundColor3 = Themes.Topbar,
		BorderSizePixel = 0,
		Parent = self.Topbar
	})

	local titleLabel = Create("TextLabel", {
		Size = UDim2.new(1, -40, 1, 0),
		Position = UDim2.new(0, 15, 0, 0),
		BackgroundTransparency = 1,
		Text = title,
		TextColor3 = Themes.Text,
		TextSize = 14,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = self.Topbar
	})

	self.Sidebar = Create("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 140, 1, -40),
		Position = UDim2.new(0, 0, 0, 40),
		BackgroundColor3 = Themes.Sidebar,
		BorderSizePixel = 0,
		Parent = self.MainFrame
	})

	Create("UICorner", { CornerRadius = UDim.new(0, 8), Parent = self.Sidebar })
	
	Create("Frame", {
		Size = UDim2.new(0, 10, 1, 0),
		Position = UDim2.new(1, -10, 0, 0),
		BackgroundColor3 = Themes.Sidebar,
		BorderSizePixel = 0,
		Parent = self.Sidebar
	})
	
	Create("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		Position = UDim2.new(0, 0, 0, 0),
		BackgroundColor3 = Themes.Sidebar,
		BorderSizePixel = 0,
		Parent = self.Sidebar
	})

	self.TabList = Create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, -10),
		Position = UDim2.new(0, 0, 0, 5),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		Parent = self.Sidebar
	})

	Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = self.TabList
	})

	self.Container = Create("Frame", {
		Name = "Container",
		Size = UDim2.new(1, -150, 1, -50),
		Position = UDim2.new(0, 145, 0, 45),
		BackgroundTransparency = 1,
		Parent = self.MainFrame
	})

	self.Tabs = {}
	self.ActiveTab = nil

	MakeDraggable(self.Topbar, self.MainFrame)

	return setmetatable(self, Window)
end

function Window:CreateTab(name: string)
	assert(typeof(name) == "string", "Tab name must be a string")

	local windowSelf = self
	local tabSelf = setmetatable({}, Tab)

	tabSelf.Frame = Create("ScrollingFrame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Themes.Border,
		Visible = false,
		Parent = windowSelf.Container
	})

	local listLayout = Create("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		Parent = tabSelf.Frame
	})
	
	Create("UIPadding", {
		PaddingTop = UDim.new(0, 2),
		PaddingBottom = UDim.new(0, 5),
		Parent = tabSelf.Frame
	})

	listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabSelf.Frame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end)

	tabSelf.Button = Create("TextButton", {
		Size = UDim2.new(0, 125, 0, 30),
		BackgroundColor3 = Themes.Sidebar,
		BorderSizePixel = 0,
		Text = "",
		AutoButtonColor = false,
		Parent = windowSelf.TabList
	})

	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = tabSelf.Button })
	
	local buttonStroke = Create("UIStroke", {
		Color = Themes.Border,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Transparency = 1,
		Parent = tabSelf.Button
	})

	local label = Create("TextLabel", {
		Size = UDim2.new(1, -10, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = name,
		TextColor3 = Themes.TextDark,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = tabSelf.Button
	})

	local function Select()
		if windowSelf.ActiveTab == tabSelf then return end

		if windowSelf.ActiveTab then
			local previous = windowSelf.ActiveTab
			previous.Frame.Visible = false
			TweenService:Create(previous.Button, TweenFast, {BackgroundColor3 = Themes.Sidebar}):Play()
			TweenService:Create(previous.ButtonStroke, TweenFast, {Transparency = 1}):Play()
			TweenService:Create(previous.Label, TweenFast, {TextColor3 = Themes.TextDark}):Play()
		end

		windowSelf.ActiveTab = tabSelf
		tabSelf.Frame.Visible = true
		TweenService:Create(tabSelf.Button, TweenFast, {BackgroundColor3 = Themes.Element}):Play()
		TweenService:Create(buttonStroke, TweenFast, {Transparency = 0}):Play()
		TweenService:Create(label, TweenFast, {TextColor3 = Themes.Accent}):Play()
	end

	tabSelf.Button.MouseButton1Click:Connect(Select)

	tabSelf.ButtonStroke = buttonStroke
	tabSelf.Label = label

	if #windowSelf.Tabs == 0 then
		Select()
	end

	table.insert(windowSelf.Tabs, tabSelf)
	return tabSelf
end

function Tab:CreateButton(text: string, callback: () -> ())
	assert(typeof(text) == "string", "Button text must be a string")
	assert(typeof(callback) == "function", "Button callback must be a function")

	local buttonFrame = Create("Frame", {
		Size = UDim2.new(1, -10, 0, 36),
		BackgroundColor3 = Themes.Element,
		BorderSizePixel = 0,
		Parent = self.Frame
	})

	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = buttonFrame })
	Create("UIStroke", { Color = Themes.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = buttonFrame })

	local interact = Create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = buttonFrame
	})

	local label = Create("TextLabel", {
		Size = UDim2.new(1, -20, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Themes.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = buttonFrame
	})

	interact.MouseEnter:Connect(function()
		TweenService:Create(buttonFrame, TweenFast, {BackgroundColor3 = Themes.Border}):Play()
	end)

	interact.MouseLeave:Connect(function()
		TweenService:Create(buttonFrame, TweenFast, {BackgroundColor3 = Themes.Element}):Play()
	end)

	interact.MouseButton1Down:Connect(function()
		TweenService:Create(label, TweenFast, {TextColor3 = Themes.TextDark}):Play()
	end)

	interact.MouseButton1Up:Connect(function()
		TweenService:Create(label, TweenFast, {TextColor3 = Themes.Text}):Play()
	end)

	interact.MouseButton1Click:Connect(function()
		task.spawn(callback)
	end)
end

function Tab:CreateToggle(text: string, default: boolean, callback: (boolean) -> ())
	assert(typeof(text) == "string", "Toggle text must be a string")
	assert(typeof(default) == "boolean", "Toggle default must be a boolean")
	assert(typeof(callback) == "function", "Toggle callback must be a function")

	local state = default

	local toggleFrame = Create("Frame", {
		Size = UDim2.new(1, -10, 0, 36),
		BackgroundColor3 = Themes.Element,
		BorderSizePixel = 0,
		Parent = self.Frame
	})

	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = toggleFrame })
	Create("UIStroke", { Color = Themes.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = toggleFrame })

	local interact = Create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = toggleFrame
	})

	Create("TextLabel", {
		Size = UDim2.new(1, -60, 1, 0),
		Position = UDim2.new(0, 10, 0, 0),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Themes.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = toggleFrame
	})

	local box = Create("Frame", {
		Size = UDim2.new(0, 32, 0, 18),
		Position = UDim2.new(1, -42, 0.5, -9),
		BackgroundColor3 = state and Themes.Accent or Themes.Sidebar,
		BorderSizePixel = 0,
		Parent = toggleFrame
	})

	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = box })
	local boxStroke = Create("UIStroke", { Color = Themes.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = box })

	local indicator = Create("Frame", {
		Size = UDim2.new(0, 12, 0, 12),
		Position = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6),
		BackgroundColor3 = Themes.Text,
		BorderSizePixel = 0,
		Parent = box
	})

	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = indicator })

	local function Update()
		local targetBoxColor = state and Themes.Accent or Themes.Sidebar
		local targetPos = state and UDim2.new(1, -15, 0.5, -6) or UDim2.new(0, 3, 0.5, -6)
		
		TweenService:Create(box, TweenFast, {BackgroundColor3 = targetBoxColor}):Play()
		TweenService:Create(indicator, TweenFast, {Position = targetPos}):Play()
		
		task.spawn(callback, state)
	end

	interact.MouseButton1Click:Connect(function()
		state = not state
		Update()
	end)
end

function Tab:CreateSlider(text: string, min: number, max: number, default: number, callback: (number) -> ())
	assert(typeof(text) == "string", "Slider text must be a string")
	assert(typeof(min) == "number" and typeof(max) == "number", "Slider limits must be numbers")
	assert(typeof(default) == "number", "Slider default must be a number")
	assert(typeof(callback) == "function", "Slider callback must be a function")
	assert(max > min, "Max limit must be greater than Min limit")

	local value = math.clamp(default, min, max)

	local sliderFrame = Create("Frame", {
		Size = UDim2.new(1, -10, 0, 48),
		BackgroundColor3 = Themes.Element,
		BorderSizePixel = 0,
		Parent = self.Frame
	})

	Create("UICorner", { CornerRadius = UDim.new(0, 6), Parent = sliderFrame })
	Create("UIStroke", { Color = Themes.Border, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = sliderFrame })

	Create("TextLabel", {
		Size = UDim2.new(0.7, -10, 0, 24),
		Position = UDim2.new(0, 10, 0, 2),
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Themes.Text,
		TextSize = 13,
		Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sliderFrame
	})

	local valueLabel = Create("TextLabel", {
		Size = UDim2.new(0.3, -10, 0, 24),
		Position = UDim2.new(0.7, 0, 0, 2),
		BackgroundTransparency = 1,
		Text = tostring(value),
		TextColor3 = Themes.TextDark,
		TextSize = 12,
		Font = Enum.Font.GothamMono,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = sliderFrame
	})

	local track = Create("Frame", {
		Size = UDim2.new(1, -20, 0, 5),
		Position = UDim2.new(0, 10, 0, 32),
		BackgroundColor3 = Themes.Sidebar,
		BorderSizePixel = 0,
		Parent = sliderFrame
	})

	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = track })

	local fill = Create("Frame", {
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = Themes.Accent,
		BorderSizePixel = 0,
		Parent = track
	})

	Create("UICorner", { CornerRadius = UDim.new(1, 0), Parent = fill })

	local trigger = Create("TextButton", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = sliderFrame
	})

	local active = false

	local function ProcessInput(input)
		local delta = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
		value = math.round((min + delta * (max - min)) * 100) / 100
		valueLabel.Text = tostring(value)
		TweenService:Create(fill, TweenFast, {Size = UDim2.new(delta, 0, 1, 0)}):Play()
		task.spawn(callback, value)
	end

	trigger.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			active = true
			ProcessInput(input)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			ProcessInput(input)
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			active = false
		end
	end)
end

return Library
