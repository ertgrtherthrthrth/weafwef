local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local TweenInfoFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenInfoSmooth = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Theme = {
	Background = Color3.fromRGB(20, 20, 20),
	Container = Color3.fromRGB(30, 30, 30),
	Element = Color3.fromRGB(40, 40, 40),
	ElementHover = Color3.fromRGB(50, 50, 50),
	Accent = Color3.fromRGB(90, 140, 255),
	Text = Color3.fromRGB(240, 240, 240),
	TextDim = Color3.fromRGB(160, 160, 160),
	Border = Color3.fromRGB(55, 55, 55),
	Shadow = Color3.fromRGB(0, 0, 0)
}

local function Validate(value, expectedType, fallback)
	if type(value) == expectedType then
		return value
	end
	return fallback
end

local function Create(className, properties)
	local instance = Instance.new(className)
	for key, value in pairs(properties or {}) do
		if type(key) == "number" then
			value.Parent = instance
		else
			instance[key] = value
		end
	end
	return instance
end

local function ApplyTween(instance, properties, tweenInfo)
	local tween = TweenService:Create(instance, tweenInfo or TweenInfoFast, properties)
	tween:Play()
	return tween
end

local function MakeDraggable(topbar, window)
	local dragging = false
	local dragInput = nil
	local dragStart = nil
	local startPos = nil

	local function Update(input)
		local delta = input.Position - dragStart
		ApplyTween(window, {
			Position = UDim2.new(
				startPos.X.Scale, 
				startPos.X.Offset + delta.X, 
				startPos.Y.Scale, 
				startPos.Y.Offset + delta.Y
			)
		}, TweenInfoFast)
	end

	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = window.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
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
			Update(input)
		end
	end)
end

local Library = {
	Instances = {},
	Connections = {}
}

