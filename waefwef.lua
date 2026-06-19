local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local TweenFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenSmooth = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Themes = {
	Dark = {
		Background = Color3.fromRGB(15, 15, 18),
		Container = Color3.fromRGB(22, 22, 26),
		Element = Color3.fromRGB(28, 28, 33),
		ElementHover = Color3.fromRGB(35, 35, 41),
		Accent = Color3.fromRGB(130, 100, 255),
		Text = Color3.fromRGB(240, 240, 245),
		TextDim = Color3.fromRGB(140, 140, 150),
		Border = Color3.fromRGB(40, 40, 48),
		Shadow = Color3.fromRGB(0, 0, 0)
	}
}

local CurrentTheme = Themes.Dark

local GlobalInput = {
	ActiveDrag = nil,
	ActiveSlider = nil,
	ActiveColorSV = nil,
	ActiveColorHue = nil
}

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if GlobalInput.ActiveDrag then GlobalInput.ActiveDrag(input) end
		if GlobalInput.ActiveSlider then GlobalInput.ActiveSlider(input) end
		if GlobalInput.ActiveColorSV then GlobalInput.ActiveColorSV(input) end
		if GlobalInput.ActiveColorHue then GlobalInput.ActiveColorHue(input) end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		GlobalInput.ActiveDrag = nil
		GlobalInput.ActiveSlider = nil
		GlobalInput.ActiveColorSV = nil
		GlobalInput.ActiveColorHue = nil
	end
end)

local function Validate(value, expectedType, fallback)
	if type(value) == expectedType then return value end
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
	local tween = TweenService:Create(instance, tweenInfo or TweenFast, properties)
	tween:Play()
	return tween
end

local function Round(value, decimals)
	local mult = 10 ^ (decimals or 1)
	return math.floor(value * mult + 0.5) / mult
end

local Library = {
	Windows = {},
	Connections = {}
}

function Library:SetTheme(themeData)
	CurrentTheme = themeData
end

function Library:Notify(config)
	local title = Validate(config.Title, "string", "Notification")
	local content = Validate(config.Content, "string", "")
	local duration = Validate(config.Duration, "number", 3)

	local screenGui = CoreGui:FindFirstChild("UI_Notifications_V3")
	if not screenGui then
		screenGui = Create("ScreenGui", {
			Name = "UI_Notifications_V3",
			Parent = CoreGui,
			ZIndexBehavior = Enum.ZIndexBehavior.Global
		})
	end

	local notifyFrame = Create("Frame", {
		Name = "NotifyFrame",
		Parent = screenGui,
		BackgroundColor3 = CurrentTheme.Container,
		Position = UDim2.new(1, 20, 1, -100),
		Size = UDim2.new(0, 270, 0, 85),
		AnchorPoint = Vector2.new(1, 1),
		ClipsDescendants = true,
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 }),
		Create("Frame", {
			BackgroundColor3 = CurrentTheme.Accent,
			Size = UDim2.new(0, 4, 1, 0),
			Create("UICorner", { CornerRadius = UDim.new(0, 6) })
		})
	})

	Create("TextLabel", {
		Parent = notifyFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 10),
		Size = UDim2.new(1, -30, 0, 20),
		Font = Enum.Font.GothamBold,
		Text = title,
		TextColor3 = CurrentTheme.Text,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	Create("TextLabel", {
		Parent = notifyFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 35),
		Size = UDim2.new(1, -30, 0, 40),
		Font = Enum.Font.Gotham,
		Text = content,
		TextColor3 = CurrentTheme.TextDim,
		TextSize = 13,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top
	})

	local targetPos = UDim2.new(1, -20, 1, -20)
	for _, child in ipairs(screenGui:GetChildren()) do
		if child ~= notifyFrame then
			ApplyTween(child, { Position = child.Position - UDim2.new(0, 0, 0, 95) }, TweenSmooth)
		end
	end

	ApplyTween(notifyFrame, { Position = targetPos }, TweenSmooth)

	task.delay(duration, function()
		local tween = ApplyTween(notifyFrame, { Position = notifyFrame.Position + UDim2.new(0, 300, 0, 0), BackgroundTransparency = 1 }, TweenSmooth)
		tween.Completed:Connect(function() notifyFrame:Destroy() end)
	end)
end

