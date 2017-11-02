# Update Scripts

You’ll find somes scripts into [notifier/scripts/updates](https://github.com/EyesOfNetworkCommunity/notifier/tree/master/scripts/updates).

## Check script
The script [check_config_file.sh](https://github.com/EyesOfNetworkCommunity/notifier/tree/master/scripts/updates/check_config_file.sh) permit to launch a summary test on rules configuration files.

This check consist only to parse all lines of configuration and verify fields number on line.  
It return output on all line, and sort fields number and line checked.

## Update script
You'll find to somes scripts (for example v2.1_to_v2.1-1.sh) will permit to update notifier version.

On standard EyesOfNetwork you've only to launch script according to version you have and newer version you'll install.  
If you launch the update script, the script [check_config_file.sh](https://github.com/EyesOfNetworkCommunity/notifier/tree/master/scripts/updates/check_config_file.sh) will be automaticaly launched considering path provided if you've done this.

## Informations
If you're on non standard EyesOfNetwork deployement, please consider to read usage of each scripts :
```bash
sh v2.1_to_v2.1-1.sh help
sh check_config_file.sh help
```