function Library:Notify(config)
	local title = Validate(config.Title, "string", "Notification")
	local content = Validate(config.Content, "string", "")
	local duration = Validate(config.Duration, "number", 3)

	local screenGui = Create("ScreenGui", {
		Name = "UI_Notification",
		Parent = CoreGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Global
	})

	table.insert(self.Instances, screenGui)

	local notifyFrame = Create("Frame", {
		Name = "NotifyFrame",
		Parent = screenGui,
		BackgroundColor3 = Theme.Container,
		Position = UDim2.new(1, 10, 1, -100),
		Size = UDim2.new(0, 250, 0, 80),
		AnchorPoint = Vector2.new(1, 1),
		ClipsDescendants = true,
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("UIStroke", { Color = Theme.Border, Thickness = 1 })
	})

	Create("TextLabel", {
		Parent = notifyFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 10),
		Size = UDim2.new(1, -30, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = Theme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	Create("TextLabel", {
		Parent = notifyFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 35),
		Size = UDim2.new(1, -30, 0, 35),
		Font = Enum.Font.Gotham,
		Text = content,
		TextColor3 = Theme.TextDim,
		TextSize = 12,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top
	})

	ApplyTween(notifyFrame, { Position = UDim2.new(1, -20, 1, -20) }, TweenInfoSmooth)

	task.delay(duration, function()
		local tween = ApplyTween(notifyFrame, { Position = UDim2.new(1, 300, 1, -20) }, TweenInfoSmooth)
		tween.Completed:Connect(function()
			screenGui:Destroy()
		end)
	end)
end

function Library:CreateWindow(config)
	local windowTitle = Validate(config.Title, "string", "Window")
	local windowSize = Validate(config.Size, "UDim2", UDim2.new(0, 500, 0, 350))

	local windowObj = {
		Tabs = {},
		CurrentTab = nil,
		Connections = {},
		Instances = {}
	}

	local screenGui = Create("ScreenGui", {
		Name = "UI_Library",
		Parent = CoreGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		ResetOnSpawn = false
	})
	
	table.insert(self.Instances, screenGui)
	table.insert(windowObj.Instances, screenGui)

	local mainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = screenGui,
		BackgroundColor3 = Theme.Background,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = windowSize,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
		Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Create("UIStroke", { Color = Theme.Border, Thickness = 1 })
	})

	local topbar = Create("Frame", {
		Name = "Topbar",
		Parent = mainFrame,
		BackgroundColor3 = Theme.Container,
		Size = UDim2.new(1, 0, 0, 40),
		Create("UICorner", { CornerRadius = UDim.new(0, 8) })
	})

	Create("Frame", {
		Parent = topbar,
		BackgroundColor3 = Theme.Container,
		Position = UDim2.new(0, 0, 1, -4),
		Size = UDim2.new(1, 0, 0, 4),
		BorderSizePixel = 0
	})

	Create("Frame", {
		Parent = topbar,
		BackgroundColor3 = Theme.Border,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0
	})

	Create("TextLabel", {
		Parent = topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 0),
		Size = UDim2.new(1, -30, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = windowTitle,
		TextColor3 = Theme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	MakeDraggable(topbar, mainFrame)

	local tabContainer = Create("ScrollingFrame", {
		Name = "TabContainer",
		Parent = mainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 50),
		Size = UDim2.new(0, 130, 1, -60),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 5)
		})
	})

	local contentContainer = Create("Frame", {
		Name = "ContentContainer",
		Parent = mainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 150, 0, 50),
		Size = UDim2.new(1, -160, 1, -60)
	})

	function windowObj:CreateTab(tabConfig)
		local tabName = Validate(tabConfig.Name, "string", "Tab")
		local tabObj = { Elements = {} }

		local tabButton = Create("TextButton", {
			Parent = tabContainer,
			BackgroundColor3 = Theme.Element,
			Size = UDim2.new(1, 0, 0, 30),
			Font = Enum.Font.GothamSemibold,
			Text = tabName,
			TextColor3 = Theme.TextDim,
			TextSize = 14,
			AutoButtonColor = false,
			Create("UICorner", { CornerRadius = UDim.new(0, 6) })
		})

		local tabContent = Create("ScrollingFrame", {
			Parent = contentContainer,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Border,
			Visible = false,
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8)
			}),
			Create("UIPadding", {
				PaddingRight = UDim.new(0, 10)
			})
		})

		tabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContent.UIListLayout.AbsoluteContentSize.Y)
		end)

		local function ActivateTab()
			if windowObj.CurrentTab then
				windowObj.CurrentTab.Content.Visible = false
				ApplyTween(windowObj.CurrentTab.Button, { BackgroundColor3 = Theme.Element, TextColor3 = Theme.TextDim }, TweenInfoFast)
			end
			windowObj.CurrentTab = { Button = tabButton, Content = tabContent }
			tabContent.Visible = true
			ApplyTween(tabButton, { BackgroundColor3 = Theme.Accent, TextColor3 = Theme.Text }, TweenInfoFast)
		end

		tabButton.MouseButton1Click:Connect(ActivateTab)

		if not windowObj.CurrentTab then
			ActivateTab()
		end

		function tabObj:CreateButton(btnConfig)
			local btnName = Validate(btnConfig.Name, "string", "Button")
			local callback = Validate(btnConfig.Callback, "function", function() end)

			local button = Create("TextButton", {
				Parent = tabContent,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, 35),
				Font = Enum.Font.Gotham,
				Text = btnName,
				TextColor3 = Theme.Text,
				TextSize = 14,
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = Theme.Border, Thickness = 1 })
			})

			button.MouseEnter:Connect(function() ApplyTween(button, { BackgroundColor3 = Theme.ElementHover }, TweenInfoFast) end)
			button.MouseLeave:Connect(function() ApplyTween(button, { BackgroundColor3 = Theme.Element }, TweenInfoFast) end)
			
			button.MouseButton1Click:Connect(function()
				ApplyTween(button, { BackgroundColor3 = Theme.Accent }, TweenInfoFast)
				task.wait(0.1)
				ApplyTween(button, { BackgroundColor3 = Theme.ElementHover }, TweenInfoFast)
				callback()
			end)
		end

		function tabObj:CreateToggle(tglConfig)
			local tglName = Validate(tglConfig.Name, "string", "Toggle")
			local default = Validate(tglConfig.Default, "boolean", false)
			local callback = Validate(tglConfig.Callback, "function", function() end)

			local state = default
			local toggleObj = {}

			local toggleFrame = Create("TextButton", {
				Parent = tabContent,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, 35),
				Text = "",
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = Theme.Border, Thickness = 1 })
			})

			Create("TextLabel", {
				Parent = toggleFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 0),
				Size = UDim2.new(1, -60, 1, 0),
				Font = Enum.Font.Gotham,
				Text = tglName,
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local indicatorBG = Create("Frame", {
				Parent = toggleFrame,
				BackgroundColor3 = state and Theme.Accent or Theme.Background,
				Position = UDim2.new(1, -45, 0.5, -10),
				Size = UDim2.new(0, 36, 0, 20),
				Create("UICorner", { CornerRadius = UDim.new(1, 0) })
			})

			local indicatorCircle = Create("Frame", {
				Parent = indicatorBG,
				BackgroundColor3 = Theme.Text,
				Position = UDim2.new(0, state and 18 or 2, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Create("UIStroke", { Color = Theme.Shadow, Transparency = 0.8, Thickness = 1 })
			})

			local function UpdateState(newState)
				state = newState
				ApplyTween(indicatorBG, { BackgroundColor3 = state and Theme.Accent or Theme.Background }, TweenInfoFast)
				ApplyTween(indicatorCircle, { Position = UDim2.new(0, state and 18 or 2, 0.5, -8) }, TweenInfoFast)
				callback(state)
			end

			toggleFrame.MouseButton1Click:Connect(function()
				UpdateState(not state)
			end)

			function toggleObj:SetValue(val)
				UpdateState(Validate(val, "boolean", false))
			end

			return toggleObj
		end

		function tabObj:CreateSlider(sldConfig)
			local sldName = Validate(sldConfig.Name, "string", "Slider")
			local min = Validate(sldConfig.Min, "number", 0)
			local max = Validate(sldConfig.Max, "number", 100)
			local default = Validate(sldConfig.Default, "number", min)
			local callback = Validate(sldConfig.Callback, "function", function() end)

			local sliderObj = {}
			local currentValue = math.clamp(default, min, max)

			local sliderFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, 50),
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = Theme.Border, Thickness = 1 })
			})

			Create("TextLabel", {
				Parent = sliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 5),
				Size = UDim2.new(1, -30, 0, 20),
				Font = Enum.Font.Gotham,
				Text = sldName,
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local valueLabel = Create("TextLabel", {
				Parent = sliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 5),
				Size = UDim2.new(1, -30, 0, 20),
				Font = Enum.Font.Gotham,
				Text = tostring(currentValue),
				TextColor3 = Theme.TextDim,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right
			})

			local sliderBG = Create("TextButton", {
				Parent = sliderFrame,
				BackgroundColor3 = Theme.Background,
				Position = UDim2.new(0, 15, 0, 30),
				Size = UDim2.new(1, -30, 0, 6),
				Text = "",
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(1, 0) })
			})

			local sliderFill = Create("Frame", {
				Parent = sliderBG,
				BackgroundColor3 = Theme.Accent,
				Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0),
				Create("UICorner", { CornerRadius = UDim.new(1, 0) })
			})

			local dragging = false

			local function UpdateSlider(input)
				local percentage = math.clamp((input.Position.X - sliderBG.AbsolutePosition.X) / sliderBG.AbsoluteSize.X, 0, 1)
				local rawValue = min + ((max - min) * percentage)
				currentValue = math.floor(rawValue * 10) / 10
				
				ApplyTween(sliderFill, { Size = UDim2.new(percentage, 0, 1, 0) }, TweenInfoFast)
				valueLabel.Text = tostring(currentValue)
				callback(currentValue)
			end

			sliderBG.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					UpdateSlider(input)
				end
			end)

			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					UpdateSlider(input)
				end
			end)

			function sliderObj:SetValue(val)
				val = math.clamp(Validate(val, "number", min), min, max)
				currentValue = val
				local pct = (val - min) / (max - min)
				ApplyTween(sliderFill, { Size = UDim2.new(pct, 0, 1, 0) }, TweenInfoFast)
				valueLabel.Text = tostring(currentValue)
				callback(currentValue)
			end

			return sliderObj
		end

		function tabObj:CreateDropdown(dpdConfig)
			local dpdName = Validate(dpdConfig.Name, "string", "Dropdown")
			local options = Validate(dpdConfig.Options, "table", {})
			local default = Validate(dpdConfig.Default, "string", "")
			local callback = Validate(dpdConfig.Callback, "function", function() end)

			local dropdownObj = {}
			local isOpen = false
			local currentOption = default

			local dropdownFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = Theme.Element,
				Size = UDim2.new(1, 0, 0, 35),
				ClipsDescendants = true,
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = Theme.Border, Thickness = 1 })
			})

			local headerBtn = Create("TextButton", {
				Parent = dropdownFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 35),
				Text = "",
				ZIndex = 2
			})

			Create("TextLabel", {
				Parent = headerBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 0),
				Size = UDim2.new(1, -30, 1, 0),
				Font = Enum.Font.Gotham,
				Text = dpdName,
				TextColor3 = Theme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local valueLabel = Create("TextLabel", {
				Parent = headerBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 0),
				Size = UDim2.new(1, -45, 1, 0),
				Font = Enum.Font.Gotham,
				Text = currentOption,
				TextColor3 = Theme.Accent,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right
			})

			local indicator = Create("TextLabel", {
				Parent = headerBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -25, 0, 0),
				Size = UDim2.new(0, 15, 1, 0),
				Font = Enum.Font.Gotham,
				Text = "+",
				TextColor3 = Theme.TextDim,
				TextSize = 16
			})

			local listContainer = Create("Frame", {
				Parent = dropdownFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 35),
				Size = UDim2.new(1, 0, 1, -35),
				Create("UIListLayout", {
					SortOrder = Enum.SortOrder.LayoutOrder
				})
			})

			local function RenderOptions()
				for _, child in pairs(listContainer:GetChildren()) do
					if child:IsA("TextButton") then child:Destroy() end
				end

				for _, opt in ipairs(options) do
					local optBtn = Create("TextButton", {
						Parent = listContainer,
						BackgroundColor3 = Theme.Background,
						Size = UDim2.new(1, 0, 0, 30),
						Font = Enum.Font.Gotham,
						Text = "  " .. opt,
						TextColor3 = (opt == currentOption) and Theme.Accent or Theme.TextDim,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutoButtonColor = false
					})

					optBtn.MouseButton1Click:Connect(function()
						currentOption = opt
						valueLabel.Text = opt
						callback(opt)
						RenderOptions()
						isOpen = false
						ApplyTween(dropdownFrame, { Size = UDim2.new(1, 0, 0, 35) }, TweenInfoFast)
						indicator.Text = "+"
					end)
				end
			end

			RenderOptions()

			headerBtn.MouseButton1Click:Connect(function()
				isOpen = not isOpen
				indicator.Text = isOpen and "-" or "+"
				local targetHeight = isOpen and (35 + (#options * 30)) or 35
				ApplyTween(dropdownFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, TweenInfoFast)
			end)

			function dropdownObj:SetValue(val)
				val = Validate(val, "string", "")
				if table.find(options, val) then
					currentOption = val
					valueLabel.Text = val
					RenderOptions()
					callback(val)
				end
			end

			return dropdownObj
		end

		return tabObj
	end

	function windowObj:Destroy()
		for _, instance in ipairs(windowObj.Instances) do
			if instance and instance.Parent then
				instance:Destroy()
			end
		end
		for _, conn in ipairs(windowObj.Connections) do
			if conn then conn:Disconnect() end
		end
		table.clear(windowObj)
	end

	return windowObj
end

return Library
