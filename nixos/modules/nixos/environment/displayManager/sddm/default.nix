{
	config,
	lib,
	pkgs,
	...
}:
	let
		inherit (lib) attrNames getAttr getExe optionalString optionalAttrs concatStringsSep concatMapStrings recursiveUpdate;
		inherit (lib.options) mkOption;
		inherit (lib.types) bool str package enum listOf;
		inherit (lib.modules) mkIf;

		sddm = config.environment.displayManager.sddm;
		xserver = config.services.xserver;
		displayManager = config.services.displayManager;
		systemd = config.systemd;

		xserverWrapper = pkgs.writeShellScript "xserver-wrapper" ''
			${concatMapStrings (n: "export ${n}=\"${getAttr n systemd.services.display-manager.environment}\"\n") (attrNames systemd.services.display-manager.environment)}
			exec systemd-cat -t xserver-wrapper ${xserver.displayManager.xserverBin} ${toString xserver.displayManager.xserverArgs} "$@"
		'';
		setupCommands = pkgs.writeShellScript "setupCommands" ''
			${sddm.settings.setupCommands}
			${xserver.displayManager.setupCommands}
		'';
		stopCommands = pkgs.writeShellScript "stopCommands" ''
			${sddm.settings.stopCommands}
		'';

		compositorCommands = {
			kwin = concatStringsSep " " [
				"${lib.getBin pkgs.kdePackages.kwin}/bin/kwin_wayland"
				"--no-global-shortcuts"
				"--no-kactivities"
				"--no-lockscreen"
				"--locale1"
    		];
			weston = let
				westonIni = (pkgs.formats.ini { }).generate "weston.ini" {
					libinput = {
						enable-tap = config.services.libinput.mouse.tapping;
						left-handed = config.services.libinput.mouse.leftHanded;
					};
					keyboard = {
						keymap_model = xserver.xkb.model;
						keymap_layout = xserver.xkb.layout;
						keymap_variant = xserver.xkb.variant;
						keymap_options = xserver.xkb.options;
					};
				};
			in	"${getExe pkgs.weston} --shell=kiosk -c ${westonIni}";
		};

		defaultConfig = {
			General = {
				DisplayServer = if sddm.settings.wayland.enable then "wayland" else "x11";
				DefaultSession = optionalString (displayManager.defaultSession != null) "${displayManager.defaultSession}.desktop";
				Numlock = if sddm.settings.numlock.enable then "on" else "none";
				HaltCommand = "/run/current-system/systemd/bin/systemctl poweroff";
				RebootCommand = "/run/current-system/systemd/bin/systemctl reboot";
			}	// optionalAttrs (sddm.settings.wayland.compositor == "kwin") {
				GreeterEnvironment = concatStringsSep " " [
					"LANG=C.UTF-8"
					"QT_WAYLAND_SHELL_INTEGRATION=layer-shell"
				];
				InputMethod = "";
			};
			Theme = {
				ThemeDir = "/run/current-system/sw/share/sddm/themes";
				FacesDir = "/run/current-system/sw/share/sddm/faces";
				Current = sddm.settings.theme;
				CursorTheme = sddm.settings.cursor.name;
				CursorSize = sddm.settings.cursor.size;
			};
			User = {
				MaximumUid = config.ids.uids.nixbld;
				HideUsers = concatStringsSep "," displayManager.hiddenUsers;
				HideShells = "/run/current-system/sw/bin/nologin";
				RememberLastSession = true;
				RememberLastUser = true;
			};
			X11 = optionalAttrs xserver.enable {
				MinimumVT = if xserver.tty != null then xserver.tty else 7;
				ServerPath = toString xserverWrapper;
				XephyrPath = "${pkgs.xorg.xorgserver.out}/bin/Xephyr";
				SessionCommand = toString displayManager.sessionData.wrapper;
				SessionDir = "${displayManager.sessionData.desktops}/share/xsessions";
				XauthPath = "${pkgs.xorg.xauth}/bin/xauth";
				DisplayCommand = toString setupCommands;
				DisplayStopCommand = toString stopCommands;
				EnableHiDPI = sddm.settings.hidpi.enable;
			};
			Wayland = {
				SessionDir = "${displayManager.sessionData.desktops}/share/wayland-sessions";
				CompositorCommand = lib.optionalString sddm.settings.wayland.enable compositorCommands.${sddm.settings.wayland.compositor};
				EnableHiDPI = sddm.settings.hidpi.enable;
			};
		};

		iniFormat = pkgs.formats.ini { };

		configFile = iniFormat.generate "sddm.conf" (recursiveUpdate defaultConfig sddm.settings.extraConfig);

		finalPackage = sddm.settings.package.override (previous: {
			withWayland = sddm.settings.wayland.enable;
			extraPackages = previous.extraPackages or [ ] ++ sddm.settings.extraPackages;
		});
	in
		{
			options.environment.displayManager.sddm = {
				enable = mkOption {
					type = bool;
					default = false;
				};
				settings = {
					package = mkOption {
						type = package;
						default = pkgs.plasma5Packages.sddm;
					};
					extraPackages = mkOption {
						type = listOf package;
						default = [ ];
					};
					setupCommands = mkOption {
						type = str;
						default = "";
					};
					stopCommands = mkOption {
						type = str;
						default = "";
					};
					hidpi = {
						enable = mkOption {
							type = bool;
							default = false;
						};
					};
					wayland = {
						enable = mkOption {
							type = bool;
							default = false;
						};
						compositor = mkOption {
							type = enum (builtins.attrNames compositorCommands);
							default = "weston";
						};
					};
					numlock = {
						enable = mkOption {
							type = bool;
							default = false;
						};
					};
					theme = mkOption {
						type = str;
						default = "";
					};
					cursor = {
						name = mkOption {
							type = str;
							default = "";
						};
						size = mkOption {
							type = str;
							default = "24";
						};
					};
				};
			};

			config = mkIf sddm.enable {
				assertions = [
					{
						assertion = xserver.enable || sddm.settings.wayland.enable;
						message = "SDDM requires either services.xserver.enable or environment.displayManager.sddm.settings.wayland.enable to be true";
					}
				];
				services = {
					displayManager = {
						enable = true;
						execCmd = "exec /run/current-system/sw/bin/sddm";
					};
					dbus = {
						packages = [
							finalPackage
						];
					};
					xserver = {
						tty = null;
						display = null;
					};
				};
				security = {
					pam = {
						services = {
							sddm = {
								text = ''
									auth      substack      login
									account   include       login
									password  substack      login
									session   include       login
								'';
							};
							sddm-greeter = {
								text = ''
									auth     required       pam_succeed_if.so audit quiet_success user = sddm
									auth     optional       pam_permit.so

									account  required       pam_succeed_if.so audit quiet_success user = sddm
									account  sufficient     pam_unix.so

									password required       pam_deny.so

									session  required       pam_succeed_if.so audit quiet_success user = sddm
									session  required       pam_env.so conffile=/etc/pam/environment readenv=0
									session  optional       ${systemd.package}/lib/security/pam_systemd.so
									session  optional       pam_keyinit.so force revoke
									session  optional       pam_permit.so
								'';
							};
						};
					};
				};
				users = {
					groups = {
						sddm = {
							gid = config.ids.gids.sddm;
						};
					};
					users = {
						sddm = {
							createHome = true;
							home = "/var/lib/sddm";
							group = sddm;
							uid = config.ids.uids.sddm;
						};
					};
				};
				environment = {
					etc = {
						"sddm.conf" = {
							source = configFile;
						};
					};
					pathToLink = [
						"/share/sddm"
					];
					systemPackages = [
						finalPackage
					];
				};
				systemd = {
					tmpfiles = {
						packages = [
							finalPackage
						];
					};
					services = {
						display-manager = {
							after = [
								"systemd-user-sessions.service"
								"getty@tty7.service"
								"plymouth-quit.service"
								"systemd-logind.service"
							];
							conflicts = [
								"getty@tty7.service"
							];
						};
					};
				};
			};
		}
