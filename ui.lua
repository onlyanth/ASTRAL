-- EvictedLib v0.1.1
-- By topit 
-- June -> July 2023 


-- Services 
local coreGui = game:GetService('CoreGui')
local runService = game:GetService('RunService')
local inputService = game:GetService('UserInputService')
local playerService = game:GetService('Players')
local tweenService = game:GetService('TweenService')

-- Wait for the game to load  
if ( not game:IsLoaded() ) then
	game.Loaded:Wait()
end

-- Variables 
local localPlayer = playerService.LocalPlayer

-- Libraries 
local tween = {}
do
	local EasingStyle = Enum.EasingStyle
	local EasingDirection = Enum.EasingDirection

	local styleLinear = EasingStyle.Linear
	local styleExp = EasingStyle.Exponential
	local styleQuad = EasingStyle.Quad 

	local dirInOut = EasingDirection.InOut
	local dirOut = EasingDirection.Out 

	function tween.Linear(instance, properties, duration) 
		local thisTween = tweenService:Create(
			instance,
			TweenInfo.new(duration, styleLinear),
			properties
		)

		thisTween:Play()

		return thisTween
	end

	function tween.Exp(instance, properties, duration) 
		local thisTween = tweenService:Create(
			instance,
			TweenInfo.new(duration, styleExp),
			properties
		)

		thisTween:Play()

		return thisTween
	end

	function tween.Quad(instance, properties, duration) 
		local thisTween = tweenService:Create(
			instance,
			TweenInfo.new(duration),
			properties
		)

		thisTween:Play()

		return thisTween
	end

	function tween.Quick(instance, properties) 
		local thisTween = tweenService:Create(
			instance,
			TweenInfo.new(0.3, styleExp),
			properties
		)

		thisTween:Play()

		return thisTween
	end

	function tween.Smooth(instance, properties)
		local thisTween = tweenService:Create(
			instance,
			TweenInfo.new(0.3, styleQuad, dirInOut),
			properties
		)

		thisTween:Play()

		return thisTween
	end
end

local function lerp(v0, v1, t) 
	return ( 1 - t ) * v0 + t * v1 
end

local function round(value, places) 
	return math.round(value / places ) * places
end

-- Preparation
local librarySource = game:GetObjects('rbxassetid://13949667049')[1]
local libraryObjects = librarySource.Objects

librarySource.Parent = (gethui and gethui()) or (get_hidden_ui and get_hidden_ui()) or ( game.CoreGui )
librarySource['#notification-container'].ZIndex = 600

--- Main
-- Create main library API
local Library = {} 
Library._class = 'Library'
Library.__index = Library 

Library._notifs = {}
Library._windows = {} 
Library.connections = {} 

