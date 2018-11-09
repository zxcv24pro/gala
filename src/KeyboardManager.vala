//
//  Copyright (C) 2016 Santiago León
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

namespace Gala
{
	public class KeyboardManager : Object
	{
		static KeyboardManager? instance;
		static VariantType sources_variant_type;
		static unowned X.Display xdisplay;
		static List<unowned X.Xkb.Desc> keymaps;

		public static void init (Meta.Display display)
		{
			if (instance != null)
				return;

			instance = new KeyboardManager ();

			display.modifiers_accelerator_activated.connect (instance.handle_modifiers_accelerator_activated);
			xdisplay = display.get_xdisplay ();
		}

		static construct
		{
			sources_variant_type = new VariantType ("a(ss)");
		}

		GLib.Settings settings;

		KeyboardManager ()
		{
			Object ();
		}
		
		construct
		{
			var schema = GLib.SettingsSchemaSource.get_default ().lookup ("org.gnome.desktop.input-sources", true);
			if (schema == null)
				return;

			settings = new GLib.Settings.full (schema, null, null);
			Signal.connect (settings, "changed", (Callback) set_keyboard_layout, this);

			set_keyboard_layout (settings, "current");
		}

		[CCode (instance_pos = -1)]
		bool handle_modifiers_accelerator_activated (Meta.Display display)
		{
			display.ungrab_keyboard (display.get_current_time ());

			var sources = settings.get_value ("sources");
			if (!sources.is_of_type (sources_variant_type))
				return true;

			var n_sources = (uint) sources.n_children ();
			if (n_sources < 2)
				return true;

			var current = settings.get_uint ("current");
			settings.set_uint ("current", (current + 1) % n_sources);

			return true;
		}

		// TODO: Add options argument
		void compile_keymaps (string layouts[])
		{
			string layout = "us", variant = "";

			keymaps = new List<unowned X.Xkb.Desc> ();
			foreach (unowned string curr in layouts) {
				string[] arr = curr.split ("+", 2);
				layout = arr[0];
				variant = arr[1] ?? "";

				// TODO: Get ComponentNames from RMLVO configuration.
				X.Xkb.ComponentNames names = new X.Xkb.ComponentNames ();
				names.keymap = null;
				names.keycodes = "evdev+aliases(qwerty)";
				names.types = "complete";
				names.compat = "complete";
				string symbols = "pc+%s+inet(evdev)+group(alt_shift_toggle)".printf (curr);
				names.symbols = symbols;
				names.geometry = "pc(pc105)";

				unowned X.Xkb.Desc desc =
				X.Xkb.get_keyboard_by_name (xdisplay,
											X.Xkb.UseCoreKbd,
											names,
											X.Xkb.GBN.AllComponentsMask,
											X.Xkb.GBN.AllComponentsMask,
											false);
				keymaps.append (desc);
			}
		}

		void set_keymap (uint idx)
		{
			X.Xkb.set_map (xdisplay, X.Xkb.GBN.AllComponentsMask, keymaps.nth_data(idx));
		}

		[CCode (instance_pos = -1)]
		void set_keyboard_layout (GLib.Settings settings, string key)
		{
			if (!(key == "current" || key == "sources" || key == "xkb-options"))
				return;

			var sources = settings.get_value ("sources");
			if (!sources.is_of_type (sources_variant_type))
				return;

			var current = settings.get_uint ("current");

			string options = "";
			var xkb_options = settings.get_strv ("xkb-options");
			if (xkb_options.length > 0)
				options = string.joinv (",", xkb_options);

			if (xdisplay != null) {
				// When Gala is working in X11, keymaps are precompiled and
				// cached in the keymaps list.
				// This is done because compilation is done inside X11 and
				// takes a long time at least for some layouts like 'br' or
				// 'ru'. This seems to be related to Scroll_Lock modifiers.
				// See issue #220.
				if (key == "sources" || key == "xkb-options" || keymaps.length() == 0) {
					// Precompilation is executed anytime the "sources" or
					// "xkb-options" keys change.

					string[] keymaps = {};
					unowned string? type = null, name = null;
					for (int idx=0; idx < sources.n_children (); idx++) {
						sources.get_child (idx, "(&s&s)", out type, out name);
						if (type == "xkb") {
							keymaps += name;
						} else {
							keymaps += "us";
						}
					}

					if (sources.n_children () == 0) {
						keymaps += "us";
					}

					compile_keymaps (keymaps);
				}

				set_keymap (current);

			} else {
				string layout = "us", variant = "";

				if (current < sources.n_children()) {
					unowned string? type = null, name = null;
					sources.get_child (current, "(&s&s)", out type, out name);
					string[] arr = name.split ("+", 2);
					if (type == "xkb") {
						layout = arr[0];
						variant = arr[1] ?? "";
					}
				}

				// Needed to make common keybindings work on non-latin layouts
				if (layout != "us" || variant != "") {
					layout = layout + ",us";
					variant = variant + ",";
				}

				Meta.Backend.get_backend ().set_keymap (layout, variant, options);
			}
		}
	}
}
