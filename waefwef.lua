local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local TweenFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TweenSmooth = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local Themes = {
	Dark = {
		Background = Color3.fromRGB(18, 18, 22),
		Container = Color3.fromRGB(24, 24, 29),
		Element = Color3.fromRGB(32, 32, 38),
		ElementHover = Color3.fromRGB(40, 40, 48),
		Accent = Color3.fromRGB(110, 150, 255),
		Text = Color3.fromRGB(245, 245, 250),
		TextDim = Color3.fromRGB(150, 150, 160),
		Border = Color3.fromRGB(45, 45, 55),
		Shadow = Color3.fromRGB(0, 0, 0)
	}
}

local CurrentTheme = Themes.Dark

local GlobalInput = {
	ActiveDrag = nil,
	ActiveSlider = nil
}

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		if GlobalInput.ActiveDrag then
			GlobalInput.ActiveDrag(input)
		end
		if GlobalInput.ActiveSlider then
			GlobalInput.ActiveSlider(input)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		GlobalInput.ActiveDrag = nil
		GlobalInput.ActiveSlider = nil
	end
end)

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

	local screenGui = CoreGui:FindFirstChild("UI_Notifications")
	if not screenGui then
		screenGui = Create("ScreenGui", {
			Name = "UI_Notifications",
			Parent = CoreGui,
			ZIndexBehavior = Enum.ZIndexBehavior.Global
		})
	end

	local notifyFrame = Create("Frame", {
		Name = "NotifyFrame",
		Parent = screenGui,
		BackgroundColor3 = CurrentTheme.Container,
		Position = UDim2.new(1, 20, 1, -100),
		Size = UDim2.new(0, 260, 0, 80),
		AnchorPoint = Vector2.new(1, 1),
		ClipsDescendants = true,
		Create("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Create("UIStroke", { Color = CurrentTheme.Border, Thickness = 1 })
	})

	Create("TextLabel", {
		Parent = notifyFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 15, 0, 10),
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
		Position = UDim2.new(0, 15, 0, 35),
		Size = UDim2.new(1, -30, 0, 35),
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
			ApplyTween(child, { Position = child.Position - UDim2.new(0, 0, 0, 90) }, TweenSmooth)
		end
	end

	ApplyTween(notifyFrame, { Position = targetPos }, TweenSmooth)

	task.delay(duration, function()
		local tween = ApplyTween(notifyFrame, { Position = notifyFrame.Position + UDim2.new(0, 300, 0, 0), BackgroundTransparency = 1 }, TweenSmooth)
		tween.Completed:Connect(function()
			notifyFrame:Destroy()
		end)
	end)
end

function Library:CreateWindow(config)
	local windowTitle = Validate(config.Title, "string", "Window")
	local windowSize = Validate(config.Size, "UDim2", UDim2.new(0, 550, 0, 400))

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

	local dragStartPos = nil
	local dragInputPos = nil

	table.insert(windowObj.Connections, topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStartPos = mainFrame.Position
			dragInputPos = input.Position
			GlobalInput.ActiveDrag = function(dragInput)
				local delta = dragInput.Position - dragInputPos
				ApplyTween(mainFrame, {
					Position = UDim2.new(
						dragStartPos.X.Scale, 
						dragStartPos.X.Offset + delta.X, 
						dragStartPos.Y.Scale, 
						dragStartPos.Y.Offset + delta.Y
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
		Size = UDim2.new(0, 140, 1, -75),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		ScrollBarThickness = 0,
		Create("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 6)
		})
	})

	local contentContainer = Create("Frame", {
		Name = "ContentContainer",
		Parent = mainFrame,
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 170, 0, 60),
		Size = UDim2.new(1, -185, 1, -75)
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
			Size = UDim2.new(1, 0, 0, 32),
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
			Create("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8)
			}),
			Create("UIPadding", {
				PaddingRight = UDim.new(0, 10)
			})
		})

		table.insert(tabObj.Instances, tabButton)
		table.insert(tabObj.Instances, tabContent)

		table.insert(tabObj.Connections, tabContent.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tabContent.CanvasSize = UDim2.new(0, 0, 0, tabContent.UIListLayout.AbsoluteContentSize.Y)
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

		if not windowObj.CurrentTab then
			ActivateTab()
		end

		local function RegisterElement(elementObj, instance)
			table.insert(tabObj.Elements, elementObj)
			table.insert(tabObj.Instances, instance)
			
			function elementObj:SetVisible(state)
				instance.Visible = Validate(state, "boolean", true)
			end
			
			function elementObj:Destroy()
				if instance and instance.Parent then
					instance:Destroy()
				end
			end
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

			table.insert(tabObj.Connections, buttonFrame.MouseEnter:Connect(function() 
				ApplyTween(buttonFrame, { BackgroundColor3 = CurrentTheme.ElementHover }, TweenFast) 
			end))
			
			table.insert(tabObj.Connections, buttonFrame.MouseLeave:Connect(function() 
				ApplyTween(buttonFrame, { BackgroundColor3 = CurrentTheme.Element }, TweenFast) 
			end))
			
			table.insert(tabObj.Connections, buttonFrame.MouseButton1Click:Connect(function()
				if tick() - lastClick < 0.2 then return end
				lastClick = tick()
				
				ApplyTween(buttonFrame, { BackgroundColor3 = CurrentTheme.Accent }, TweenInfo.new(0.1))
				task.delay(0.1, function()
					ApplyTween(buttonFrame, { BackgroundColor3 = CurrentTheme.ElementHover }, TweenFast)
				end)
				
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
				Position = UDim2.new(0, state and 18 || 2, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				Create("UICorner", { CornerRadius = UDim.new(1, 0) }),
				Create("UIStroke", { Color = CurrentTheme.Shadow, Transparency = 0.8, Thickness = 1 })
			})

			local function UpdateState(newState, skipCallback)
				state = newState
				ApplyTween(indicatorBG, { BackgroundColor3 = state and CurrentTheme.Accent or CurrentTheme.Background }, TweenFast)
				ApplyTween(indicatorCircle, { Position = UDim2.new(0, state and 18 or 2, 0.5, -8) }, TweenFast)
				if not skipCallback then
					callback(state)
				end
			end

			table.insert(tabObj.Connections, toggleFrame.MouseButton1Click:Connect(function()
				UpdateState(not state, false)
			end))

			function toggleObj:SetValue(val)
				UpdateState(Validate(val, "boolean", false), false)
			end

			function toggleObj:GetValue()
				return state
			end

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

			function sliderObj:GetValue()
				return currentValue
			end

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

			local listContainer = Create("Frame", {
				Parent = dropdownFrame,
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 0, 0, 38),
				Size = UDim2.new(1, 0, 1, -38)
			})

			local listLayout = Create("UIListLayout", {
				Parent = listContainer,
				SortOrder = Enum.SortOrder.LayoutOrder
			})

			local function BuildOptions(newOptions)
				for _, inst in ipairs(optionInstances) do
					inst:Destroy()
				end
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

					table.insert(tabObj.Connections, optBtn.MouseEnter:Connect(function()
						ApplyTween(optBtn, { BackgroundColor3 = CurrentTheme.ElementHover }, TweenFast)
					end))

					table.insert(tabObj.Connections, optBtn.MouseLeave:Connect(function()
						ApplyTween(optBtn, { BackgroundColor3 = CurrentTheme.Background }, TweenFast)
					end))

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
				
				local targetHeight = isOpen and (38 + listLayout.AbsoluteContentSize.Y) or 38
				ApplyTween(dropdownFrame, { Size = UDim2.new(1, 0, 0, targetHeight) }, TweenFast)
			end))

			function dropdownObj:SetOptions(newOptions)
				BuildOptions(Validate(newOptions, "table", {}))
				if isOpen then
					local targetHeight = 38 + listLayout.AbsoluteContentSize.Y
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

			function dropdownObj:GetValue()
				return currentOption
			end

			RegisterElement(dropdownObj, dropdownFrame)
			return dropdownObj
		end

		return tabObj
	end

	function windowObj:Destroy()
		for _, inst in ipairs(windowObj.Instances) do
			if inst and inst.Parent then
				inst:Destroy()
			end
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

return Library