-- Create and initialize element classes
local Classes = {} do
	Classes.Base = (function() 
		local Base = {}  
		Base._class = 'Base'
		Base.__index = Base

		function Base:GetParentOfClass(class: string) 
			local parent = self 

			while true do
				parent = parent.parent

				if ( not parent ) then
					return false
				end

				if ( parent._class == class ) then
					return parent 
				end
			end

			return false 
		end

		function Base.new() 
			return setmetatable({}, Base)
		end

		return Base 
	end)();

	Classes.Window = (function() 
		local Window = {} do 
			Window._class = 'Window'
			Window.__index = Window 

			setmetatable(Window, Classes.Base)

			function Window:Finalize() 		
				local instances = self.instances

				-- window related
				do 
					local i_window = instances.window
					local i_windowScale = i_window['#scale']

					i_window.Visible = true
					i_window.Parent = librarySource

					i_windowScale.Scale = 0 
					tween.Smooth(i_windowScale, {Scale = 1}).Completed:Connect(function() 
						local sizeOffset = UDim2.fromOffset(i_window.AbsoluteSize.X / 2, i_window.AbsoluteSize.Y / 2)

						i_window.AnchorPoint = Vector2.zero 
						i_window.Position -= sizeOffset

						self._draggable = true
					end)
				end

				-- title related
				do 
					local i_title = instances.title
					local i_titleWipe = i_title['#gradient']

					local i_build = instances.build
					local i_buildWipe = i_build['#gradient']

					i_titleWipe.Offset = Vector2.zero 
					tween.Quad(i_titleWipe, {Offset = Vector2.xAxis}, 0.8)

					i_titleWipe.Offset = Vector2.zero 
					tween.Quad(i_titleWipe, {Offset = Vector2.xAxis}, 0.8)
				end

				-- loader related
				do 
					if ( self._loader ) then
						task.spawn(function()
							local loader_container = instances.loader_container
							local loader_background = instances.loader_background
							local loader_button = instances.loader_button 
							local loader_progress = instances.loader_progress
							local loader_title = instances.loader_title
							local loader_message = instances.loader_message 


							loader_container.Visible = true 

							local progress_gradient = loader_progress['#gradient']
							progress_gradient.Offset = Vector2.new(-0.6, 0)

							task.wait(0.3)

							tween.Quad(progress_gradient, {
								Offset = Vector2.new(0.51, 0)
							}, self._loadTime)

							task.wait(self._loadTime + 0.1)

							loader_title.Text = 'Loaded'
							loader_message.Text = 'Done!'

							if ( self._loaderConfirm ) then
								local detector = loader_button['#button']							

								local now = coroutine.running()

								detector.MouseButton1Click:Once(function() 
									detector.BackgroundColor3 = detector:GetAttribute('_ClickColor')
									tween.Quad(detector, {
										BackgroundColor3 = detector:GetAttribute('_HoverColor')
									}, 0.5)
									coroutine.resume(now)
								end) 

								detector.MouseEnter:Connect(function() 
									tween.Quick(detector, {
										BackgroundColor3 = detector:GetAttribute('_HoverColor')
									})
								end) 

								detector.MouseLeave:Connect(function() 
									tween.Quick(detector, {
										BackgroundColor3 = detector:GetAttribute('_MainColor')
									})
								end)

								tween.Quick(loader_button, { Position = UDim2.fromScale(0.5, 0.8)})

								coroutine.yield()
							end

							task.wait(0.3)

							if ( self._loadedCallback ) then
								task.spawn(self._loadedCallback, self, self._loaderConfirm)
							end

							tween.Smooth(loader_background, {
								BackgroundTransparency = 1 
							}, 0.5)

							tween.Smooth(loader_title, {
								Position = UDim2.fromScale(0.5, -0.2)
							}, 0.5)

							tween.Smooth(loader_message, {
								Position = UDim2.fromScale(0.5, -0.12)
							}, 0.5)

							tween.Smooth(loader_progress, {
								Position = UDim2.fromScale(0.5, 1.1)
							}, 0.5)
							tween.Smooth(loader_button, {
								Position = UDim2.fromScale(0.5, 1.3)
							}, 0.5)

							task.wait(0.5)
							loader_container.Visible = false
						end)
					end
				end

				return self
			end

			function Window:Destroy(_avoidLibraryCheck: boolean) 
				local i_window = self.instances.window -- instance_window
				local i_windowScale = i_window['#scale']

				if ( self._destroyCallback ) then
					task.spawn(self._destroyCallback, self)
				end

				i_windowScale.Scale = 1 
				i_window.Visible = true 

				self._resizable = false 
				self._draggable = false 

				task.spawn(function()
					local sizeOffset = UDim2.fromOffset(i_window.AbsoluteSize.X / 2, i_window.AbsoluteSize.Y / 2)

					i_window.AnchorPoint = Vector2.one / 2 
					i_window.Position += sizeOffset

					tween.Smooth(i_windowScale, {Scale = 0}).Completed:Wait()
					i_window:Destroy()

					for i, conn in pairs(self.connections) do
						if ( typeof(conn) == 'thread' ) then
							task.cancel(conn)
						else
							conn:Disconnect()
						end
					end
				end)

				if ( self._retainToggles ~= true ) then
					for _, category in self._categories do
						for _, menu in category._menus do
							for _, section in menu._sections do
								for _, module in section._modules do
									if ( module._class == 'ModuleToggle' and module:IsEnabled() ) then
										module:Disable()
									end
								end
							end
						end
					end    
				end

				local windows = self.parent._windows

				table.remove(windows, table.find(windows, self))


				if ( #windows == 0 and ( _avoidLibraryCheck ~= true ) ) then
					Library:Destroy()
				end

				setmetatable(self, nil)
			end

			function Window:Minimize() 
				self._minimized = true 

				--[[Library:Notify({
					Title = 'Window minimized';
					Message = 'Press RightShift to refocus the window';
					Duration = 5;
				})]]
			end

			function Window:Unminimize() 
				self._minimized = false 
			end

			function Window:_ClearViewerConns() 
				local connections = self.connections
				for _, updater in ipairs({ 'viewerSwipeUpdater', 'viewerSwipeAnimator', 'viewerDragUpdater', 'viewerDragAnimator'}) do 
					if ( connections[updater] ) then
						connections[updater]:Disconnect() 
					end
				end

				return self 
			end

			function Window:ShowCharViewer()
				self:_ClearViewerConns()

				local charviewer_container = self.instances.charviewer_container
				local xPosition = charviewer_container:GetAttribute('_XPosition')

				charviewer_container.Position = UDim2.fromScale(xPosition, 2)

				charviewer_container.Visible = true 
				tween.Smooth(charviewer_container, {
					Position = UDim2.fromScale(xPosition, 0.03)
				}, 0.5)

				return self
			end

			function Window:HideCharViewer() 
				self:_ClearViewerConns()

				local charviewer_container = self.instances.charviewer_container
				local xPosition = charviewer_container:GetAttribute('_XPosition')

				charviewer_container.Position = UDim2.fromScale(xPosition, 0.03)

				tween.Smooth(charviewer_container, {
					Position = UDim2.fromScale(xPosition, 2)
				}, 0.5).Completed:Connect(function()
					charviewer_container.Visible = false
				end)

				return self
			end

			function Window:ViewChar(character: Model) 
				if ( typeof(character) ~= 'Instance' ) then
					return error('[Window:ViewChar] Expected type "Instance" for argument "character"', 2)
				end

				if ( character.ClassName ~= 'Model' ) then
					return error('[Window:ViewChar] Expected class "Model" for argument "character"', 2)
				end

				if ( self.connections.viewerThread ) then
					task.cancel(self.connections.viewerThread)
				end

				local instances = self.instances

				local warningMessage = instances.charviewer_warning 
				local viewport = instances.charviewer_viewport 


				character.Archivable = true
				local clone = character:Clone()
				character.Archivable = false 

				if ( not clone ) then
					warningMessage.Text = 'failed to clone model'
					warningMessage.Visible = true 
					return false 
				end

				self._viewModel = clone

				clone:SetAttribute('_BaseCFrame', CFrame.new(0, 9, 0) * CFrame.fromOrientation(math.rad(-8), math.rad(180), 0))
				clone:PivotTo(clone:GetAttribute('_BaseCFrame'))

				clone.Parent = viewport['#worldmodel']

				if ( clone:FindFirstChild('Humanoid') and clone:FindFirstChild('HumanoidRootPart') ) then

					-- check for an animate script
					-- if one is found this is a default roblox character and can be manually animated
					-- otherwise, just leave it unanimated 
					if ( clone:FindFirstChild('Animate') ) then			

						local animator = clone.Humanoid:FindFirstChild('Animator')

						if ( not animator ) then
							return
						end

						local animateScript = clone.Animate

						if ( not animateScript:FindFirstChild('idle') ) then
							return 
						end

						local anim1 = animator:LoadAnimation(clone.Animate.idle.Animation1)
						local anim2 = animator:LoadAnimation(clone.Animate.idle.Animation2)

						anim1.Looped = false 
						anim2.Looped = false

						clone.Animate:Destroy()

						self.connections.viewerThread = task.spawn(function() -- this doesnt fully work, no idea why, fuck roblox animation system
							while true do
								for i = 1, math.random(3, 5) do 
									anim1.Looped = false
									anim1:Play(0.1)
									anim1.Ended:Wait()
								end
								
								anim2.Looped = false
								anim2:Play(0.1)
								anim2.Ended:Wait()
							end
						end)
					end
				end

				return self 
			end

			-- Creates and returns a new window object
			function Window.new(parent, settings: {}) 
				local self = setmetatable({}, Window)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 

				-- Private properties
				self._draggable = settings.Draggable
				self._resizable = settings.Resizable
				self._categories = {} 

				self._loader = settings.Loader 
				self._loadTime = settings.LoadTime
				self._loaderConfirm = settings.LoaderConfirmation
				self._loadedCallback = settings.LoadedCallback

				self._retainToggles = settings.RetainToggles 
				self._destroyCallback = settings.DestroyCallback

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 
					local window = Library:GetObjects()['#WINDOW']:Clone()
					instances.window = window 

					-- localization 
					local title_container = window['#sidebar-container']['#background']['#content-container']['#title-container']
					local control_container = window['#menu-container']['#header-container']['#control-container']
					local loader_container = window['#loader-container']
					local charviewer_container = window['#charviewer-container']

					instances.title = title_container['#title']
					instances.build = title_container['#build']
					instances.pagelist_container = window['#sidebar-container']['#background']['#content-container']['#pagelist-container']
					instances.page_container = window['#menu-container']['#content-container']['#page-container']
					instances.userinfo = window['#sidebar-container']['#userinfo']['#content-container']
					instances.header = window['#menu-container']['#header-container']
					instances.control_close = control_container['#control-close']
					instances.control_minimize = control_container['#control-minimize']
					instances.control_settings = control_container['#control-settings']

					instances.loader_container = loader_container
					instances.loader_button = loader_container['#button']
					instances.loader_background = loader_container['#background']
					instances.loader_progress = loader_container['#progress-bar']
					instances.loader_title = loader_container['#title']
					instances.loader_message = loader_container['#message']

					instances.charviewer_container = charviewer_container
					instances.charviewer_viewport = charviewer_container['#viewport']
					instances.charviewer_warning = charviewer_container['#warning']
				end

				-- Instance modification
				do 
					local instances = self.instances

					-- Build and title
					do 
						instances.title.Text = settings.Title 

						if ( settings.Build == false ) then
							instances.build.Text = ''
						else
							instances.build.Text = settings.BuildPrefix .. tostring(settings.Build)
						end
					end

					-- Loader
					do 
						if ( settings.Loader ) then 
							instances.loader_container.Visible = true
							instances.loader_button.Position = UDim2.fromScale(0.5, 1.2) -- 0.5, 0.85
						else
							instances.loader_container.Visible = false 
						end
					end

					-- Userinfo
					do 
						local iconContainer = instances.userinfo['#icon-container']
						local infoContainer = instances.userinfo['#info-container']

						local userLabel = infoContainer['#username']
						local timeLabel = infoContainer['#timestamp']
						local userIcon = iconContainer['#user-icon']

						local animThread 
						local resetThread

						local fontNormal = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold, Enum.FontStyle.Normal)
						local fontItalic = Font.new('rbxasset://fonts/families/Montserrat.json', Enum.FontWeight.Bold, Enum.FontStyle.Italic)

						local userThumbnail = playerService:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)

						userLabel:GetAttributeChangedSignal('StreamerMode'):Connect(function() 
							if ( userLabel:GetAttribute('StreamerMode') == true ) then
								--[[local function e1(x) -- y1 = abs(sin(4x))
									return abs(sin(2 * x))
								end
								local function e2(x) --y2 = abs(sin(2x)+1)
									return abs(sin(1 * x) + 1)
								end
								local function e3(x) -- y3 = min(abs(y1+y2)^3, 1)
									return max( -abs(e1(x) + e2(x))^3, -1 ) + 1
								end]]

								if ( resetThread ) then
									task.cancel(resetThread)
								end 

								local messages = { 'NAME HIDDEN', 'STREAMER MODE' }

								animThread = task.spawn(function() 
									local index = 0

									tween.Exp(userIcon, {
										ImageTransparency = 1
									}, 0.2).Completed:Connect(function() 
										userIcon.Image = 'rbxassetid://13292509590'

										tween.Exp(userIcon, {
											ImageTransparency = 0
										}, 0.2)
									end)

									while ( true ) do
										index += 1 

										tween.Exp(userLabel, {
											TextTransparency = 1
										}, 0.2)

										task.wait(0.2)

										userLabel.FontFace = fontItalic
										userLabel.Text = messages[(index % 2) + 1]

										tween.Exp(userLabel, {
											TextTransparency = 0
										}, 0.2)

										task.wait(2)
									end
								end)
							else
								if ( animThread ) then
									task.cancel(animThread)
								end

								resetThread = task.spawn(function()
									tween.Exp(userLabel, {
										TextTransparency = 1
									}, 0.2)

									tween.Exp(userIcon, {
										ImageTransparency = 1 
									}, 0.2)

									task.wait(0.2)

									userLabel.Text = localPlayer.Name
									userLabel.FontFace = fontNormal
									userIcon.Image = userThumbnail

									tween.Exp(userIcon, {
										ImageTransparency = 0 
									}, 0.2)

									tween.Exp(userLabel, {
										TextTransparency = 0
									}, 0.2)
								end)
							end
						end)


						userLabel.Text = localPlayer.Name
						userIcon.Image = userThumbnail

						-- rbxassetid://13292509590

						self.connections.userinfoUpdate = runService.Heartbeat:Connect(function() 
							timeLabel.Text = os.date('%I:%M:%S %p'):upper()
						end)

						--userLabel:SetAttribute('StreamerMode', true)
					end

					local viewerSwiping = false
					local viewerDragging = false 
					local windowDragging = false 

					-- Charviewer
					do 
						local charviewer_container = instances.charviewer_container
						local charviewer_viewport = instances.charviewer_viewport

						charviewer_container:SetAttribute('_XPosition', 1.1)
						charviewer_container.Position = UDim2.fromScale(1.1, 2)
						charviewer_container.Visible = false

						local targetRotation = 0 
						local currentRotation = 0 
						local thisDragId = 0

						charviewer_viewport.InputBegan:Connect(function(input) 
							if ( not self._viewModel ) then
								return 
							end

							if ( input.UserInputType.Name == 'MouseButton1' ) then
								thisDragId += 1 
								viewerSwiping = true

								currentRotation %= 360
								targetRotation %= 360

								local offsetRotation = targetRotation

								local s_mousePos = Vector2.new(input.Position.X, input.Position.Y) -- starter mouse position 
								local s_modelPos = self._viewModel:GetAttribute('_BaseCFrame')

								-- check for existing connections and disconnect them so nothing leaks 
								local swipeUpdater = self.connections.viewerSwipeUpdater
								local swipeAnimator = self.connections.viewerSwipeAnimator 

								if ( swipeUpdater ) then
									swipeUpdater:Disconnect()
								end
								if ( swipeAnimator ) then
									swipeAnimator:Disconnect()
								end

								self.connections.viewerSwipeAnimator = runService.Heartbeat:Connect(function(deltaTime)
									currentRotation = lerp(currentRotation, targetRotation, 1 - math.exp(-6 * deltaTime))

									self._viewModel:PivotTo(s_modelPos * CFrame.fromOrientation(0, math.rad(currentRotation), 0))
								end)

								self.connections.viewerSwipeUpdater = inputService.InputChanged:Connect(function(input) 
									if ( input.UserInputType.Name == 'MouseMovement' ) then
										local c_mousePos = Vector2.new(input.Position.X, input.Position.Y) -- current mouse position 

										local delta = ( c_mousePos - s_mousePos )
										targetRotation = offsetRotation + delta.X
									end
								end)
							end
						end)

						charviewer_viewport.InputEnded:Connect(function(input) 
							if ( not self._viewModel ) then
								return 
							end

							if ( input.UserInputType.Name == 'MouseButton1' ) then
								viewerSwiping = false 

								local swipeUpdater = self.connections.viewerSwipeUpdater
								local swipeAnimator = self.connections.viewerSwipeAnimator 

								if ( swipeUpdater ) then
									swipeUpdater:Disconnect()
								end

								local thisId = thisDragId

								while ( thisId == thisDragId ) do
									if math.abs( targetRotation - currentRotation ) < 0.01 then
										swipeAnimator:Disconnect()
										break
									end
									task.wait(0.05)
								end
							end
						end)


						local targetPosition

						charviewer_container.InputBegan:Connect(function(input) 
							if ( viewerSwiping or windowDragging ) then
								return 
							end

							if ( input.UserInputType.Name == 'MouseButton1' ) then

								local s_basePos = charviewer_container.AbsolutePosition
								local s_windowPos = instances.window.AbsolutePosition
								local s_mousePos = Vector2.new(input.Position.X, input.Position.Y)

								local dragUpdater = self.connections.viewerDragUpdater
								local dragAnimator = self.connections.viewerDragAnimator 

								if ( dragUpdater ) then
									dragUpdater:Disconnect()
								end
								if ( dragAnimator ) then
									dragAnimator:Disconnect()
								end

								targetPosition = s_basePos - s_windowPos

								-- connect updater functions
								self.connections.viewerDragAnimator = runService.Heartbeat:Connect(function(deltaTime)
									local destination = UDim2.fromOffset(targetPosition.X, targetPosition.Y)

									charviewer_container.Position = charviewer_container.Position:Lerp(destination, 1 - math.exp(-25 * deltaTime))
								end)

								self.connections.viewerDragUpdater = inputService.InputChanged:Connect(function(input) 
									if ( input.UserInputType.Name == 'MouseMovement' ) then
										local c_mousePos = Vector2.new(input.Position.X, input.Position.Y) -- current mouse position 

										targetPosition = (s_basePos + (c_mousePos - s_mousePos)) - s_windowPos
									end
								end)
							end
						end)

						charviewer_container.InputEnded:Connect(function(input) 
							if ( viewerSwiping or windowDragging ) then
								return 
							end

							if ( input.UserInputType.Name == 'MouseButton1' ) then
								local dragUpdater = self.connections.viewerDragUpdater
								local dragAnimator = self.connections.viewerDragAnimator 

								if ( dragUpdater ) then
									dragUpdater:Disconnect()
								end
								if ( dragAnimator ) then
									dragAnimator:Disconnect()
								end

								local window = instances.window

								local viewerX = charviewer_viewport.AbsolutePosition.X 
								local windowX = window.AbsolutePosition.X + ( window.AbsoluteSize.X / 2 ) -- account for midway anchorpoint

								if ( viewerX >= windowX ) then -- viewer is to the right, snap to 1.1
									tween.Smooth(charviewer_container, {Position = UDim2.fromScale(1.1, 0.03)}, 0.3)
									charviewer_container:SetAttribute('_XPosition', 1.1)
								else
									tween.Smooth(charviewer_container, {Position = UDim2.fromScale(-0.45, 0.03)}, 0.3)
									charviewer_container:SetAttribute('_XPosition', -0.45)
								end
							end
						end)
					end

					-- Window dragging
					do 
						local window = instances.window
						local header = instances.header 

						window.Position = settings.DefaultPosition 
						window.Size = settings.DefaultSize

						local targetPosition

						header.InputBegan:Connect(function(input) 
							if ( not self._draggable ) then
								return 
							end

							if ( input.UserInputType.Name == 'MouseButton1' ) then
								windowDragging = true

								local s_basePos = window.AbsolutePosition -- starter base position
								local s_mousePos = Vector2.new(input.Position.X, input.Position.Y) -- starter mouse position 

								-- check for existing connections and disconnect them so nothing leaks 
								local dragUpdater = self.connections.dragUpdater
								local dragAnimator = self.connections.dragAnimator 

								if ( dragUpdater ) then
									dragUpdater:Disconnect()
								end
								if ( dragAnimator ) then
									dragAnimator:Disconnect()
								end

								targetPosition = s_basePos  

								-- connect updater functions
								self.connections.dragAnimator = runService.Heartbeat:Connect(function(deltaTime)
									local destination = UDim2.fromOffset(targetPosition.X, targetPosition.Y) -- convert targetPosition, a vec2, to a udim2

									window.Position = window.Position:Lerp(destination, 1 - math.exp(-25 * deltaTime)) -- smoothly move the window over to the target
								end)

								self.connections.dragUpdater = inputService.InputChanged:Connect(function(input) 
									if ( input.UserInputType.Name == 'MouseMovement' ) then
										local c_mousePos = Vector2.new(input.Position.X, input.Position.Y) -- current mouse position 

										targetPosition = s_basePos + (c_mousePos - s_mousePos)
									end
								end)
							end
						end)

						header.InputEnded:Connect(function(input) 
							if ( not self._draggable ) then
								return 
							end

							if ( input.UserInputType.Name == 'MouseButton1' ) then
								windowDragging = false

								-- disconnect any updaters
								local dragUpdater = self.connections.dragUpdater
								local dragAnimator = self.connections.dragAnimator 

								if ( dragUpdater ) then
									dragUpdater:Disconnect()
								end
								if ( dragAnimator ) then
									dragAnimator:Disconnect()
								end

								-- remove dragging drift (innaccuracies caused by lerp)
								tween.Quad(window, {Position = UDim2.fromOffset(targetPosition.X, targetPosition.Y)}, 0.1)
							end
						end)
					end

					-- Controls
					do 
						local controlClose = instances.control_close
						local controlMinimize = instances.control_minimize
						local controlSettings = instances.control_settings

						controlMinimize.Visible = false 
						controlSettings.Visible = false 

						-- this loop thingy may look bad but its super nice
						for _, button in ipairs({ controlClose, controlMinimize, controlSettings }) do
							button.MouseEnter:Connect(function() 
								tween.Quick(button['#button']['#icon'], {
									ImageColor3 = Color3.fromRGB(25, 175, 255)
								})
							end)

							button.MouseLeave:Connect(function() 
								tween.Quick(button['#button']['#icon'], {
									ImageColor3 = Color3.fromRGB(255, 255, 255)
								})
							end)

							button['#button'].MouseButton1Down:Connect(function() 
								tween.Quick(button['#button']['#icon'], {
									ImageColor3 = Color3.fromRGB(14, 101, 145)
								})
							end)

							button['#button'].MouseButton1Up:Connect(function() 
								tween.Quick(button['#button']['#icon'], {
									ImageColor3 = Color3.fromRGB(25, 175, 255)
								})
							end)
						end

						controlClose['#button'].MouseButton1Click:Connect(function() 
							self:Destroy()
						end)

						controlMinimize['#button'].MouseButton1Click:Connect(function() 
							if ( self._minimized ) then
								self:Unminimize()
							else
								self:Minimize()
							end
						end)
					end
				end

				table.insert(parent._windows, self)

				return self 
			end

			function Window:CreateMenuCategory(options: {})
				local s_title = options.Title 

				-- handle parameters
				if ( typeof(s_title) ~= 'string' ) then
					s_title = 'Section'
				end

				-- handle object 
				return Classes.MenuCategory.new(self, {
					Title = s_title 
				})
			end
		end

		return Window
	end)();

	Classes.MenuCategory = (function() 
		local MenuCategory = {} do 
			MenuCategory.__index = MenuCategory
			MenuCategory._class = 'MenuCategory'

			setmetatable(MenuCategory, Classes.Base)

			function MenuCategory.new(parent, settings: {}) 
				local self = setmetatable({}, MenuCategory)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 

				-- Private properties
				self._menus = {}

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 
					local category = Library:GetObjects()['#MENU_CATEGORY']:Clone()
					instances.category = category 

					-- localization 
					instances.title = category['#header']['#title']
					instances.menu_container = category['#menu-container']
				end

				-- Instance modification
				do 
					local instances = self.instances
					instances.title.Text = settings.Title 

					instances.category.Parent = parent.instances.pagelist_container
					instances.category.Visible = true 
				end

				table.insert(parent._categories, self)

				return self 
			end

			function MenuCategory:CreateMenu(settings: {}) 
				local s_title = settings.Title
				local s_icon = settings.Icon

				-- handle parameters
				if ( typeof(s_title) ~= 'string' ) then
					s_title = 'Menu'
				end

				if ( typeof(s_icon) ~= 'string' ) then
					s_icon = 'rbxassetid://13282358188'
				end

				return Classes.Menu.new(self, {
					Title = s_title; -- Title of the menu button
					Icon = s_icon; -- Icon of the menu button
				})
			end
		end

		return MenuCategory
	end)();

	Classes.Menu = (function() 
		local Menu = {} do 
			Menu.__index = Menu
			Menu._class = 'Menu'

			setmetatable(Menu, Classes.Base)

			function Menu:CreateSection(settings: {}) 
				local s_side = settings.Side 
				local s_title = settings.Title

				if ( typeof(s_title) ~= 'string' ) then
					s_title = 'Section'
				end

				if ( s_side == 'Left' ) then
					s_side = 1 -- left 
				elseif ( s_side == 'Right' ) then
					s_side = 2 -- right
				else
					s_side = 0 -- auto 
				end

				return Classes.Section.new(self, {
					Side = s_side;
					Title = s_title;
				})
			end

			function Menu:IsSelected() 
				return self._selected
			end			

			function Menu:Select() 
				if ( self:IsSelected() ) then
					return
				end

				local thisId = self._menuId

				self._selected = true 

				for _, category in ipairs(self:GetParentOfClass('Window')._categories) do
					for _, menu in ipairs(category._menus) do
						if ( menu ~= self ) then
							menu:Deselect()
						end

						tween.Quick(menu.instances.menu_page, {
							Position = UDim2.fromScale(0, menu._menuId - thisId)
						})
					end
				end

				tween.Exp(self.instances.button_glow['#gradient'], {
					Offset = Vector2.zero 
				}, 0.4)
			end

			function Menu:Deselect() 
				self._selected = false

				tween.Quick(self.instances.button_text, {
					TextColor3 = Color3.fromRGB(150, 150, 150)
				})
				tween.Exp(self.instances.button_glow['#gradient'], {
					Offset = -Vector2.xAxis 
				}, 0.8)
			end

			function Menu.new(parent, settings: {}) 
				local self = setmetatable({}, Menu)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 

				-- Private properties
				self._selected = false -- for button
				self._menuId = 0 do
					local count = 0 
					local window = self:GetParentOfClass('Window')

					for _, category in ipairs(window._categories) do
						count += # category._menus
					end

					self._menuId = count
				end
				self._sections = { }

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 
					local menu_page = Library:GetObjects()['#MENU_PAGE']:Clone()
					instances.menu_page = menu_page 

					local menu_button = Library:GetObjects()['#MENU_BUTTON']:Clone()
					instances.menu_button = menu_button 

					-- localization 
					instances.page_sidel = menu_page['#side-lh']
					instances.page_sider = menu_page['#side-rh']

					instances.button_text = menu_button['#text']
					instances.button_icon = menu_button['#icon']
					instances.button_glow = menu_button['#glow']
				end

				-- Instance modification
				do 
					local instances = self.instances

					-- setup main instances
					do 

						local category = self:GetParentOfClass('MenuCategory')
						local window = category:GetParentOfClass('Window')

						instances.menu_page.Parent = window.instances.page_container
						instances.menu_button.Parent = category.instances.menu_container

						instances.menu_page.Visible = true
						instances.menu_button.Visible = true

						instances.button_text.Text = settings.Title
						instances.button_icon.Image = settings.Icon 
					end

					-- setup first button 
					do 
						if ( self._menuId == 0 ) then
							instances.button_glow['#gradient'].Offset = Vector2.zero
							--instances.menu_page.Visible = true 
						else
							instances.button_glow['#gradient'].Offset = -Vector2.xAxis
							--instances.menu_page.Visible = false 	
						end

						instances.menu_page.Position = UDim2.fromScale(0, self._menuId)
					end

					-- button connections
					do 
						local button = instances.menu_button

						button.MouseEnter:Connect(function() 
							local color = self:IsSelected() and Color3.fromRGB(250, 250, 250) or Color3.fromRGB(225, 225, 225)

							tween.Quick(button['#text'], {
								TextColor3 = color
							})
						end)

						button.MouseLeave:Connect(function() 
							local color = self:IsSelected() and Color3.fromRGB(200, 200, 200) or Color3.fromRGB(150, 150, 150)

							tween.Quick(button['#text'], {
								TextColor3 = color
							})
						end)

						button.MouseButton1Click:Connect(function() 
							self:Select()

							tween.Quick(button['#text'], {
								TextColor3 = Color3.fromRGB(250, 250, 250)
							})
						end)
					end
				end

				table.insert(parent._menus, self)

				return self 
			end
		end	

		return Menu 
	end)();

	Classes.Section = (function() 
		local Section = {} do 
			Section.__index = Section
			Section._class = 'Section'

			setmetatable(Section, Classes.Base)

			function Section:CreateToggle(settings: {}) 
				local s_title = settings.Title
				local s_callback = settings.Callback
				local s_state = settings.State 

				if ( typeof(s_title) ~= 'string' ) then
					s_title = 'Toggle'
				end

				if ( typeof(s_callback) ~= 'function' ) then
					s_callback = nil 
				end

				if ( s_state ~= true ) then
					s_state = false 
				end

				return Classes.ModuleToggle.new(self, {
					Callback = s_callback;
					Title = s_title;
					State = s_state;
				})
			end

			function Section:CreateSlider(settings: {}) 
				local s_value = settings.Value -- the starting value
				local s_step = settings.Step -- how much the slider snaps (a step of 5 advances the slider by 5, 10 advances by 10, etc.)
				local s_minimum = settings.Minimum -- the lowest value possible
				local s_maximum = settings.Maximum -- the highest value possible
				local s_exponential = settings.Exponential -- if the slider should be exponential (higher precision at lower values, lower precision at higher values); good for things like speedhacks
				local s_exponent = settings.Exponent -- the exponent to apply if exponential is true 

				local s_title = settings.Title
				local s_callback = settings.Callback
				local s_style = settings.Style -- slider style; can be 'Large' or 'Normal'

				--local s_flag = settings.Flag

				if ( typeof(s_value) ~= 'number' ) then
					s_value = 50 
				end

				if ( typeof(s_step) ~= 'number' ) then 
					s_step = 1
				end

				if ( typeof(s_minimum) ~= 'number' ) then
					s_minimum = 0 
				end

				if ( typeof(s_maximum) ~= 'number' ) then
					s_maximum = 500 
				end

				if ( s_exponential ~= true ) then
					s_exponential = false 
				end

				if ( typeof(s_exponent) ~= 'number' ) then
					s_exponent = 2.5 
				end

				if ( typeof(s_title) ~= 'string' ) then
					s_title = 'Title'
				end

				if ( typeof(s_callback) ~= 'function' ) then
					s_callback = nil 
				end


				if ( s_style == 'Large' ) then
					s_style = 1
				else
					s_style = 0 
				end

				s_value = math.clamp(s_value, s_minimum, s_maximum)
				s_value = round(s_value, s_step)

				return Classes.ModuleSlider.new(self, {
					Value = s_value;
					Step = s_step;
					Minimum = s_minimum;
					Maximum = s_maximum;
					Exponential = s_exponential;
					Exponent = s_exponent;
					Title = s_title;
					Callback = s_callback;
					Style = s_style;
					--Flag = s_flag;
				})
			end

			function Section:CreateButton(settings: {})
				local s_title = settings.Title
				local s_callback = settings.Callback

				if ( typeof(s_title) ~= 'string' ) then
					s_title = 'Button'
				end

				if ( typeof(s_callback) ~= 'function' ) then
					s_callback = nil 
				end

				return Classes.ModuleButton.new(self, {
					Callback = s_callback;
					Title = s_title;
				})
			end

			function Section:CreateMultiLabel(settings: {}) 
				local s_text = settings.Text

				if ( typeof(s_text) ~= 'string' ) then
					s_text = tostring(s_text)
				end

				return Classes.ModuleLabelMulti.new(self, {
					Text = s_text;
				})
			end

			function Section.new(parent, settings: {}) 
				local self = setmetatable({}, Section)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 

				-- Private properties
				self._sectionId = #(parent._sections)
				self._modules = {} 
				self._side = settings.Side 

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 
					local section = Library:GetObjects()['#SECTION']:Clone()
					instances.section = section 

					-- localization 
					instances.title = section['#content-container']['#header-container']['#title']
					instances.module_container = section['#content-container']['#module-container']
				end

				-- Instance modification
				do 
					local instances = self.instances

					-- setup main instances
					do 
						local section = instances.section 

						if ( self._side == 0 ) then
							-- automatic 

							if ( self._sectionId % 2 == 0 ) then
								section.Parent = parent.instances.page_sidel
							else
								section.Parent = parent.instances.page_sider
							end
						elseif ( self._side == 1 ) then -- left
							section.Parent = parent.instances.page_sidel
						else -- right
							section.Parent = parent.instances.page_sider
						end

						instances.title.Text = settings.Title 
						section.Visible = true
					end
				end

				table.insert(parent._sections, self)

				return self 
			end
		end	

		return Section 
	end)();

	Classes.ModuleButton = (function() 
		local ModuleButton = {} do 
			ModuleButton.__index = ModuleButton
			ModuleButton._class = 'ModuleButton'

			setmetatable(ModuleButton, Classes.Base)

			function ModuleButton:SetCallback(callback) 
				if ( typeof(callback) ~= 'function' ) then
					return error('[ModuleButton:SetCallback] Expected type "function" for argument "callback"', 2)
				end

				self._callback = callback 

				return self 
			end

			function ModuleButton:Click()
				local clickButton = self.instances.clickbutton

				clickButton.BackgroundColor3 = clickButton:GetAttribute('_ClickColor')
				tween.Quad(clickButton, {
					BackgroundColor3 = ( self._hovered and clickButton:GetAttribute('_HoverColor') ) or clickButton:GetAttribute('_MainColor')
				}, 0.5)

				if ( self._callback ) then
					task.spawn(self._callback)
				end
			end

			function ModuleButton.new(parent, settings: {}) 
				local self = setmetatable({}, ModuleButton)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 

				-- Private properties
				self._moduleId = #(parent._modules)
				self._hovered = false 
				self._callback = settings.Callback

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 
					local button = Library:GetObjects()['#MODULE_BUTTON']:Clone()

					-- localization
					instances.button = button 
					instances.clickbutton = button['#button'] -- surely not confusing Aware
					instances.title = button['#button']['#title']
				end

				-- Instance modification
				do 
					local instances = self.instances

					-- setup main instances
					do 
						instances.title.Text = settings.Title 

						instances.button.Parent = parent.instances.module_container
						instances.button.Visible = true
					end
				end

				-- Connections
				do 
					local instances = self.instances
					local clickButton = instances.clickbutton

					clickButton.MouseButton1Click:Connect(function() 
						self:Click()
					end) 

					clickButton.MouseEnter:Connect(function() 
						self._hovered = true 

						tween.Quick(clickButton, {
							BackgroundColor3 = clickButton:GetAttribute('_HoverColor')
						})
					end) 

					instances.clickbutton.MouseLeave:Connect(function() 
						self._hovered = false 

						tween.Quick(clickButton, {
							BackgroundColor3 = clickButton:GetAttribute('_MainColor')
						})
					end)
				end

				table.insert(parent._modules, self)

				return self 
			end
		end	

		return ModuleButton 
	end)();

	Classes.ModuleToggle = (function() 
		local ModuleToggle = {} do 
			ModuleToggle.__index = ModuleToggle
			ModuleToggle._class = 'ModuleToggle'

			setmetatable(ModuleToggle, Classes.Base)

			function ModuleToggle:Enable() 
				self._toggled = true

				local instances = self.instances 
				do 
					local color = self._hovered and '_EnabledHoverColor' or '_EnabledColor'

					tween.Quick(instances.icon_inner, {
						BackgroundColor3 = instances.icon_inner:GetAttribute(color);
						AnchorPoint = Vector2.new(1, 0.5);
						Position = UDim2.fromScale(1, 0.5);
					})

					tween.Quick(instances.icon_outer, {
						BackgroundColor3 = instances.icon_outer:GetAttribute(color);
					})

					tween.Quick(instances.title, {
						TextColor3 = instances.title:GetAttribute(color);
					})
				end

				if ( self._callback ) then
					task.spawn(self._callback, true)
				end

				return self 
			end

			function ModuleToggle:Disable() 
				self._toggled = false 

				local instances = self.instances 
				do 
					local color = self._hovered and '_DisabledHoverColor' or '_DisabledColor'

					tween.Quick(instances.icon_inner, {
						BackgroundColor3 = instances.icon_inner:GetAttribute(color);
						AnchorPoint = Vector2.new(0, 0.5);
						Position = UDim2.fromScale(0, 0.5);
					})

					tween.Quick(instances.icon_outer, {
						BackgroundColor3 = instances.icon_outer:GetAttribute(color);
					})

					tween.Quick(instances.title, {
						TextColor3 = instances.title:GetAttribute(color);
					})
				end

				if ( self._callback ) then
					task.spawn(self._callback, false)
				end

				return self 
			end

			function ModuleToggle:Toggle() 
				if ( self._toggled ) then
					self:Disable()
				else
					self:Enable()
				end

				return self 
			end

			-- Sets this toggle's state to the target value
			function ModuleToggle:SetState(value: boolean) 
				if ( value == true ) then 
					if ( self._toggled == false ) then
						self:Enable()
					end
				elseif ( value == false ) then
					if ( self._toggled == true ) then
						self:Disable()
					end
				end

				return self 
			end

			function ModuleToggle:SetCallback(callback) 
				if ( typeof(callback) ~= 'function' ) then
					return error('[ModuleToggle:SetCallback] Expected type "function" for argument "callback"', 2)
				end

				self._callback = callback 

				return self 
			end

			function ModuleToggle:GetValue() 
				return self._toggled
			end

			ModuleToggle.GetState = ModuleToggle.GetValue
			ModuleToggle.IsEnabled = ModuleToggle.GetValue
			ModuleToggle.GetToggleState = ModuleToggle.GetValue 

			function ModuleToggle:GetFlagValue() 
				return self:GetValue()
			end

			function ModuleToggle.new(parent, settings: {}) 
				local self = setmetatable({}, ModuleToggle)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 
				self.flag = settings.Flag

				-- Private properties
				self._moduleId = #(parent._modules)
				self._hovered = false 
				self._toggled = settings.State
				self._callback = settings.Callback

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 
					local toggle = Library:GetObjects()['#MODULE_TOGGLE']:Clone()

					-- localization
					instances.toggle = toggle 
					instances.detector = toggle['#detector']
					instances.title = toggle['#title']
					instances.icon_outer = toggle['#icon-outer']
					instances.icon_inner = toggle['#icon-outer']['#icon-inner']
				end

				-- Instance modification
				do 
					local instances = self.instances

					-- setup main instances
					do 
						instances.title.Text = settings.Title 

						instances.toggle.Parent = parent.instances.module_container
						instances.toggle.Visible = true
					end

					local icon_inner = instances.icon_inner
					local icon_outer = instances.icon_outer 
					local title = instances.title 

					if ( settings.State == true ) then
						icon_inner.AnchorPoint = Vector2.new(1, 0.5)
						icon_inner.Position = UDim2.fromScale(1, 0.5)

						icon_inner.BackgroundColor3 = icon_inner:GetAttribute('_EnabledColor')
						icon_outer.BackgroundColor3 = icon_outer:GetAttribute('_EnabledColor')

						title.TextColor3 = title:GetAttribute('_EnabledColor')
					else
						icon_inner.AnchorPoint = Vector2.new(0, 0.5)
						icon_inner.Position = UDim2.fromScale(0, 0.5)

						icon_inner.BackgroundColor3 = icon_inner:GetAttribute('_DisabledColor')
						icon_outer.BackgroundColor3 = icon_outer:GetAttribute('_DisabledColor')

						title.TextColor3 = title:GetAttribute('_DisabledColor')
					end
				end

				-- Connections
				do 
					local instances = self.instances
					local detector = instances.detector

					detector.MouseButton1Click:Connect(function() 
						self:Toggle()
					end) 

					detector.MouseEnter:Connect(function() 
						self._hovered = true 

						local color = self._toggled and '_EnabledHoverColor' or '_DisabledHoverColor'

						tween.Quick(instances.icon_inner, {
							BackgroundColor3 = instances.icon_inner:GetAttribute(color)
						})
						tween.Quick(instances.icon_outer, {
							BackgroundColor3 = instances.icon_outer:GetAttribute(color)
						})
						tween.Quick(instances.title, {
							TextColor3 = instances.title:GetAttribute(color)
						})
					end) 

					detector.MouseLeave:Connect(function() 
						self._hovered = false 

						local color = self._toggled and '_EnabledColor' or '_DisabledColor'

						tween.Quick(instances.icon_inner, {
							BackgroundColor3 = instances.icon_inner:GetAttribute(color)
						})
						tween.Quick(instances.icon_outer, {
							BackgroundColor3 = instances.icon_outer:GetAttribute(color)
						})
						tween.Quick(instances.title, {
							TextColor3 = instances.title:GetAttribute(color)
						})
					end)
				end

				table.insert(parent._modules, self)

				return self 
			end
		end	

		return ModuleToggle 
	end)();

	Classes.ModuleSlider = (function() 
		local ModuleSlider = {} do 
			ModuleSlider.__index = ModuleSlider
			ModuleSlider._class = 'ModuleSlider'

			setmetatable(ModuleSlider, Classes.Base)

			function ModuleSlider:SetCallback(callback) 
				if ( typeof(callback) ~= 'function' ) then
					return error('[ModuleSlider:SetCallback] Expected type "function" for argument "callback"', 2)
				end

				self._callback = callback 

				return self 
			end

			-- Returns a value converted to it's respective cursor position
			function ModuleSlider:_ValueToPosition(value: number) 
				local temp = ((value - self._minimum) / (self._maximum - self._minimum))

				if ( self._exponential ) then
					temp = self:_FromExponential(temp)
				end

				return temp 
			end

			-- Returns a cursor position converted to it's respective value
			function ModuleSlider:_PositionToValue(position: number) 
				if ( self._exponential ) then
					position = self:_ToExponential(position)
				end

				return round((position * (self._maximum - self._minimum)) + self._minimum, self._step) 
			end			

			function ModuleSlider:SetValue(value: number) 
				value = math.clamp(round(value, self._step), self._minimum, self._maximum)

				-- localize some stuff
				local instances = self.instances
				local connections = self.connections

				local entry = instances.entry 
				local cursor = instances.slider_cursor 

				-- setup animation
				if ( connections.sliderProcess ) then
					connections.sliderProcess:Disconnect()
				end

				local thisId = math.random(0, 10000)
				cursor:SetAttribute('_connectionId', thisId)

				-- setup anim vars 
				local currentValue = self._value -- the starter value
				local currentPosition = cursor.Position.X.Scale -- current cursor X 

				local targetValue = value -- the final value 
				local targetPosition = self:_ValueToPosition(targetValue) -- the final position

				connections.sliderProcess = runService.Heartbeat:Connect(function(deltaTime: number)

					currentPosition = lerp(currentPosition, targetPosition, 1 - math.exp(-25 * deltaTime))
					cursor.Position = UDim2.fromScale(currentPosition, 0.5)

					local tvalue = self:_PositionToValue(currentPosition)

					entry.Text = self._format:format(tvalue)
				end)

				task.delay(0.7, function() 
					if ( cursor:GetAttribute('_connectionId') == thisId ) then
						connections.sliderProcess:Disconnect()
					end
				end)

				self._value = value 
				if ( self._callback ) then
					task.spawn(self._callback, value)
				end

				return self 
			end

			-- An alternate version of :SetValue that has better performance when called often.
			-- Primarily used for linked sliders. Can optionally avoid calling the callback by passing true after the value.
			function ModuleSlider:SetValuePerformant(value: number, bypassCallback: boolean) 
				value = math.clamp(round(value, self._step), self._minimum, self._maximum)

				-- localize some stuff
				local instances = self.instances
				local connections = self.connections

				local entry = instances.entry 
				local cursor = instances.slider_cursor 

				-- setup anim vars 
				local currentValue = self._value -- the starter value
				local currentPosition = cursor.Position.X.Scale -- current cursor X 

				local targetPosition = self:_ValueToPosition(value) -- the final position

				cursor.Position = UDim2.fromScale(targetPosition, 0.5)
				entry.Text = self._format:format(value)

				self._value = value 

				if ( self._callback and ( bypassCallback ~= true ) ) then
					task.spawn(self._callback, value)
				end

				return self 
			end

			function ModuleSlider:_ToExponential(x: number)
				return x ^ self._exponent


				--return ( 2.5 / 7.071068 ) * x^2.5
			end

			function ModuleSlider:_FromExponential(x: number) 
				return x ^ ( 1 / self._exponent )
				--return 1.51571656651 * x^0.4
			end

			function ModuleSlider:GetValue() 
				return self._value
			end

			function ModuleSlider:GetFlagValue() 
				return self:GetValue()
			end


			function ModuleSlider.new(parent, settings: {}) 
				local self = setmetatable({}, ModuleSlider)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 
				self.flag = settings.Flag

				-- Private properties
				self._moduleId = #(parent._modules)
				self._hovered = false 

				self._value = settings.Value
				self._step = settings.Step 
				self._minimum = settings.Minimum
				self._maximum = settings.Maximum
				self._exponential = settings.Exponential
				self._exponent = settings.Exponent
				self._callback = settings.Callback
				self._style = settings.Style

				self._decimalCount = math.max((#tostring(self._step)) - (#string.format('%d', self._step) + 1), 0) -- gets length of normal format, subtracts by length of rounded format ( minus one for the decimal point, math.max in case there is no decimal )
				self._format = '%.' .. self._decimalCount .. 'f'				

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 

					local slider
					if ( self._style == 1 ) then 
						slider = Library:GetObjects()['#MODULE_SLIDERLARGE']:Clone()
					else
						slider = Library:GetObjects()['#MODULE_SLIDER']:Clone()
					end

					-- localization
					instances.slider = slider 
					instances.detector = slider['#detector'] 
					instances.bar_detector = slider['#bar-detector']
					instances.title = slider['#title']
					instances.slider_bar = slider['#bar-detector']['#slider-bar']
					instances.slider_cursor = instances.slider_bar['#icon-cursor']
					instances.entry = slider['#entry']
				end

				-- Instance modification
				do 
					local instances = self.instances

					local title = instances.title 
					local slider = instances.slider 
					local entry = instances.entry
					local bar_detector = instances.bar_detector 
					local cursor = instances.slider_cursor

					-- setup main instances
					do 
						title.Text = settings.Title 
						title.TextColor3 = title:GetAttribute('_MainColor')
						entry.TextColor3 = entry:GetAttribute('_MainColor')

						slider.Parent = parent.instances.module_container
						slider.Visible = true
					end

					-- setup slider scaling 
					do 
						if ( self._style == 0 ) then 
							title.Parent = Library:GetSource()
							local textBounds = title.TextBounds
							title.Parent = slider

							local sliderBounds = slider.AbsoluteSize

							local widthScale = (textBounds.X) / (sliderBounds.X - 6)

							title.Size = UDim2.new(widthScale, -6, 1, 0) -- calculated title width minus 6 for padding 
							bar_detector.Position = UDim2.new(widthScale, 12, 0, 0) -- calculated title width plus 12 for padding
							bar_detector.Size = UDim2.new(1 - widthScale - 0.2, -18, 0, 24) -- the entire slider minus title width minus entry box, minus 18 for extra padding
						end	
					end

					-- setup initial value
					do 
						local value = self._value 

						cursor.Position = UDim2.fromScale(self:_ValueToPosition(value), 0.5)

						entry.Text = self._format:format(value)
					end
				end

				-- Connections
				do 
					local instances = self.instances
					local detector = instances.detector
					local bar_detector = instances.bar_detector

					local entry = instances.entry
					local cursor = instances.slider_cursor

					local lastValue 
					cursor:SetAttribute('_connectionId', 0)

					self.connections.sliderBegin = bar_detector.InputBegan:Connect(function(input: InputObject) 
						if ( input.UserInputType == Enum.UserInputType.MouseButton1 ) then
							cursor:SetAttribute('_connectionId', cursor:GetAttribute('_connectionId') + 1) 

							local mousePosition = Vector2.new(input.Position.X, input.Position.Y)
							local barPosition = bar_detector.AbsolutePosition
							local barWidth = bar_detector.AbsoluteSize.X

							local delta = mousePosition - barPosition

							local targetPosition = delta.X / barWidth
							local currentPosition = cursor.Position.X.Scale

							do 
								local sliderProcess = self.connections.sliderProcess 
								local sliderUpdate = self.connections.sliderUpdate

								if ( sliderUpdate ) then
									sliderUpdate:Disconnect()
								end

								if ( sliderProcess ) then
									sliderProcess:Disconnect()
								end
							end


							self.connections.sliderProcess = runService.Heartbeat:Connect(function(deltaTime: number)
								targetPosition = math.clamp(targetPosition, 0, 1)

								currentPosition = lerp(currentPosition, targetPosition, 1 - math.exp(-25 * deltaTime))

								cursor.Position = UDim2.fromScale(currentPosition, 0.5)

								self._value = self:_PositionToValue(currentPosition)
								if ( self._callback ) then
									task.spawn(self._callback, self._value)
								end

								entry.Text = self._format:format(self._value)
							end)

							self.connections.sliderUpdate = inputService.InputChanged:Connect(function(input: InputObject) 
								if ( input.UserInputType == Enum.UserInputType.MouseMovement ) then
									local mousePosition = Vector2.new(input.Position.X, input.Position.Y)
									local delta = mousePosition - barPosition

									targetPosition = delta.X / barWidth
								end
							end)
						end
					end)

					self.connections.sliderEnd = bar_detector.InputEnded:Connect(function(input: InputObject) 
						if ( input.UserInputType == Enum.UserInputType.MouseButton1 ) then
							local sliderProcess = self.connections.sliderProcess 
							local sliderUpdate = self.connections.sliderUpdate

							local thisId = cursor:GetAttribute('_connectionId')

							if ( sliderUpdate ) then
								sliderUpdate:Disconnect()
							end

							if ( sliderProcess ) then
								task.delay(0.7, function() 
									if ( cursor:GetAttribute('_connectionId') ~= thisId ) then
										return 
									end

									sliderProcess:Disconnect()
								end)
							end
						end
					end)

					detector.MouseEnter:Connect(function() 
						self._hovered = true 

						tween.Quick(instances.slider_bar, {
							BackgroundColor3 = instances.slider_bar:GetAttribute('_HoverColor')
						})
						tween.Quick(instances.slider_cursor, {
							BackgroundColor3 = instances.slider_cursor:GetAttribute('_HoverColor')
						})
						tween.Quick(instances.title, {
							TextColor3 = instances.title:GetAttribute('_HoverColor')
						})
						tween.Quick(instances.entry, {
							TextColor3 = instances.entry:GetAttribute('_HoverColor')
						})
					end) 

					detector.MouseLeave:Connect(function() 
						self._hovered = false 

						tween.Quick(instances.slider_bar, {
							BackgroundColor3 = instances.slider_bar:GetAttribute('_MainColor')
						})
						tween.Quick(instances.slider_cursor, {
							BackgroundColor3 = instances.slider_cursor:GetAttribute('_MainColor')
						})
						tween.Quick(instances.title, {
							TextColor3 = instances.title:GetAttribute('_MainColor')
						})
						tween.Quick(instances.entry, {
							TextColor3 = instances.entry:GetAttribute('_MainColor')
						})
					end)

					entry.FocusLost:Connect(function(enterPressed: boolean) 
						if ( not enterPressed ) then
							return 
						end

						local text = tonumber(entry.Text)

						if ( not text ) then
							entry.Text = 'NaN'

							task.delay(1, function() 
								if ( entry.Text == 'NaN' ) then
									entry.Text = self._format:format(self._value)
								end
							end)

							return
						end

						self:SetValue(text)
					end)

					entry.Focused:Connect(function() 
						local cursor = self.instances.slider_cursor
						local sliderProcess = self.connections.sliderProcess

						if ( sliderProcess ) then
							sliderProcess:Disconnect()
						end

						cursor:SetAttribute('_connectionId', cursor:GetAttribute('_connectionId') + 1) 

						cursor.Position = UDim2.fromScale(self:_ValueToPosition(self._value), 0.5)
					end)
				end

				table.insert(parent._modules, self)

				return self 
			end
		end	

		return ModuleSlider 
	end)();

	Classes.ModuleLabelMulti = (function() 
		local ModuleLabelMulti = {} do 
			ModuleLabelMulti.__index = ModuleLabelMulti
			ModuleLabelMulti._class = 'ModuleLabelMulti'

			setmetatable(ModuleLabelMulti, Classes.Base)

			function ModuleLabelMulti:SetText(newText: string)
				if ( typeof(newText) ~= 'string' ) then
					newText = tostring(newText)
				end

				local label = self.instances.label
				local text = self.instances.text

				text.Text = newText

				return self 
			end

			function ModuleLabelMulti.new(parent, settings: {}) 
				local self = setmetatable({}, ModuleLabelMulti)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 

				-- Private properties
				self._moduleId = #(parent._modules)
				self._variadicHeight = true -- height can vary

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 
					local label = Library:GetObjects()['#MODULE_MULTILABEL']:Clone()

					-- localization
					instances.label = label 
					instances.text = label['#text']
				end

				-- Instance modification
				do 
					local instances = self.instances

					-- setup main instances
					do 
						self:SetText(settings.Text)

						instances.label.Parent = parent.instances.module_container
						instances.label.Visible = true
					end
				end

				table.insert(parent._modules, self)

				return self 
			end
		end	

		return ModuleLabelMulti 
	end)();

	Classes.Notification = (function() 
		local Notification = {} do 
			Notification.__index = Notification
			Notification._class = 'Notification'

			setmetatable(Notification, Classes.Base)

			function Notification:SetText(newText: string)
				if ( typeof(newText) ~= 'string' ) then
					newText = tostring(newText)
				end

				self.instances.text.Text = newText

				return self 
			end

			function Notification:Destroy() 
				self.instances.notification:Destroy()
				self.instances = nil 
				self.connections = nil
				self.parent = nil
				setmetatable(self, nil)
			end

			function Notification.new(parent, settings: {}) 
				local self = setmetatable({}, Notification)

				-- Public properties
				self.instances = {} 
				self.connections = {} 
				self.parent = parent 

				-- Private properties
				--self._notifId = #parent._notifs 

				local function getHeight() 
					local height = 0 

					for _, notif in ipairs(parent._notifs) do
						height += notif.instances.notification.AbsoluteSize.Y + 20
					end

					return height
				end

				-- Instance declaration
				do 
					local instances = self.instances
					-- creation 
					local notification = Library:GetObjects()['#NOTIFICATION']:Clone()

					-- localization
					instances.notification = notification 
					instances.text = notification['#content-container']['#text-container']['#text']
					instances.title = notification['#content-container']['#header-container']['#title']
					instances.trim = notification['#content-container']['#header-container']['#trim']
				end

				-- Instance modification
				do 
					local instances = self.instances
					instances.text.Text = settings.Text
					instances.title.Text = settings.Title 

					instances.notification.Parent = Library:GetNotifContainer()
					instances.notification.Visible = true
				end

				-- Notification processing
				do 
					local instances = self.instances
					local notification = instances.notification

					if ( settings.Silent == false ) then 
						notification['#sound']:Play()
					end

					notification.Position = UDim2.new(2.2, 0, 1, -getHeight())
					tween.Smooth(notification, {
						Position = UDim2.new(1, 0, 1, -getHeight())
					}, 0.3)

					tween.Linear(instances.trim['#gradient'], {
						Offset = Vector2.new(0, 0)
					}, settings.Duration)

					task.delay(settings.Duration, function() 
						table.remove(parent._notifs, table.find(parent._notifs, self))

						tween.Smooth(notification, {
							Position = UDim2.new(1, 0, 1.3, 0)
						}, 0.3)

						local height =  - notification.AbsoluteSize.Y

						for _, notif in ipairs(parent._notifs) do
							height += notif.instances.notification.AbsoluteSize.Y + 20

							tween.Smooth(notif.instances.notification, {
								Position = UDim2.new(1, 0, 1, -height)
							}, 0.3)
						end

						task.wait(0.3)

						self:Destroy()
					end)
				end

				table.insert(parent._notifs, self)

				return self 
			end
		end	

		return Notification 
	end)();
end

-- Create functions for the library
function Library:GetSource() 
	return librarySource 
end

function Library:GetObjects()
	return libraryObjects
end

function Library:GetNotifContainer() 
	return librarySource['#notification-container']
end

function Library:Destroy() 
	for i, conn in pairs(self.connections) do
		if ( typeof(conn) == 'thread' ) then
			task.cancel(conn)
		else
			conn:Disconnect()
		end
	end

	for _, window in ipairs(self._windows) do
		window:Destroy(true)
	end
	
	setmetatable(self, nil)
end

function Library:CreateWindow(options: {}) 
	local s_title = options.Title
	local s_draggable = options.Draggable 
	local s_defaultPos = options.DefaultPosition
	local s_defaultSize = options.DefaultSize 

	local s_build = options.Build 
	local s_buildPrefix = options.BuildPrefix

	local s_loader = options.Loader
	local s_loaderConfirm = options.LoaderConfirmation
	local s_loadTime = options.LoadTime
	local s_loadedCallback = options.LoadedCallback

	local s_retainToggles = options.RetainToggles 
	local s_destroyCallback = options.DestroyCallback

	if ( typeof(s_title) ~= 'string' ) then
		s_title = 'EVICTEDLIB'
	end

	if ( typeof(s_buildPrefix) ~= 'string' ) then
		s_buildPrefix = 'BUILD: '
	end

	if ( s_draggable ~= true ) then
		s_draggable = false 
	end

	if ( typeof(s_defaultPos) ~= 'UDim2' ) then
		s_defaultPos = UDim2.fromScale(0.6, 0.6)
	end

	if ( typeof(s_defaultSize) ~= 'UDim2' ) then
		s_defaultSize = UDim2.fromOffset(700, 400)
	end

	if ( s_build == nil ) then
		s_build = false 
	end

	if ( s_loader ~= true ) then
		s_loader = false 
	end

	if ( s_loaderConfirm ~= true ) then
		s_loaderConfirm = false
	end

	if ( typeof(s_loadTime) ~= 'number' ) then
		s_loadTime = 5
	end

	if ( typeof(s_loadedCallback) ~= 'function' ) then
		s_loadedCallback = nil 
	end

	if ( s_retainToggles ~= true ) then
		s_retainToggles = false
	end

	if ( typeof(s_destroyCallback) ~= 'function' ) then
		s_destroyCallback = nil
	end

	return Classes.Window.new(self, {
		Title = s_title; -- Title of window
		Draggable = s_draggable; -- If window is draggable 
		DefaultPosition = s_defaultPos; -- Default position
		DefaultSize = s_defaultSize; -- Default size

		Build = s_build; -- Build number
		BuildPrefix = s_buildPrefix; -- Build prefix

		LoaderConfirmation = s_loaderConfirm; -- If true, the loader has an OK button that needs to be pressed
		Loader = s_loader; -- If true, a loader screen will pop up on finalization
		LoadTime = s_loadTime; -- How long loading will take 
		LoadedCallback = s_loadedCallback; -- A function that gets called when loading finishes. If confirmation is enabled, the second argument will be true

		RetainToggles = s_retainToggles; -- Retains the state of toggles when the ui closes
		DestroyCallback = s_destroyCallback; -- A function that gets called with destruction of this window occurs
	})
end

function Library:Notify(settings: {})
	local s_duration = settings.Duration 
	local s_title = settings.Title 
	local s_text = settings.Text
	local s_silent = settings.Silent

	if ( typeof(s_duration) ~= 'number' ) then
		s_duration = 3 
	end

	if ( s_silent ~= true ) then
		s_silent = false
	end

	if ( typeof(s_title) ~= 'string' ) then
		s_title = 'Notification'
	end

	if ( typeof(s_text) ~= 'string' ) then
		s_text = 'Notification'
	end

	return Classes.Notification.new(self, {
		Duration = s_duration;
		Title = s_title;
		Text = s_text;
		Silent = s_silent;
	})
end

return Library 
