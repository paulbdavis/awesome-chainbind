-- awesome-modalbind - modal keybindings for awesomewm

local awesome, client, mouse, screen, tag = awesome, client, mouse, screen, tag
local chainbind = {}
local wibox = require("wibox")
local awful = require("awful")
local beautiful = require("beautiful")
local dpi = require("beautiful.xresources").apply_dpi
local gears = require("gears")
local nesting = 0
local verbose = false

local defaults = {
   {"Control"}, "t",
   name = "Root",
   bind_trigger = true,
   universal_exit = {{"Control"}, "g"},
   map       = {},
}

local function hide_bindings(self)
   -- print("-- hide_bindings called --")
   
   local s = mouse.screen

   local bar = self.widget
   
   bar:setup{
      layout=wibox.layout.fixed.horizontal,
   }

   -- bar.visible = false
end

local color_cycle = beautiful.chainbind_color_cycle or {
   beautiful.fg_focus,
   beautiful.fg_normal,
   beautiful.fg_urgent,
}

local function get_color(index)
   local i = (index+1)%(#color_cycle+1)
   if i == 0 then i = 1 end
   return color_cycle[i]
end

local function format_binding(key)
   local keybind = {}
   for i, m in ipairs(key[1] or {}) do
      if m == "Control" then
         keybind[#keybind+1] = "C"
      elseif m == "Mod1" then
         keybind[#keybind+1] = "M"
      elseif m == "Mod4" then
         keybind[#keybind+1] = "s"
      elseif m == "Shift" then
         keybind[#keybind+1] = "S"
      end
   end

   local final_key = key[2]
   if final_key == " " then
      final_key = "SPC"
   elseif final_key == "Return" then
      final_key = "RET"
   end

   keybind[#keybind+1] = awful.util.escape(final_key)

   local description = key.description
   if not description and key.map then
      description = key.name
   end

   local table = table

   return table.concat(keybind, "-"), awful.util.escape(description or "")
end

local function binding_key_shape(cr, width, height)
   return gears.shape.rectangular_tag(cr, width, height, (-1 * height)/2)
end

local function get_binding_widget(index, key)
   local bg = beautiful.chainbind_bind_description_bg or beautiful.bg_normal
   local bind_bg = get_color(index-1)
   local fg = beautiful.chainbind_bind_description_fg or beautiful.fg_normal
   local shape = binding_key_shape
   local lpad = dpi(15)
   local rpad = dpi(5)

   if not key.description and key.map then
      bg = beautiful.chainbind_submap_description_bg or beautiful.bg_normal
      fg = beautiful.chainbind_submap_description_fg or beautiful.bg_normal
      bind_bg = get_color(index)
      shape = gears.shape.powerline
      lpad = dpi(15)
      rpad = dpi(15)
   end
   
   local keybind, description = format_binding(key)
   
   return {
      {
         {
            {
               {
                  id = "binding",
                  align = "left",
                  markup = "<b>"..keybind.."</b>",
                  font = beautiful.chainbind_font or "Monospace 10",
                  widget=wibox.widget.textbox,
               },
               left=lpad,
               right=rpad,
               layout=wibox.container.margin
            },
            bg=bind_bg,
            fg=beautiful.chainbind_key_fg or bg,
            shape=shape,
            layout=wibox.container.background,
         },
         {
            {
               id = "binding",
               align = "left",
               markup = description,
               font = beautiful.chainbind_font or "Monospace 10",
               widget=wibox.widget.textbox,
            },
            left=dpi(5),
            right=rpad,
            layout=wibox.container.margin
         },
         layout=wibox.layout.fixed.horizontal,
      },
      bg=bg,
      fg=fg,
      shape=shape,
      layout=wibox.container.background,
   }
end

local function show_bindings(self)
   -- print("-- show_bindings called by ".. self.map_name .." --")
   -- local wbox = wibox({
   --       width=80,
   --       height=20,
   --       bg=beautiful.zenburn_orange,
   --       fg=beautiful.bg_normal,
   --       shape=gears.shape.powerline,
   --       type="normal"
   -- })

   local s = mouse.screen

   local bar = self.widget

   if bar.timer then
      bar.timer:stop()
   end
   
   local map_crumbs = {
      layout = wibox.layout.fixed.horizontal,
      spacing = -13,
   }

   for i, p in ipairs(self.parents) do
      local left_pad = 15
      if i == 1 then
         left_pad = 20
      end
      -- print("adding parent "..p)
      map_crumbs[#map_crumbs+1] = {
         {
            {
               id = "mapname",
               align = "left",
               markup = "<b>"..awful.util.escape(p).."</b>",
               font = beautiful.chainbind_font or "Monospace 10",
               widget=wibox.widget.textbox,
            },
            left=dpi(left_pad),
            right=dpi(15),
            layout=wibox.container.margin
         },
         bg=get_color(#map_crumbs),
         fg=beautiful.bg_normal,
         shape=gears.shape.powerline,
         layout=wibox.container.background,
      }
   end

   -- print("adding self "..self.name)

   local left_pad = 15
   if #map_crumbs == 0 then
      left_pad = 20
   end
      
   map_crumbs[#map_crumbs+1] = {
      {
         {
            id = "mapname",
            align = "left",
            markup = "<b>"..awful.util.escape(self.map_name).."</b>",
            font = beautiful.chainbind_font or "Monospace 10",
            widget=wibox.widget.textbox,
         },
         left=dpi(left_pad),
         right=dpi(15),
         layout=wibox.container.margin
      },
      bg=get_color(#map_crumbs),
      fg=beautiful.bg_normal,
      shape=gears.shape.powerline,
      layout=wibox.container.background,
   }

   local map_bindings = {
      layout = wibox.layout.fixed.horizontal,
      spacing = dpi(5),
   }

   local submap_bindings = {
      layout = wibox.layout.fixed.horizontal,
      spacing = dpi(5),
   }

   local crumb_count = #map_crumbs
   for i, k in ipairs(self.map) do
      local wdgt = get_binding_widget(crumb_count, k)
      if k.map then
         map_crumbs[#map_crumbs+1] = wdgt
      else
         map_bindings[#map_bindings+1] = wdgt
      end
   end

   bar:setup({
         {
            {
               id="crumbs",
               layout = wibox.layout.flex.horizontal,
               map_crumbs
            },
            left = self.left_offset or -15,
            right = 10,
            layout=wibox.container.margin
         },
         {
            map_bindings,
            speed = 30,
            -- step_function = wibox.container.scroll.step_functions.linear_back_and_forth,
            layout = wibox.container.scroll.horizontal,
         },
         submap_bindings,
         layout = wibox.layout.align.horizontal,

   })

   -- bar.visible = true

   -- local crumbs = bar:get_children_by_id("crumbs")
   -- for i, c in ipairs(crumbs:get_children()) do
   --    local txt = c.get_children_by_id("mapname")
   --    local x, y = txt:get_preferred_size(s)
   --    c.width = x + 30
   -- end
   
end

local function handle_keypress (self)

   show_bindings(self)
   
end


local function send_trigger(self, mods, key)
   -- print("sending trigger key")
   -- gears.debug.dump(mods, "mods")
   -- gears.debug.dump(key, "key")
   local current_keys = root.keys()
   self:stop()
   root.keys({})
   
   local translated_mods = {}
   for i, m in ipairs(mods) do
      if m == "Mod4" then
         m = "Super_L"
      elseif m == "Mod1" then
         m = "Alt_L"
      else
         m = m .. "_L"
      end
      translated_mods[i] = m
   end
   
   -- gears.debug.dump(translated_mods, "translated_mods")
   for i, m in ipairs(translated_mods) do
      -- print("releasing "..m)
      root.fake_input('key_release'  , m)
   end
   
   -- os.execute("sleep 0.1")
   
   for i, m in ipairs(translated_mods) do
      -- print("pressing "..m)
      root.fake_input('key_press'  , m)
   end
   
   -- os.execute("sleep 0.05")
   
   -- print("pressing "..key)
   root.fake_input('key_press', key)
   
   -- os.execute("sleep 0.1")
   
   -- print("releasing "..key)
   root.fake_input('key_release', key)
   
   -- os.execute("sleep 0.05")
   
   for i, m in ipairs(translated_mods) do
      -- print("releasing "..m)
      root.fake_input('key_release'  , m)
   end
   
   root.keys(current_keys)
   -- self:start()
   return false
end

local function keypress_matches(_key, mods, key)
   for i, k in ipairs(_key) do
      if awful.key.match(k, mods, key) then
         return true
      end
   end
   return false
end

function chainbind.start(options)
   -- show_bindingos()
   local grabber = mouse.screen.chaingrabber

   grabber:start()
end

function build_grabber(screen, options)
   local options = options or defaults
   
   -- print("building grabber "..options.name)
   
   local uni_exit = options.universal_exit or defaults.universal_exit
   local exit_key = uni_exit[2] or "g"
   local exit_mods = uni_exit[1] or {"Control"}
   
   local grabber = awful.keygrabber{
      stop_key = options.stop_key or "Escape",
      start_callback = show_bindings,
   }

   grabber.stop_callback = function () hide_bindings(grabber) end

   grabber:add_keybinding(exit_mods, exit_key,
                          function ()
                             grabber:stop()
                             hide_bindings(grabber)
                          end,
                          {
                             description = "End chain",
                             group = options.name or ""
                          }
   )
   
   if options.bind_trigger then
      grabber:add_keybinding({}, options[2],
         function ()
            gears.timer {
               timeout = 0.2,
               autostart = true,
               single_shot = true,
               callback = function()
                  send_trigger(grabber, options[1], options[2])   
               end
            }
            
         end,
         {
            description = "Send trigger keys",
            group = options.name
         }
      )
   end

   for i, mapping in ipairs(options.map) do
      if mapping.action then
         -- print("mapping action to "..options.name.." map")
         grabber:add_keybinding(mapping[1], mapping[2],
                                function ()
                                   -- print("grabber " .. options.name .. " command")
                                   mapping.action()
                                   if not mapping.no_stop then
                                      grabber:stop()
                                      hide_bindings(grabber)
                                   end
                                end,
                                {
                                   description = mapping.description or "", group = options.name or "",
                                }
         )
      else if mapping.map then
            -- print("adding sub map "..mapping.name.." to "..options.name.." map")
            local parents = {}
            for i, p in ipairs(options.parents or {}) do
               parents[i] = p
            end
            parents[#parents+1] = options.name
            local sub_grabber = build_grabber(screen, {
                  name = mapping.name or "",
                  map = mapping.map,
                  universal_exit = uni_exit,
                  parents = parents,
                  display_widget = options.display_widget,
                  left_offset = options.left_offset,
            })
            grabber:add_keybinding(mapping[1], mapping[2],
                                   function ()
                                      -- print("grabber " .. options.name .. " sub triggered " .. mapping.name)
                                      grabber:stop()
                                      sub_grabber:start()
                                   end, {description = mapping.name or "", group = "Sub Maps"})
           end
      end
   end

   grabber.map = options.map or {}
   grabber.parents = options.parents or {}
   grabber.map_name = options.name or ""
   grabber.widget = options.display_widget[screen.index]
   grabber.left_offset = options.left_offset or -15
   
   return grabber
end

function chainbind.create(options)
   
   options = options or defaults
   
   local trigger_mods = options[1] or {"Control"}
   local trigger_key = options[2] or "t"

         
   awful.screen.connect_for_each_screen(function(s)
         if not options.display_widget then
            options.display_widget = {}
         end
         
         if not options.display_widget[s.index]
         then
            options.display_widget[s.index] = awful.wibar({
                  position = "bottom",
                  screen = s,
            })
         end
         
         s.chaingrabber = build_grabber(s, options)
         
   end)


   return awful.key(trigger_mods, trigger_key, function () chainbind.start(options) end, {description = "Start " .. (options.name or "Root") .. " map", group = "chainbind"})
end


return chainbind
