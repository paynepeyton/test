{
	stdenv,
	fetchFromGitHub,
	sddm,
	qt5,
	coreutils,
	themeConfig,
	...
}: 
	stdenv.mkDerivation rec {
		name = "sugarcandy-sddm-theme";
		src = fetchFromGitHub {
			owner = "Kangie";
			repo = "sddm-sugar-candy";
			rev = "a1fae5159c8f7e44f0d8de124b14bae583edb5b8";
			sha256 = "18wsl2p9zdq2jdmvxl4r56lir530n73z9skgd7dssgq18lipnrx7";
		};
		dontWrapQtApps = true;
		propagatedUserEnvPkgs = [
			sddm
			qt5.qtbase
			qt5.qtsvg
			qt5.qtgraphicaleffects
			qt5.qtquickcontrols2
		];
		nativeBuildInputs = [
			coreutils
		];
		installPhase =
		''
			local installDirectory = $out/share/sddm/themes/${name}
			mkdir -p $installDirectory
			cp -aR -t $installDirectory $src/{Main.qml, Assets, Components, metadata.desktop, theme.conf, Backgrounds}
			cat "${themeConfig}" > "$installDirectory/theme.conf"
		'';
	}
