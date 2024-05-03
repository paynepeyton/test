{
	device,
	...
}: {
	disko = {
		devices = {
			disk = {
				main = {
					inherit device;
					type = "disk";
					content = {
						type = "gpt";
						partitions = {
							esp = {
								type = "EF00";
								size = "512M";
								content = {
									type = "filesystem";
									format = "vfat";
									mountpoint = "/boot/efi";
								};
							};
							swap = {
								size = "4G";
								content = {
									type = "swap";
									resumeDevice = true;
								};
							};
							root = {
								size = "100G";
								content = {
									type = "filesystem";
									format = "ext4";
									mountpoint = "/";
								};
							};
							home = {
								size = "100%";
								content = {
									type = "filesystem";
									format = "ext4";
									mountpoint = "/home";
								};
							};
						};
					};
				};
			};
		};
	};
}