function Library:CreateWindow(config)
	local windowTitle = Validate(config.Title, "string", "Window")
	local windowSize = Validate(config.Size, "UDim2", UDim2.new(0, 650, 0, 480))

	local windowObj = {
		Tabs = {},
		CurrentTab = nil,
		Connections = {},
		Instances = {}
	}

	local screenGui = Create("ScreenGui", {
		Name = "UI_Framework_" .. windowTitle,
		Parent = CoreGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		ResetOnSpawn = false
	})
	
	table.insert(Library.Windows, windowObj)
	table.insert(windowObj.Instances, screenGui)

	local mainFrame = Create("Frame", {
		Name = "MainFrame",
		Parent = screenGui,
		BackgroundColor3 = CurrentTheme.Background,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = windowSize,
		AnchorPoint = Vector2.new(0.5, 0.5),
		ClipsDescendants = true,
		Create("UICorner", { CornerRadius = UDim.new(0, 8) }),
		Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
	})

	local topbar = Create("Frame", {
		Name = "Topbar",
		Parent = mainFrame,
		BackgroundColor3 = CurrentTheme.Container,
		Size = UDim2.new(1, 0, 0, 45),
		Create("UICorner", { CornerRadius = UDim.new(0, 8) })
	})

	Create("Frame", {
		Parent = topbar,
		BackgroundColor3 = CurrentTheme.Container,
		Position = UDim2.new(0, 0, 1, -8),
		Size = UDim2.new(1, 0, 0, 8),
		BorderSizePixel = 0
	})

	Create("Frame", {
		Parent = topbar,
		BackgroundColor3 = CurrentTheme.Border,
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BorderSizePixel = 0
	})

	Create("TextLabel", {
		Parent = topbar,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 20, 0, 0),
		Size = UDim2.new(1, -40, 1, 0),
		Font = Enum.Font.GothamBold,
		Text = windowTitle,
		TextColor3 = CurrentTheme.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left
	})

	local dragStartPos, dragInputPos
	table.insert(windowObj.Connections, topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStartPos = mainFrame.Position
			dragInputPos = input.Position
			GlobalInput.ActiveDrag = function(dragInput)
				local delta = dragInput.Position - dragInputPos
				ApplyTween(mainFrame, {
					Position = UDim2.new(
						dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X, 
						dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
					)
				}, TweenInfo.new(0.05, Enum.EasingStyle.Linear))
			end
		end
	end))

	local tabContainer = Create("ScrollingFrame", {
		Name = "TabContainer",
		Parent = mainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 60),
		Size = UDim2.new(0, 150, 1, -75),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) })
	})

	local contentContainer = Create("Frame", {
		Name = "ContentContainer",
		Parent = mainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 180, 0, 60),
		Size = UDim2.new(1, -195, 1, -75)
	})

	table.insert(windowObj.Connections, tabContainer.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		tabContainer.CanvasSize = UDim2.new(0, 0, 0, tabContainer.UIListLayout.AbsoluteContentSize.Y)
	end))

	function windowObj:CreateTab(tabConfig)
		local tabName = Validate(tabConfig.Name, "string", "Tab")
		local tabObj = { Elements = {}, Instances = {}, Connections = {} }

		local tabButton = Create("TextButton", {
			Parent = tabContainer,
			BackgroundColor3 = CurrentTheme.Element,
			Size = UDim2.new(1, 0, 0, 36),
			Font = Enum.Font.GothamSemibold,
			Text = tabName,
			TextColor3 = CurrentTheme.TextDim,
			TextSize = 13,
			AutoButtonColor = false,
			Create("UICorner", { CornerRadius = UDim.new(0, 6) })
		})

		local tabContent = Create("ScrollingFrame", {
			Parent = contentContainer,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = CurrentTheme.Border,
			Visible = false,
			Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }),
			Create("UIPadding", { PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10) })
		})

		table.insert(tabObj.Instances, tabButton)
		table.insert(tabObj.Instances, tabContent)
		table.insert(tabObj.Connections, tabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContent.UIListLayout.AbsoluteContentSize.Y + 10)
		end))

		local function ActivateTab()
			if windowObj.CurrentTab then
				windowObj.CurrentTab.Content.Visible = false
				ApplyTween(windowObj.CurrentTab.Button, { BackgroundColor3 = CurrentTheme.Element, TextColor3 = CurrentTheme.TextDim }, TweenFast)
			end
			windowObj.CurrentTab = { Button = tabButton, Content = tabContent }
			tabContent.Visible = true
			ApplyTween(tabButton, { BackgroundColor3 = CurrentTheme.Accent, TextColor3 = CurrentTheme.Text }, TweenFast)
		end

		table.insert(tabObj.Connections, tabButton.MouseButton1Click:Connect(ActivateTab))
		if not windowObj.CurrentTab then ActivateTab() end

		local function RegisterElement(elementObj, instance)
			table.insert(tabObj.Elements, elementObj)
			table.insert(tabObj.Instances, instance)
			function elementObj:SetVisible(state) instance.Visible = Validate(state, "boolean", true) end
			function elementObj:Destroy() if instance and instance.Parent then instance:Destroy() end end
		end

		function tabObj:CreateSection(secConfig)
			local secName = Validate(secConfig.Name, "string", "Section")
			local sectionFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30)
			})
			Create("TextLabel", {
				Parent = sectionFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 5, 0, 0),
				Size = UDim2.new(1, -10, 1, -5),
				Font = Enum.Font.GothamBold,
				Text = secName,
				TextColor3 = CurrentTheme.Accent,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Bottom
			})
			Create("Frame", {
				Parent = sectionFrame,
				BackgroundColor3 = CurrentTheme.Border,
				Position = UDim2.new(0, 5, 1, -2),
				Size = UDim2.new(1, -10, 0, 1),
				BorderSizePixel = 0
			})
			local sectionObj = {}
			RegisterElement(sectionObj, sectionFrame)
			return sectionObj
		end

		function tabObj:CreateLabel(lblConfig)
			local text = Validate(lblConfig.Text, "string", "Label")
			local labelFrame = Create("TextLabel", {
				Parent = tabContent,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = CurrentTheme.TextDim,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true
			})
			local labelObj = {}
			function labelObj:SetText(newText) labelFrame.Text = tostring(newText) end
			RegisterElement(labelObj, labelFrame)
			return labelObj
		end

		function tabObj:CreateParagraph(paraConfig)
			local title = Validate(paraConfig.Title, "string", "Paragraph")
			local content = Validate(paraConfig.Content, "string", "Content")
			local paraFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 60),
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})
			local titleLbl = Create("TextLabel", {
				Parent = paraFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 10),
				Size = UDim2.new(1, -30, 0, 15),
				Font = Enum.Font.GothamBold,
				Text = title,
				TextColor3 = CurrentTheme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})
			local contentLbl = Create("TextLabel", {
				Parent = paraFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 30),
				Size = UDim2.new(1, -30, 1, -40),
				Font = Enum.Font.Gotham,
				Text = content,
				TextColor3 = CurrentTheme.TextDim,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true
			})
			local paraObj = {}
			function paraObj:SetTitle(newTitle) titleLbl.Text = tostring(newTitle) end
			function paraObj:SetContent(newContent) contentLbl.Text = tostring(newContent) end
			RegisterElement(paraObj, paraFrame)
			return paraObj
		end

		function tabObj:CreateButton(btnConfig)
			local btnName = Validate(btnConfig.Name, "string", "Button")
			local callback = Validate(btnConfig.Callback, "function", function() end)
			local buttonObj = {}
			local lastClick = 0

			local buttonFrame = Create("TextButton", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 38),
				Font = Enum.Font.Gotham,
				Text = btnName,
				TextColor3 = CurrentTheme.Text,
				TextSize = 14,
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			table.insert(tabObj.Connections, buttonFrame.MouseEnter:Connect(function() ApplyTween(buttonFrame, { BackgroundColor3 = CurrentTheme.ElementHover }, TweenFast) end))
			table.insert(tabObj.Connections, buttonFrame.MouseLeave:Connect(function() ApplyTween(buttonFrame, { BackgroundColor3 = CurrentTheme.Element }, TweenFast) end))
			table.insert(tabObj.Connections, buttonFrame.MouseButton1Click:Connect(function()
				if tick() - lastClick < 0.2 then return end
				lastClick = tick()
				ApplyTween(buttonFrame, { BackgroundColor3 = CurrentTheme.Accent }, TweenInfo.new(0.1))
				task.delay(0.1, function() ApplyTween(buttonFrame, { BackgroundColor3 = CurrentTheme.ElementHover }, TweenFast) end)
				callback()
			end))

			RegisterElement(buttonObj, buttonFrame)
			return buttonObj
		end

		function tabObj:CreateToggle(tglConfig)
			local tglName = Validate(tglConfig.Name, "string", "Toggle")
			local default = Validate(tglConfig.Default, "boolean", false)
			local callback = Validate(tglConfig.Callback, "function", function() end)

			local toggleObj = {}
			local state = default

			local toggleFrame = Create("TextButton", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 38),
				Text = "",
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			Create("TextLabel", {
				Parent = toggleFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 0),
				Size = UDim2.new(1, -70, 1, 0),
				Font = Enum.Font.Gotham,
				Text = tglName,
				TextColor3 = CurrentTheme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local indicatorBG = Create("Frame", {
				Parent = toggleFrame,
				BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.Background,
				Position = UDim2.new(1, -50, 0.5, -10),
				Size = UDim2.new(0, 36, 0, 20),
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			local indicatorCircle = Create("Frame", {
				Parent = indicatorBG,
				BackgroundColor3 = CurrentTheme.Text,
				Position = UDim2.new(0, state and 18 or 2, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Create("UIStroke", { Color = CurrentTheme.Shadow, Transparency = 0.8, Thickness = 1 })
			})

			local function UpdateState(newState, skipCallback)
				state = newState
				ApplyTween(indicatorBG, { BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.Background }, TweenFast)
				ApplyTween(indicatorCircle, { Position = UDim2.new(0, state and 18 or 2, 0.5, -8) }, TweenFast)
				if not skipCallback then callback(state) end
			end

			table.insert(tabObj.Connections, toggleFrame.MouseButton1Click:Connect(function() UpdateState(not state, false) end))

			function toggleObj:SetValue(val) UpdateState(Validate(val, "boolean", false), false) end
			function toggleObj:GetValue() return state end

			RegisterElement(toggleObj, toggleFrame)
			return toggleObj
		end

		function tabObj:CreateSlider(sldConfig)
			local sldName = Validate(sldConfig.Name, "string", "Slider")
			local min = Validate(sldConfig.Min, "number", 0)
			local max = Validate(sldConfig.Max, "number", 100)
			local decimals = Validate(sldConfig.Decimals, "number", 1)
			local default = Validate(sldConfig.Default, "number", min)
			local callback = Validate(sldConfig.Callback, "function", function() end)

			local sliderObj = {}
			local currentValue = math.clamp(default, min, max)

			local sliderFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 55),
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			Create("TextLabel", {
				Parent = sliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 8),
				Size = UDim2.new(1, -30, 0, 20),
				Font = Enum.Font.Gotham,
				Text = sldName,
				TextColor3 = CurrentTheme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local valueLabel = Create("TextLabel", {
				Parent = sliderFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 8),
				Size = UDim2.new(1, -30, 0, 20),
				Font = Enum.Font.Gotham,
				Text = tostring(currentValue),
				TextColor3 = CurrentTheme.TextDim,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right
			})

			local sliderBG = Create("TextButton", {
				Parent = sliderFrame,
				BackgroundColor3 = CurrentTheme.Background,
				Position = UDim2.new(0, 15, 0, 36),
				Size = UDim2.new(1, -30, 0, 6),
				Text = "",
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(1, 0) })
			})

			local sliderFill = Create("Frame", {
				Parent = sliderBG,
				BackgroundColor3 = CurrentTheme.Accent,
				Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0),
				Create("UICorner", { CornerRadius = UDim.new(1, 0) })
			})

			local function UpdateSliderValue(input)
				local absoluteX = math.clamp(input.Position.X - sliderBG.AbsolutePosition.X, 0, sliderBG.AbsoluteSize.X)
				local percentage = absoluteX / sliderBG.AbsoluteSize.X
				local rawValue = min + ((max - min) * percentage)
				currentValue = Round(rawValue, decimals)
				local finalPct = (currentValue - min) / (max - min)
				ApplyTween(sliderFill, { Size = UDim2.new(finalPct, 0, 1, 0) }, TweenInfo.new(0.05, Enum.EasingStyle.Linear))
				valueLabel.Text = tostring(currentValue)
				callback(currentValue)
			end

			table.insert(tabObj.Connections, sliderBG.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					GlobalInput.ActiveSlider = UpdateSliderValue
					UpdateSliderValue(input)
				end
			end))

			function sliderObj:SetValue(val)
				val = math.clamp(Validate(val, "number", min), min, max)
				currentValue = Round(val, decimals)
				local pct = (currentValue - min) / (max - min)
				ApplyTween(sliderFill, { Size = UDim2.new(pct, 0, 1, 0) }, TweenFast)
				valueLabel.Text = tostring(currentValue)
				callback(currentValue)
			end

			function sliderObj:GetValue() return currentValue end

			RegisterElement(sliderObj, sliderFrame)
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
			local optionInstances = {}

			local dropdownFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 38),
				ClipsDescendants = true,
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			local headerBtn = Create("TextButton", {
				Parent = dropdownFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 38),
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
				TextColor3 = CurrentTheme.Text,
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
				TextColor3 = CurrentTheme.Accent,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right
			})

			local indicator = Create("TextLabel", {
				Parent = headerBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -25, 0, 0),
				Size = UDim2.new(0, 15, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "v",
				TextColor3 = CurrentTheme.TextDim,
				TextSize = 12
			})

			local listContainer = Create("ScrollingFrame", {
				Parent = dropdownFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 38),
				Size = UDim2.new(1, 0, 1, -38),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = CurrentTheme.Border,
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder })
			})

			local listLayout = listContainer.UIListLayout
			table.insert(tabObj.Connections, listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
			end))

			local function BuildOptions(newOptions)
				for _, inst in ipairs(optionInstances) do inst:Destroy() end
				table.clear(optionInstances)
				options = newOptions

				for _, opt in ipairs(options) do
					local optBtn = Create("TextButton", {
						Parent = listContainer,
						BackgroundColor3 = CurrentTheme.Background,
						Size = UDim2.new(1, 0, 0, 32),
						Font = Enum.Font.Gotham,
						Text = "  " .. opt,
						TextColor3 = (opt == currentOption) and CurrentTheme.Accent or CurrentTheme.TextDim,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutoButtonColor = false
					})
					table.insert(optionInstances, optBtn)

					table.insert(tabObj.Connections, optBtn.MouseEnter:Connect(function() ApplyTween(optBtn, { BackgroundColor3 = CurrentTheme.ElementHover }, TweenFast) end))
					table.insert(tabObj.Connections, optBtn.MouseLeave:Connect(function() ApplyTween(optBtn, { BackgroundColor3 = CurrentTheme.Background }, TweenFast) end))
					table.insert(tabObj.Connections, optBtn.MouseButton1Click:Connect(function()
						currentOption = opt
						valueLabel.Text = opt
						callback(opt)
						for _, btn in ipairs(optionInstances) do
							local txt = string.sub(btn.Text, 3)
							ApplyTween(btn, { TextColor3 = (txt == currentOption) and CurrentTheme.Accent or CurrentTheme.TextDim }, TweenFast)
						end
						isOpen = false
						ApplyTween(dropdownFrame, { Size = UDim2.new(1, 0, 0, 38) }, TweenFast)
						ApplyTween(indicator, { Rotation = 0 }, TweenFast)
					end))
				end
			end

			BuildOptions(options)

			table.insert(tabObj.Connections, headerBtn.MouseButton1Click:Connect(function()
				isOpen = not isOpen
				ApplyTween(indicator, { Rotation = isOpen and 180 or 0 }, TweenFast)
				local targetHeight = isOpen and math.clamp(38 + listLayout.AbsoluteContentSize.Y, 38, 160) or 38
				ApplyTween(dropdownFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, TweenFast)
			end))

			function dropdownObj:SetOptions(newOptions)
				BuildOptions(Validate(newOptions, "table", {}))
				if isOpen then
					local targetHeight = math.clamp(38 + listLayout.AbsoluteContentSize.Y, 38, 160)
					ApplyTween(dropdownFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, TweenFast)
				end
			end

			function dropdownObj:SetValue(val)
				val = Validate(val, "string", "")
				if table.find(options, val) then
					currentOption = val
					valueLabel.Text = val
					callback(val)
					for _, btn in ipairs(optionInstances) do
						local txt = string.sub(btn.Text, 3)
						ApplyTween(btn, { TextColor3 = (txt == currentOption) and CurrentTheme.Accent or CurrentTheme.TextDim }, TweenFast)
					end
				end
			end

			function dropdownObj:GetValue() return currentOption end

			RegisterElement(dropdownObj, dropdownFrame)
			return dropdownObj
		end

		function tabObj:CreateMultiDropdown(dpdConfig)
			local dpdName = Validate(dpdConfig.Name, "string", "Multi-Dropdown")
			local options = Validate(dpdConfig.Options, "table", {})
			local default = Validate(dpdConfig.Default, "table", {})
			local callback = Validate(dpdConfig.Callback, "function", function() end)

			local dropdownObj = {}
			local isOpen = false
			local currentOptions = default
			local optionInstances = {}

			local dropdownFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 38),
				ClipsDescendants = true,
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			local headerBtn = Create("TextButton", {
				Parent = dropdownFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 38),
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
				TextColor3 = CurrentTheme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local valueLabel = Create("TextLabel", {
				Parent = headerBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 0),
				Size = UDim2.new(1, -45, 1, 0),
				Font = Enum.Font.Gotham,
				Text = #currentOptions > 0 and table.concat(currentOptions, ", ") or "None",
				TextColor3 = CurrentTheme.Accent,
				TextSize = 13,
				TextXAlignment = Enum.TextXAlignment.Right,
				TextTruncate = Enum.TextTruncate.AtEnd
			})

			local indicator = Create("TextLabel", {
				Parent = headerBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -25, 0, 0),
				Size = UDim2.new(0, 15, 1, 0),
				Font = Enum.Font.GothamBold,
				Text = "v",
				TextColor3 = CurrentTheme.TextDim,
				TextSize = 12
			})

			local listContainer = Create("ScrollingFrame", {
				Parent = dropdownFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 38),
				Size = UDim2.new(1, 0, 1, -38),
				CanvasSize = UDim2.new(0, 0, 0, 0),
				ScrollBarThickness = 2,
				ScrollBarImageColor3 = CurrentTheme.Border,
				Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder })
			})

			local listLayout = listContainer.UIListLayout
			table.insert(tabObj.Connections, listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				listContainer.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y)
			end))

			local function BuildOptions(newOptions)
				for _, inst in ipairs(optionInstances) do inst:Destroy() end
				table.clear(optionInstances)
				options = newOptions

				for _, opt in ipairs(options) do
					local isSelected = table.find(currentOptions, opt) ~= nil
					local optBtn = Create("TextButton", {
						Parent = listContainer,
						BackgroundColor3 = CurrentTheme.Background,
						Size = UDim2.new(1, 0, 0, 32),
						Font = Enum.Font.Gotham,
						Text = "  " .. opt,
						TextColor3 = isSelected and CurrentTheme.Accent or CurrentTheme.TextDim,
						TextSize = 13,
						TextXAlignment = Enum.TextXAlignment.Left,
						AutoButtonColor = false
					})
					table.insert(optionInstances, optBtn)

					table.insert(tabObj.Connections, optBtn.MouseEnter:Connect(function() ApplyTween(optBtn, { BackgroundColor3 = CurrentTheme.ElementHover }, TweenFast) end))
					table.insert(tabObj.Connections, optBtn.MouseLeave:Connect(function() ApplyTween(optBtn, { BackgroundColor3 = CurrentTheme.Background }, TweenFast) end))
					table.insert(tabObj.Connections, optBtn.MouseButton1Click:Connect(function()
						local idx = table.find(currentOptions, opt)
						if idx then table.remove(currentOptions, idx) else table.insert(currentOptions, opt) end
						valueLabel.Text = #currentOptions > 0 and table.concat(currentOptions, ", ") or "None"
						callback(currentOptions)
						
						local txt = string.sub(optBtn.Text, 3)
						local nowSelected = table.find(currentOptions, txt) ~= nil
						ApplyTween(optBtn, { TextColor3 = nowSelected and CurrentTheme.Accent or CurrentTheme.TextDim }, TweenFast)
					end))
				end
			end

			BuildOptions(options)

			table.insert(tabObj.Connections, headerBtn.MouseButton1Click:Connect(function()
				isOpen = not isOpen
				ApplyTween(indicator, { Rotation = isOpen and 180 or 0 }, TweenFast)
				local targetHeight = isOpen and math.clamp(38 + listLayout.AbsoluteContentSize.Y, 38, 160) or 38
				ApplyTween(dropdownFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, TweenFast)
			end))

			function dropdownObj:SetOptions(newOptions)
				BuildOptions(Validate(newOptions, "table", {}))
				if isOpen then
					local targetHeight = math.clamp(38 + listLayout.AbsoluteContentSize.Y, 38, 160)
					ApplyTween(dropdownFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, TweenFast)
				end
			end

			function dropdownObj:SetValue(valTable)
				currentOptions = Validate(valTable, "table", {})
				valueLabel.Text = #currentOptions > 0 and table.concat(currentOptions, ", ") or "None"
				callback(currentOptions)
				for _, btn in ipairs(optionInstances) do
					local txt = string.sub(btn.Text, 3)
					local nowSelected = table.find(currentOptions, txt) ~= nil
					ApplyTween(btn, { TextColor3 = nowSelected and CurrentTheme.Accent or CurrentTheme.TextDim }, TweenFast)
				end
			end

			function dropdownObj:GetValue() return currentOptions end

			RegisterElement(dropdownObj, dropdownFrame)
			return dropdownObj
		end

		function tabObj:CreateInput(inpConfig)
			local inpName = Validate(inpConfig.Name, "string", "Input")
			local placeholder = Validate(inpConfig.Placeholder, "string", "Enter text...")
			local clearOnFocus = Validate(inpConfig.ClearOnFocus, "boolean", true)
			local callback = Validate(inpConfig.Callback, "function", function() end)

			local inputObj = {}

			local inputFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 38),
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			Create("TextLabel", {
				Parent = inputFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 0),
				Size = UDim2.new(0.5, -15, 1, 0),
				Font = Enum.Font.Gotham,
				Text = inpName,
				TextColor3 = CurrentTheme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local textBox = Create("TextBox", {
				Parent = inputFrame,
				BackgroundColor3 = CurrentTheme.Background,
				Position = UDim2.new(0.5, 0, 0.5, -12),
				Size = UDim2.new(0.5, -10, 0, 24),
				Font = Enum.Font.Gotham,
				Text = "",
				PlaceholderText = placeholder,
				PlaceholderColor3 = CurrentTheme.TextDim,
				TextColor3 = CurrentTheme.Text,
				TextSize = 13,
				ClearTextOnFocus = clearOnFocus,
				Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			table.insert(tabObj.Connections, textBox.FocusLost:Connect(function() callback(textBox.Text) end))

			function inputObj:SetValue(val)
				textBox.Text = tostring(val)
				callback(textBox.Text)
			end
			function inputObj:GetValue() return textBox.Text end

			RegisterElement(inputObj, inputFrame)
			return inputObj
		end

		function tabObj:CreateKeybind(kbConfig)
			local kbName = Validate(kbConfig.Name, "string", "Keybind")
			local default = Validate(kbConfig.Default, "EnumItem", Enum.KeyCode.Unknown)
			local callback = Validate(kbConfig.Callback, "function", function() end)

			local keybindObj = {}
			local currentKey = default
			local isBinding = false

			local keybindFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 38),
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			Create("TextLabel", {
				Parent = keybindFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 0),
				Size = UDim2.new(1, -70, 1, 0),
				Font = Enum.Font.Gotham,
				Text = kbName,
				TextColor3 = CurrentTheme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local bindBtn = Create("TextButton", {
				Parent = keybindFrame,
				BackgroundColor3 = CurrentTheme.Background,
				Position = UDim2.new(1, -85, 0.5, -12),
				Size = UDim2.new(0, 75, 0, 24),
				Font = Enum.Font.Gotham,
				Text = currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name,
				TextColor3 = CurrentTheme.TextDim,
				TextSize = 13,
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			table.insert(tabObj.Connections, bindBtn.MouseButton1Click:Connect(function()
				isBinding = true
				bindBtn.Text = "..."
				ApplyTween(bindBtn, { TextColor3 = CurrentTheme.Accent }, TweenFast)
			end))

			table.insert(tabObj.Connections, UserInputService.InputBegan:Connect(function(input, gpe)
				if isBinding and input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
						currentKey = Enum.KeyCode.Unknown
						bindBtn.Text = "None"
					else
						currentKey = input.KeyCode
						bindBtn.Text = currentKey.Name
					end
					isBinding = false
					ApplyTween(bindBtn, { TextColor3 = CurrentTheme.TextDim }, TweenFast)
				elseif not isBinding and input.KeyCode == currentKey and not gpe then
					callback(currentKey)
				end
			end))

			function keybindObj:SetValue(key)
				currentKey = Validate(key, "EnumItem", Enum.KeyCode.Unknown)
				bindBtn.Text = currentKey == Enum.KeyCode.Unknown and "None" or currentKey.Name
			end
			function keybindObj:GetValue() return currentKey end

			RegisterElement(keybindObj, keybindFrame)
			return keybindObj
		end

		function tabObj:CreateColorPicker(cpConfig)
			local cpName = Validate(cpConfig.Name, "string", "ColorPicker")
			local default = Validate(cpConfig.Default, "Color3", Color3.fromRGB(255, 255, 255))
			local callback = Validate(cpConfig.Callback, "function", function() end)

			local cpObj = {}
			local h, s, v = default:ToHSV()
			local isOpen = false

			local cpFrame = Create("Frame", {
				Parent = tabContent,
				BackgroundColor3 = CurrentTheme.Element,
				Size = UDim2.new(1, 0, 0, 38),
				ClipsDescendants = true,
				Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			local headerBtn = Create("TextButton", {
				Parent = cpFrame,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 38),
				Text = ""
			})

			Create("TextLabel", {
				Parent = headerBtn,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 15, 0, 0),
				Size = UDim2.new(1, -60, 1, 0),
				Font = Enum.Font.Gotham,
				Text = cpName,
				TextColor3 = CurrentTheme.Text,
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left
			})

			local displayColor = Create("Frame", {
				Parent = headerBtn,
				BackgroundColor3 = default,
				Position = UDim2.new(1, -40, 0.5, -10),
				Size = UDim2.new(0, 25, 0, 20),
				Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
			})

			local pickerArea = Create("Frame", {
				Parent = cpFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 38),
				Size = UDim2.new(1, 0, 1, -38)
			})

			local svBox = Create("TextButton", {
				Parent = pickerArea,
				BackgroundColor3 = Color3.fromHSV(h, 1, 1),
				Position = UDim2.new(0, 15, 0, 10),
				Size = UDim2.new(1, -55, 0, 100),
				Text = "",
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(0, 4) })
			})

			Create("Frame", {
				Parent = svBox,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Size = UDim2.new(1, 0, 1, 0),
				Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Create("UIGradient", { Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)}) })
			})

			Create("Frame", {
				Parent = svBox,
				BackgroundColor3 = Color3.new(0, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Create("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)}) })
			})

			local svCursor = Create("Frame", {
				Parent = svBox,
				BackgroundColor3 = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(s, 0, 1 - v, 0),
				Size = UDim2.new(0, 8, 0, 8),
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 })
			})

			local hueBox = Create("TextButton", {
				Parent = pickerArea,
				BackgroundColor3 = Color3.new(1, 1, 1),
				Position = UDim2.new(1, -30, 0, 10),
				Size = UDim2.new(0, 15, 0, 100),
				Text = "",
				AutoButtonColor = false,
				Create("UICorner", { CornerRadius = UDim.new(0, 4) }),
				Create("UIGradient", {
					Rotation = 90,
					Color = ColorSequence.new({
						ColorSequenceKeypoint.new(0, Color3.new(1, 0, 0)),
						ColorSequenceKeypoint.new(0.166, Color3.new(1, 1, 0)),
						ColorSequenceKeypoint.new(0.333, Color3.new(0, 1, 0)),
						ColorSequenceKeypoint.new(0.5, Color3.new(0, 1, 1)),
						ColorSequenceKeypoint.new(0.666, Color3.new(0, 0, 1)),
						ColorSequenceKeypoint.new(0.833, Color3.new(1, 0, 1)),
						ColorSequenceKeypoint.new(1, Color3.new(1, 0, 0))
					})
				})
			})

			local hueCursor = Create("Frame", {
				Parent = hueBox,
				BackgroundColor3 = Color3.new(1, 1, 1),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, h, 0),
				Size = UDim2.new(1, 4, 0, 4),
				Create("UICorner", { CornerRadius = UDim.new(0, 2) }),
				Create("UIStroke", { Color = Color3.new(0, 0, 0), Thickness = 1 })
			})

			local function UpdateColor()
				local finalColor = Color3.fromHSV(h, s, v)
				svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				displayColor.BackgroundColor3 = finalColor
				callback(finalColor)
			end

			local function UpdateSV(input)
				local absoluteX = math.clamp(input.Position.X - svBox.AbsolutePosition.X, 0, svBox.AbsoluteSize.X)
				local absoluteY = math.clamp(input.Position.Y - svBox.AbsolutePosition.Y, 0, svBox.AbsoluteSize.Y)
				s = absoluteX / svBox.AbsoluteSize.X
				v = 1 - (absoluteY / svBox.AbsoluteSize.Y)
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				UpdateColor()
			end

			local function UpdateHue(input)
				local absoluteY = math.clamp(input.Position.Y - hueBox.AbsolutePosition.Y, 0, hueBox.AbsoluteSize.Y)
				h = absoluteY / hueBox.AbsoluteSize.Y
				hueCursor.Position = UDim2.new(0.5, 0, h, 0)
				UpdateColor()
			end

			table.insert(tabObj.Connections, svBox.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					GlobalInput.ActiveColorSV = UpdateSV
					UpdateSV(input)
				end
			end))

			table.insert(tabObj.Connections, hueBox.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					GlobalInput.ActiveColorHue = UpdateHue
					UpdateHue(input)
				end
			end))

			table.insert(tabObj.Connections, headerBtn.MouseButton1Click:Connect(function()
				isOpen = not isOpen
				ApplyTween(cpFrame, { Size = UDim2.new(1, 0, 0, isOpen and 158 or 38) }, TweenFast)
			end))

			function cpObj:SetValue(col)
				col = Validate(col, "Color3", Color3.new(1, 1, 1))
				h, s, v = col:ToHSV()
				svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
				hueCursor.Position = UDim2.new(0.5, 0, h, 0)
				UpdateColor()
			end

			function cpObj:GetValue() return Color3.fromHSV(h, s, v) end

			RegisterElement(cpObj, cpFrame)
			return cpObj
		end

		return tabObj
	end

	function windowObj:Destroy()
		for _, inst in ipairs(windowObj.Instances) do
			if inst and inst.Parent then inst:Destroy() end
		end
		for _, conn in ipairs(windowObj.Connections) do
			if conn then conn:Disconnect() end
		end
		for _, tab in pairs(windowObj.Tabs) do
			for _, conn in ipairs(tab.Connections) do
				if conn then conn:Disconnect() end
			end
		end
		local idx = table.find(Library.Windows, windowObj)
		if idx then table.remove(Library.Windows, idx) end
		table.clear(windowObj)
	end

	return windowObj
end

function Library:Unload()
	for _, window in ipairs(table.clone(self.Windows)) do
		window:Destroy()
	end
	local notifs = CoreGui:FindFirstChild("UI_Notifications_V3")
	if notifs then notifs:Destroy() end
	table.clear(self.Windows)
end

return Library
