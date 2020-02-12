# Pool Operator Helper Scripts #

```jor_wrapper``` and ```node_helpers``` are a set of ```bash``` scripts to help pool operators manage their nodes. These spun off [Chris G ```.bash_profile```](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/config/.bash_profile). I have *ported them to bash (scripts)*, improved some of the commands, adapted others to the ```NACG``` guide setup, and implemented brand new features. You will still be able to use ```jor_wrapper``` and the ```node_helpers``` scripts, regardless of the guide you used to set up your pool. However, they work best if you followed the ```NACG``` guide, as they are tailored to system configurations you would setup with it (e.g: ```systemctl``` and ```journalctl```).

**If you have followed guides other than ```NACG``` to set up your pool, to fully take advantange of these scripts, all you need to add are the ```systemd``` and logging (```rsyslogd``` and ```logrotate```) integrations from the [```NACG``` guide](NACG.md).**

## Contribution ##

If you have suggestions on how to improve these scripts, please [file an issue](https://github.com/gacallea/cardanoRelatedStuff/issues) on Github.

## License ##

```jor_wrapper``` and the ```node_helpers``` scripts are licensed under the terms of the [GPLv3](scripts/LICENSE) license.

## Download ##

This page assumes that the system will be managed with ```root```. To use these scripts, simply clone this repository and place them in ```/root``` like so:

```text
cd /root
git clone https://github.com/gacallea/cardanoRelatedStuff.git
cp -af cardanoRelatedStuff/scripts/node_helpers /root/
cp -af cardanoRelatedStuff/scripts/jor_script/* /root/
```

## jor_wrapper ##

## node_helpers ##

The ```node_helpers``` scripts take care of a number of *ancillary* aspects:

- ```blocks_backup.sh```: regularly backups ```blocks.sqlite``` to offer a safety net.
- ```syncdumpcache.sh```: monitors the system cache usage, and forces a sync based on a threshold.
- ```stuckrestart.sh```: monitors the node sync and restarts it under certain conditions.

### blocks backup ###

Having to restart your node is currently a nuisance, and it can take a long time to bootstrap, especially if your node was significantly out of sync before the restart. Backing up your ```blocks.sqlite``` with ```blocks_backup.sh``` at a regular interval, via cron, can offer a safety net from where to recover in such cases.

All you need to do to take advantage of ```blocks_backup.sh```, is to place it in a convenient location, say ```/root/node_helpers/blocks_backup.sh```, and setup a ```root``` crontab (**crontab -e**). The following would run a backup of ```blocks.sqlite``` every hour:

```0 */1 * * * /root/node_helpers/blocks_backup.sh```

The script has a data retention of 24h, and it removes older backups automatically. You won't need anything older than a day. **Just be mindful of your disk space when setting this up**. At the time of this writing, bzipped ```blocks.sqlite``` files backup take around **100MB** each. So if you backup every hour, 100MB times the number of files (24), **constantly takes 2.4GB** of your disk space.

### cache sync ###

At the time of this writing, I noticed that keeping the system cache under control and forcing a sync at a threshold, helps with the node health. I'm sure that future ```jormungandr``` version will eventually fix this, but for the time being I'm experimenting with this. I will file an issue on IOHK's GitHub to let them know about it, for the good of everyone.

To take advantage of ```syncdumpcache.sh```, all you need to do is to place it in a convenient location, say ```/root/node_helpers/syncdumpcache.sh```, and setup a ```root``` crontab (**crontab -e**). The following would run the checks every ten minutes. This does **not** mean that it will force the sync every ten minutes, that depends on the threshold set in the script:

```*/10 * * * * /root/node_helpers/syncdumpcache.sh```

The script will check the system cache usage and intervene with a forced sync after the threshold (**it defaults to 4096)**. If your server only runs ```jormungandr```, the system cache would 100% reflect ```jormungandr``` cache. Adjust the values to suit your system, if it runs anything else. Be mindful that **anything more aggressive than the default threshold value could break your node**.

### stuck restart ###

**THIS SCRIPT IS EXPERIMENTAL AND NEEDS FINE TUNING AND TESTING, USE AT YOUR OWN RISK.**

At times, the node could lag behind by a significant margin. When this happens, the node sync goes bananas and it's time to restart it. ```stuckrestart.sh``` monitors the node sync against two conditions, and restarts the node if those are met. The first condition is a **blocks date delta** and, if this is met, it goes on to check the second one. The second condition is to check when **lastReceivedBlockTime** was last modified. If that lags behind for more than 5 minutes, the script restarts the node.

To take advantage of ```stuckrestart.sh```, all you need to do is to place it in a convenient location, say ```/root/node_helpers/stuckrestart.sh```, and setup a ```root``` crontab (**crontab -e**). The following would run the checks every fifteen minutes. This does **not** mean that it will force the restart every fifteen minutes, that depends on the thresholds set in the script:

```*/15 * * * * /root/node_helpers/stuckrestart.sh```

## some useful commands ##

It's not a secret that my ```jor_wrapper``` scripts spun off [Chris G ```.bash_profile```](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/config/.bash_profile). However, some of his *aliases* have been removed in my version. Things such as ```get_pid``` are considered redundant in ```jor_wrapper``` and in [my guide](NACG.md). This is because I favor and promote system administration over them, and I'd rather teach users *to fish*. For example, if you need to get ```jormungandr```'s ```pid```, there's no need for a convoluted ```grep```; just run ```pidof jormungandr```. Hence, I hereby list a number of one-liners and commands, to help you with your server administration.

### get jormungandr's pid ###

```pidof jormungandr```

### quick resources usage ###

This is also available in ```jor_wrapper```, but I wanted to make a point: how using the proper way to get the ```pid```, can help in other commands too.

```top -b -n 4 -d 0.2 -p $(pidof jormungandr) | tail -2```

### keep an eye on storage ###

If you want to keep an eye on when storage is being written and updated, you could run the following. This is totally subjective, and you are free to ignore it. I personally like to have that bit of info in front of me at all times. Change the path to your storage location:

``` watch 'ls -l /home/poolrun/storage'```

### monitor node connections ###

```watch 'netstat -tn | tail -n +3 | awk "{ print \$6 }" | sort | uniq -c | sort -nr'```

## more tools ##

### tmux ###

Most people, even seasoned system administrators, are more familiar with ```screen``` when it comes to convenience. ```tmux``` is a modern ```screen``` on steroids. It's more recent, it offers more in terms of malleability and it does a lot more than ```screen```.

If you are not familiar with either, they are tools that allow you to run multiple terminal sessions in background. This is particularly useful in server administration, because it allows you to run sessions that won't terminate your processes when you logout of the server (unless rebooted). You can ```ssh``` into your server, and reconnect to your sessions, at any time, and have it readily available for your administration needs.

Learn more about ```tmux``` on its [official GitHub](https://github.com/tmux/tmux/wiki), and how to use it on the precious [tmux cheatsheet website](https://tmuxcheatsheet.com/). If you need a guide, [this is a good one](https://linuxize.com/post/getting-started-with-tmux/).

### htop ###

 ```htop``` is a must have ```top``` on steroids. Run it with the ```-u``` flag to monitor your pool service user (if you have setup your node with [my guide](NACG.md)). Alternatively, run ```htop``` and filter by users by pressing ```u``` once it's open.

 ```htop -u pooluser```

### cbm ###

```cbm``` is an old piece of software, but it still serves its purpose quite well. It is a simple real-time bandwidth monitor that runs in a terminal. Useful to quickly check if your node traffic, from which you can deduce its status. If you have followed ```NACG```, you get this too. Here's [a guide](https://www.tecmint.com/cbm-shows-network-bandwidth-traffic-in-ubuntu/) showing ```cbm``` usage.

### dotfiles ###

With my repo, you also get a number of [dotfiles](dotfiles/) that are useful if you do use the tools I suggest above. Feel free to use them to make the most of them. Or come up with your own. It's up to you.

## send your tip to pooltool ##
