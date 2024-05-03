{
	inputs = {
		nixpkgs = {
			url = "github:nixos/nixpkgs/nixos-unstable";
		};
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		snowfall-lib = {
			url = "github:snowfallorg/lib";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		snowfall-flake = {
			url = "github:snowfallorg/flake";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		hyprland = {
			url = "github:hyprwm/Hyprland";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		hyprpaper = {
			url = "github:hyprwm/hyprpaper";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		hyprlock = {
			url = "github:hyprwm/hyprlock";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		hypridle = {
			url = "github:hyprwm/hypridle";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		ags = {
			url = "github:Aylur/ags";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		nixvim = {
			url = "github:nix-community/nixvim";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
		disko = {
			url = "github:nix-community/disko";
			inputs = {
				nixpkgs = {
					follows = "nixpkgs";
				};
			};
		};
	};

	outputs = inputs: with inputs;
		let
			lib = snowfall-lib.mkLib {
				inherit inputs;
				src = ./.;
				snowfall = {
					namespace = "snowfall";
				};
			};
		in 
			lib.mkFlake {
				channels-config = {
					allowUnfree = true;
				};
				overlays = with inputs; [
					snowfall-flake.overlay
				];
				systems = {
					hosts = {
						"L15ACH6" = {
							specialArgs = {
								inherit inputs;
							};
						};
					};
				};
			};
}
