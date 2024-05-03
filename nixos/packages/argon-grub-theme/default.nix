{
	stdenv,
	fetchFromGitHub,
	fetchurl,
	...
}:
	stdenv.mkDerivation {
		src = fetchFromGitHub {
			owner = "stuarthayhurst";
			repo = "argon-grub-theme";
			rev = "16ee6fc5e2b6cc9cf84ab22550ea3795e77054ff";
			sha256 = "19cl8cbbgl46rhgnjc23mnxrfs8ai7dmv6kcdsfdz66sfbhj12v8";
		};
		dontBuild = true;
		installPhase = let
			background = fetchurl {
				url = "https://raw.githubusercontent.com/paynepeyton/Nixdots/main/assets/images/background/grub.png";
				sha256 = "1nklxvzlsdm4f7xa1d2lxi0j52ajk64h3b0xmrkmi97r18yda281";
			};
			settings = builtins.toFile "theme.txt" ''
				title-text: ""
				desktop-image: "backgrounds/default.png"
				desktop-color: "#000000"
				terminal-left: "0%"
				terminal-top: "0%"
				terminal-width: "100%"
				terminal-height: "100%"
				terminal-border: "0"
				+ boot_menu {
					left = 25%
					top = 30%
					width = 50%
					height = 50%
					item_color = "#81A1C1"
					selected_item_color = "#81A1C1"
					icon_width = 48
					icon_height = 48
					item_icon_space = 26
					item_height = 56
					item_padding = 12
					item_spacing = 16
					selected_item_pixmap_style = "select_*.png"
				}
				+ label {
					top = 80%
					left = 35%
					width = 30%
					align = "center"
					id = "__timeout__"
					text = "Booting in %d seconds"
					color = "#81A1C1"
				}
			'';
		in ''
			mkdir -p $out/{icons,backgrounds}
			cp $src/assets/icons/48px/* $out/icons
			cp $src/assets/select/48px/* $out
			cp ${background} $out/backgrounds/default.png
			cp ${settings} $out/theme.txt	
		'';
	}
