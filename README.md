# Chris G Guide Addendum #

## Notes ##

- some changes would be easily integrated into your guide, some others may require one too many changes, it's up to you what you want to integrate :)
- besides giving back to the community with the scripts, I'm also pondering if I should create another guide from a more advanced (sysadmin) perspective and link/refer to the ones that helped/inspired me (or when reinventing the wheel would be an ass move).
- apologies for the *short notes* style, this is preliminary and I would rather chat about the nitty gritty details, and take it from there.
- in case you are wondering "*where this notes come from*", this is me: [https://linkedin.com/in/gacallea/](https://linkedin.com/in/gacallea/)
- please don’t share just yet and ask away if you need to clarify something
- I’d love to hear your thoughts and understand what you will integrate in your guide and how
- cheers and thank you for your availability.

### ADDENDUM NOTES ###

### create the 'ssh-users' group ###

- finer ssh login control and more security
- check out '*AllowedGroups*' SSH option
- regarding the ```sshd_config``` file, [read why](https://www.ssh.com/ssh/tunneling#ssh-tunneling-in-the-corporate-risk-portfolio) it is bad to leave SSH tunneling on (e.g: like lovelypool suggests for remote monitoring)

```bash
groupadd ssh-users
```

### create non-root login user to ssh and sudo ###

- there's no need to edit visudo
- single command is enough

```bash
useradd -c "user to ssh and sudo" -m -d /home/<YOUR_SYSTEM_USER> -s /bin/bash -G sudo,ssh-users <YOUR_SYSTEM_USER>
```

#### double-check that your new user is in both the sudo and ssh-users groups ####

```bash
groups <YOUR_SYSTEM_USER>
```

#### it should show ####

```bash
<YOUR_SYSTEM_USER> : <YOUR_SYSTEM_USER> sudo ssh-users
```

### create non-root user to run the pool. ###

- this user neither needs a login shell nor a password
- this reduces surface attack by not exposing a user with a shell on top of alpha quality software
- see ```jormungandr.service``` file for how the pool is run as this user

```bash
useradd -c "user to run the pool" -m -d /home/<YOUR_POOL_USER> -s /sbin/nologin <YOUR_POOL_USER>
passwd -d <YOUR_POOL_USER>
```

### install extra packages ###

- no need for compiling tools (no build-essentials, no rust either)
- this also reduces risks
- some of the installed tools are used in my scripts, some others you know already
  - ```bc``` is used for calculations
  - ```cbm``` is a nice real-time bandwidth monitor for the terminal
  - ```ccze``` for coloring, no need to reinvent that
  - ```dateutils``` is used for date related calculations
  - ```fail2ban``` to keep script kiddies at bay
  - ```htop``` is a must have ```top``` on steroids
  - ```ripgrep``` is available with ```apt``` :)
  - ```speedtest-cli``` in case you need a speed test for your server

```bash
apt update
apt upgrade
apt install bc cbm ccze chrony curl dateutils fail2ban git htop jq net-tools ripgrep speedtest-cli sysstat tcptraceroute wget
```

### no need to compile ###

- if you omit compilations steps, average joe won't even notice, super users will compile anyway...
- handle the updates the same way (```apt``` or ```curl``` for new jormungandr releases)
- ```/usr/local/bin/``` is there for this specific purpose (user installed binary files)

```bash
curl -sLOJ https://github.com/input-output-hk/jormungandr/releases/download/v0.8.9/jormungandr-v0.8.9-x86_64-unknown-linux-gnu.tar.gz
tar xzvf jormungandr-v0.8.9-x86_64-unknown-linux-gnu.tar.gz
mv jcli /usr/local/bin/
mv jormungandr /usr/local/bin/
chmod +x /usr/local/bin/jcli
chmod +x /usr/local/bin/jormungandr
```

### install tcpping ###

```bash
curl http://www.vdberg.org/~richard/tcpping -o /usr/local/bin/tcpping
chmod +x /usr/local/bin/tcpping
```

### see sshd_config for more secure config ###

- main reason to use such a config is better security
- use fail2ban as well (installed with the above ```apt```), default config is great

### download scripts + some config files ###

- a link to repo + a nice note to describe the scripts maybe?
- honestly, I need to generate buzz for INSL. I have no delegations, and I’m running out of money for the pool.
- a “shout out” in your guide with the git clone link would be helpful.

```bash
git clone -- this is where my scripts and files would go
```

### place the scripts in ```/root/``` (not the 'scripts' folder, the scripts only) ###

- manage system/pool and run the scripts, with root since the pool user is a "service user"

```bash
mv scripts/jor_wrapper scripts/jor_config scripts/jor_funcs /root/
mv scripts/nodehelperscripts/blocks_backup.sh /root/
```

### files notes ###

- ```sysctl -p``` is enough.
- no need to add anything to ```/etc/rc.local```
- ILAP:
  - ```/etc/security/limits.conf```
  - ```/etc/sysctl.conf```
- LovelyPool:
  - ```/etc/chrony/chrony.conf```
- my own files:
  - ```/home/<YOUR_POOL_USER>/node-config.yaml```
  - ```/etc/ssh/sshd_config```
  - ```/etc/systemd/system/jormungandr.service```
  - ```/etc/rsyslog.d/90-jormungandr.conf```
  - ```/etc/logrotate.d/jormungandr```
- no need for directories creation. my scripts takes care of the directories it needs.
- ```get_pid``` is redundant. it is not in my scripts. I'd teach the user to use ```pidof jormungandr``` instead.
- start, stop, and restart, are provided by systemd, hence have been removed from the script.
- ```/etc/systemd/system/jormungandr.service``` it's only valid for a leader node. May need to add a "start as passive node" perhaps?
- logging is managed at a system level with usual tools. script has wrappers for less linux prone users.

### END OF ADDENDUM NOTES ###

In the (near?) future I will implement (and add to a guide?)

1) proper remote monitoring with [Prometheus](https://prometheus.io/) and [Grafana](https://grafana.com/) (will ponder security as priority).
2) "stuck sentinel" restart script for when the node is stuck or has serious sync issues.
3) IDS/IPS with [Suricata IDS](https://suricata-ids.org/).
4) proper [nftables](https://netfilter.org/projects/nftables/) firewall (which allows for more).
5) perhaps one day, if my pool goes well, I will implement [Ansible](https://www.ansible.com/) and [Docker](https://www.docker.com/) to expand.
