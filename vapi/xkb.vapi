/* Manually created, so feel free to add and adjust it directly */
namespace X {
	[CCode (cheader_filename = "X11/XKBlib.h")]
	namespace Xkb {
		[CCode (cname = "XkbUseCoreKbd")]
		public const int UseCoreKbd;

		[CCode (cname = "unsigned int", cprefix = "XkbGBN_", has_type_id = false)]
		public enum GBN {
			TypesMask,
			CompatMapMask,
			ClientSymbolsMask,
			ServerSymbolsMask,
			SymbolsMask,
			IndicatorMapMask,
			KeyNamesMask,
			GeometryMask,
			OtherNamesMask,
			AllComponentsMask
		}

		[CCode (cname = "XkbComponentNamesRec", has_type_id = false)]
		public struct ComponentNames {
			public unowned string keymap;
			public unowned string keycodes;
			public unowned string types;
			public unowned string compat;
			public unowned string symbols;
			public unowned string geometry;
		}

		[CCode (cname = "XkbDescRec")]
		public class Desc {
		}

		[CCode (cname = "XkbGetKeyboardByName")]
		public static unowned Xkb.Desc get_keyboard_by_name (X.Display display, uint device_spec, Xkb.ComponentNames names, uint want, uint need, bool load);

		[CCode (cname = "XkbSetMap")]
		public static bool set_map (X.Display display, int which, Xkb.Desc xkb);
	}
}
