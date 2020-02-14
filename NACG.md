# Not Another Cardano Guide #

- [Not Another Cardano Guide](#not-another-cardano-guide)
  - [The Guide](#the-guide)
    - [License](#license)
    - [System](#system)
    - [Updates](#updates)
    - [Contributions](#contributions)
  - [Prepare Your System](#prepare-your-system)
    - [ssh-users group](#ssh-users-group)
    - [non-root login user](#non-root-login-user)
      - [set password and keys](#set-password-and-keys)
    - [non-root service user](#non-root-service-user)
    - [install extra packages](#install-extra-packages)
      - [install from apt](#install-from-apt)
      - [install jormungandr and jcli](#install-jormungandr-and-jcli)
      - [install tcpping](#install-tcpping)
  - [Create & Register Your Pool](#create--register-your-pool)
  - [Configure Your System](#configure-your-system)
    - [configure backend](#configure-backend)
    - [configure firewalld](#configure-firewalld)
    - [configure sshd](#configure-sshd)
    - [configure fail2ban](#configure-fail2ban)
    - [configure chrony](#configure-chrony)
    - [configure limits](#configure-limits)
    - [configure systemd](#configure-systemd)
    - [configure logging](#configure-logging)
    - [configure node](#configure-node)
  - [What's Next](#whats-next)
    - [Helping Hands](#helping-hands)
    - [Pool Operator Tools](#pool-operator-tools)
      - [Pool Tool](#pool-tool)
      - [Stake Pool Bootstrap Channel](#stake-pool-bootstrap-channel)
      - [Other Resources](#other-resources)
    - [Telegram](#telegram)

## The Guide ##

This guide is written with experienced users in mind. Things like creating a GitHub account, creating and using a pair of ssh keys, are a given. If you think you need help with those - there's nothing wrong with it - you should refer to Chris's [guide for newbs](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/docs/jormungandr_node_setup_guide.md).

This guide won't reinvent the wheel either. Its focus are the system and the node itself, and it will point you to [IOHK](https://iohk.io/)'s, when it's time to create, fund, and register your pool. IOHK [**guide**](https://github.com/input-output-hk/shelley-testnet/blob/master/docs/stake_pool_operator_how_to.md) and [**scripts**](https://github.com/input-output-hk/jormungandr-qa/tree/master/scripts) are all you need, and they are **official**.

The only note worth adding, before you venture into configuring a server and creating a pool, is that **you need to have enough tADA** - meaning ADA coins that were **in your wallet before the November 2019** snapshot - to register your pool. Otherwise, you won't be able to proceed with the pool registration.

**IMPORTANT**: this guide helps you configure and run a single pool with a single leader candidate node. If you are planning to run passive nodes, this guide assumes that you know what you are doing (and it won't be explained here).

### License ###

This guide is licensed under the terms of a Creative Commons [**CC BY-NC-SA 4.0**](https://creativecommons.org/licenses/by-nc-sa/4.0/). If you are not familiar with Creative Commons licenses, here's a bit [I wrote about them](https://gacallea.info/posts/a-primer-on-linux-open-source-and-copyleft-hackers-included/#creative-commons) that clarify what Creative Commons licenses are about.

### System ###

This guide will be focusing on the latest **Debian stable**, and assumes you already have your server installed with a vanilla Debian 10 (Buster), **that you can already ```ssh``` into on port ```22```**. This guide will stick to official repositories, with the exception for ```jormungandr```, ```jcli```, and ```tcpping```. This guide will stick with best practices for stability (e.g: [backports](https://backports.debian.org/) vs [unstable](https://wiki.debian.org/DontBreakDebian)).

Lastly, this guide assumes that you are familiar with Linux, its shell, its commands and have some experience in managing a server. This guide will promote system administration over shortcuts and aliases. For example, it will favor and configure ```systemd``` over aliases to manage the node. It will favor using ```pidof jormungandr``` instead of configuring an alias. In this guide you'll be also configuring system wide logging, and using ```journalctl``` over typing "*logs*". You get the idea.

### Updates ###

This guide will help you setup your server to accomodate a pool, but you won't find remote monitoring in here (just yet). This is because I have not implemented it on [INSL](https://insalada.io/) yet. I don't write about things I haven't had direct experience with. Once I'll have done so, and tested it, I will add a monitoring section to the guide. The same goes for any useful feature that could help pool owners run and manage the server and the pool. Follow [insaladaPool](https://twitter.com/insaladaPool) for future updates.

### Contributions ###

**If you have comments, changes, and suggestions, please [file an issue](https://github.com/gacallea/cardanoRelatedStuff/issues) on Github**. Any insight is valuable and will be considered for integration and improvements. If these resources help you in any way, consider [buying me a beer](https://seiza.com/blockchain/address/Ae2tdPwUPEZGcgwWYE3wKGcpn9cfPmADjwegQqBnTrcBfsexUkbxnT4sciw).

## Prepare Your System ##

The guides assumes that the system will be managed with ```root```. Don't worry, to ```ssh``` and ```sudo```, there will be a dedicated **non-root user**. To run the pool, yet another *service user*, with neither a shell nor privileges. So, if you are wondering if the pool will run as ```root```, the answer is **no way.** Systemd will take care of running the pool as the *service user*. A *service user* without a shell or a password, means less surface attack for an hacker trying to exploit *testing quality* software.

**Let's get started.**

### ssh-users group ###

Firstly, you need to create a group for a finer ssh login control and for an added layer of security. If you want to understand how this works and improves security, it is simple: it adds a restriction that will allow ```ssh``` connections from users who are in the ```ssh-users``` group **only**. Later in the guide, you'll also find a ```sshd_config``` file with more enhancements and restrictions.

```text
groupadd ssh-users
```

Make sure that the ```ssh-users``` group was successfully created:

```text
grep "ssh-users" /etc/group
```

It should return something like the following (the ```gid``` will likely be different for your system):

```text
ssh-users:x:998
```

### non-root login user ###

This is **your main user** that you will be using to ```ssh``` into the server and to ```sudo``` to ```root```, to manage your system. Make sure to replace ```<YOUR_SYSTEM_USER>``` with your user name of choice. **If you already have such user** that you actively ```ssh``` and ```sudo``` with, you can skip creating one, but make sure you add it to ```sudo``` and ```ssh-users``` groups.

For a new user run:

```text
useradd -c "user to ssh and sudo" -m -d /home/<YOUR_SYSTEM_USER> -s /bin/bash -G sudo,ssh-users <YOUR_SYSTEM_USER>
```

For an existing user run:

```text
usermod -aG sudo,ssh-users <YOUR_EXISTING_USER>
```

Double-check that your user (either ```<YOUR_SYSTEM_USER>``` or ```<YOUR_EXISTING_USER>```) is in both the ```sudo``` and ```ssh-users``` groups. **This step is important, don't skip it**. Later will be setting up ```sshd``` to only allow ```ssh``` from this group only. **You risk of locking yourself out**.

```text
groups <YOUR_SYSTEM_USER>
```

It should show the following:

```text
<YOUR_SYSTEM_USER> : <YOUR_SYSTEM_USER> sudo ssh-users
```

#### set password and keys ####

**Set a password for your login user, and enable your public ssh keys in the users' "```~/.ssh/authorized_keys```" file, or you will lock yourself out.**

### non-root service user ###

Running a service exposed to the Internet, with a user who has a shell it is not a wise choice, to use an euphemism. This is why you are creating a dedicated user to run the service. This is also standard practice for services in Linux. Think of ```nginx```, for example. It has both a user and a group, directories, configurations, and some permissions; but it doesn't need neither a shell nor password. Because exposing a shell to the outside world is a security risk. This reduces the attack surface on the server.

Make sure to replace ```<YOUR_POOL_USER>``` with your user name of choice, and take a note of it. You will be needing this username later in the guide when you will configure ```systemd``` and the scripts.

```text
useradd -c "user to run the pool" -m -d /home/<YOUR_POOL_USER> -s /sbin/nologin <YOUR_POOL_USER>
passwd -d <YOUR_POOL_USER>
```

### install extra packages ###

This guide assumes that you are familiar with compilation, and that you know why and when compilation is necessary or useful, and that you are capable of compiling. Therefore, during this guide you **won't** be compiling ```jormungandr``` or ```jcli```. If you reckon that compiling will give you more, knock yourself out. If you compile, is advisable to do it on a dedicated environment, or cross-compile, and transfer the binaries to the pool server.

#### install from apt ####

Some of the installed tools are used in my scripts, some others serve system administration purposes:

- ```bc``` is used for calculations in my scripts
- ```cbm``` is a nice real-time bandwidth monitor for the terminal
- ```chrony``` is used for better time sync
- ```ccze``` is for coloring commands output
- ```dateutils``` is used for date related calculations in my scripts
- ```fail2ban``` to keep script kiddies at bay
- ```firewalld``` is used for ```nftables``` configuration
- ```htop``` is a must have ```top``` on steroids
- ```jq``` if you want to send your stats to [PoolTool.io](https://pooltool.io/health)
- ```ripgrep``` is used in my scripts
- ```speedtest-cli``` in case you need a good speed test for your server

```text
apt-get update
apt-get upgrade
apt-get install bc cbm ccze chrony curl dateutils fail2ban htop jq net-tools ripgrep speedtest-cli sysstat tcptraceroute wget
```

Make sure that the ```backports``` repository is enabled in ```/etc/apt/sources.list```, and install ```firewalld``` and ```nftbales```:

```text
apt-get -t buster-backports install firewalld nftables
```

#### install jormungandr and jcli ####

You should stick [to the latest stable release](https://github.com/input-output-hk/jormungandr/releases), unless it introduces regressions. The following works for the current release for a ```x86_64``` architecture (PC/Mac - Intel/AMD Server) and [GNU](https://www.gnu.org/) ```glibc```.

```text
curl -sLOJ https://github.com/input-output-hk/jormungandr/releases/download/v0.8.10-2/jormungandr-v0.8.10-2-x86_64-unknown-linux-gnu.tar.gz
tar xzvf jormungandr-v0.8.10-2-x86_64-unknown-linux-gnu.tar.gz
mv jcli /usr/local/bin/
mv jormungandr /usr/local/bin/
chmod +x /usr/local/bin/jcli
chmod +x /usr/local/bin/jormungandr
chown -R root\: /usr/local/bin/
```

#### install tcpping ####

This is going to be the only alien piece of software, besides pool software, that you will be installing from a source that is not from official Debian repositories. It is used in my scripts.

```text
curl http://www.vdberg.org/~richard/tcpping -o /usr/local/bin/tcpping
chmod +x /usr/local/bin/tcpping
```

## Create & Register Your Pool ##

Without a pool, there's no point in going any further. Before you can proceed with system configurations, now it is a good time to follow [IOHK](https://github.com/input-output-hk)'s [**guide**](https://github.com/input-output-hk/shelley-testnet/blob/master/docs/stake_pool_operator_how_to.md) and use their [QA Team](https://github.com/input-output-hk/jormungandr-qa) [**scripts**](https://github.com/input-output-hk/jormungandr-qa/tree/master/scripts) to create, register and start your leader candidate node.

Come back after you have successfully completed **all** the necessary steps, and once your pool will be started as a leader candidate and it will be available on Daedalus and Yoroi (testnet versions).

Should you need help at any stage of your pool operator journey, join the '[Cardano Shelley Testnet & StakePool Best Practice Workgroup](https://t.me/CardanoStakePoolWorkgroup)' group on Telegram; it is packed with knowledge, and great and helpful people.

## Configure Your System ##

Now that you have a pool with a registered ticker (congrats!!!), it is time to configure your system. When it comes to the firewall, this guide focuses on ```nftables``` and ```firewalld``` instead of ```iptables``` and ```ufw```. For two simple reasons: ```nftables``` is the successor of ```iptables```, and it is the [default on Debian](https://wiki.debian.org/DebianFirewall). As far the firewall front-end goes, ```firewalld``` supports ```nftables```. This is why it is used in this guide, and ```ufw``` just doesn't support ```nftables``` yet.

To configure your system, you'll be using configuration files and scripts that are either provided by me or linked to other great guides. Always remember to **adapt them to your system**,  where it's needed.

### configure backend ###

By default Debian doesn't have any front-end installed nor a firewall configured, and the underlying settings for ```iptables``` should already be pointing to the ```nft``` backend. To make sure that your system does point to ```/usr/sbin/iptables-nft```; run the following, and select "```/usr/sbin/iptables-nft 20 auto mode```".

```text
update-alternatives --config iptables
```

### configure firewalld ###

A controversial note, first: believe it or not, if your server is only running ```sshd``` and ```jormungandr``` a firewall is not really necessary. Both services need an open port, the ```jcli``` REST API runs locally, and there's not other running service to externally attack. You could skip the firewall configuration, change the ```sshd``` port and install ```fail2ban```; that would be good enough.

However, setting up a firewall is something this guide will help you do. This guide will help you configure ```nftables``` with ```firewalld```, because in the future it will come in handy for *extra features* I'll be adding to this guide *soon*. Stay tuned.

First things first, let's make ```firewalld``` use the ```nftables``` backend, instead of ```iptables```. Edit ```/etc/firewalld/firewalld.conf```, and change the backend to ```nftables``` and turn logging for drops on. Everything else must stay untouched.

```text
FirewallBackend=nftables
LogDenied=all
```

It is now time to decide the ports for your public services, namely ```sshd``` and ```jormungandr```. These will be the ports that they will be listening on, and that you will need to open on ```firewalld```. To make things a little easier, you should choose ports that match existing ```firewalld``` services. Alternatively, you could add and enable your own services by following the [official documentation](https://firewalld.org/documentation/howto/add-a-service.html). To check which services are available in ```firewalld``` to choose from, run:

```text
firewall-cmd --get-services
```

My suggestion is to choose two services that you know your server would never run. For example, ```svn``` and ```xmpp-server```.

```text
firewall-cmd --info-service=svn
firewall-cmd --info-service=xmpp-server
```

This guide will bind ```jormungandr``` to ```3690``` and ```sshd``` to ```5269```; respectively ```svn``` and ```xmpp-server```. Once you have chosen your services, you need to enable them.

**IMPORTANT**: Since you haven't configured ```sshd``` yet, make sure to add it to the enabled services! You'll be configuring you custom ```ssh``` port of choice next (hereby ```5269```). Afterwards, you will remove ```ssh``` (port ```22```) from the ```firewalld``` rules.

```text
firewall-cmd --permanent --zone=public --add-service=ssh
firewall-cmd --permanent --zone=public --add-service=svn
firewall-cmd --permanent --zone=public --add-service=xmpp-server
```

Double check that they are enabled with:

```text
firewall-cmd --list-services
```

To enable the ```nftables``` backend, and to enable the firewall rules you have just set, you need to ```reboot``` the server. This is to ditch ```iptables``` and switch to ```nftables``` completely. If ```sshd``` is still running on port ```22``` as this guide assumes, you'll be fine.

```text
reboot
```

Once you log back in, Make sure everything is fine for your ```public``` zone, before you continue with ```ssh``` configuration.

```text
firewall-cmd --list-all
```

It should show the folowing:

```text
public
  target: default
  icmp-block-inversion: no
  interfaces:
  sources:
  services: dhcpv6-client ssh svn xmpp-server
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

To confirm that you have switched from ```iptables``` to ```nftables``` completely, run the following commands:

```text
iptables -nL
```

The above should return an empty ```iptables```:

```text
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
```

The following should return your new ```nftables``` rules:

```text
nft list ruleset
```

### configure sshd ###

You'll be enabling some additional restrictions, and disabling some features that are enabled by default. Like tunneling and forwarding. [Read why](https://www.ssh.com/ssh/tunneling#ssh-tunneling-in-the-corporate-risk-portfolio) it is bad to leave SSH tunneling on. Some guides suggest to tunnel into your remote server for monitoring purposes. This is bad practice, and a security risk. Make sure you have the following configured in ```/etc/ssh/sshd_config```; everything else can be commented out.

**IMPORTANT:** your new ```sshd``` port ```<YOUR_SSH_PORT>``` must match whatever service you have picked up in ```firewalld```, this guide uses ```5269``` for ```xmpp-server```.

```text
Port <YOUR_SSH_PORT>
Protocol 2

LoginGraceTime 2m
PermitRootLogin no
StrictModes yes
MaxAuthTries 6
MaxSessions 10

PubkeyAuthentication yes
IgnoreRhosts yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes

X11Forwarding no
PrintMotd no

ClientAliveInterval 300
ClientAliveCountMax 2

AllowTcpForwarding no
AllowStreamLocalForwarding no
GatewayPorts no
PermitTunnel no

AllowGroups ssh-users

AcceptEnv LANG LC_*

Subsystem       sftp    /usr/lib/openssh/sftp-server
```

Restart the ```sshd``` server, and ```ssh``` into the server from another terminal to test the new configuration..

```text
systemctl restart sshd.service
```

Make **absolutely sure** you can ```ssh``` into your server with the newly configured port, disable ```ssh``` (**port ```22```**), and restart the ```firewalld``` service:

```text
firewall-cmd --permanent --zone=public --remove-service=ssh
```

```text
systemctl restart firewalld.service
```

### configure fail2ban ###

While ```fail2ban``` doesn't offer perfect security - [*security is a process, not a product*](https://www.schneier.com/essays/archives/2000/04/the_process_of_secur.html) - it serves its purpose. The default ```fail2ban``` configuration is generally good enough. Usually, one would copy the ```jail``` configuration file, add the server IP to ```ignoreip```, change the ban time-related parameters if he wants to, enable the ```sshd``` jail, restart the service, and be good to go.

However, since this guide use ```firewalld```, you need to adjust a couple of settings. Copy the ```jail.conf``` file to one you will configure, and edit it:

```text
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

Make sure you have these (everything else can be left alone) configurations:

- "```ignorself = true```"
- "```ignoreip = 127.0.0.1/8 ::1 <YOUR_NODE_PUBLIC_IP>```"
- "```enabled = true```" for the ```sshd``` jail
- "```banaction = firewallcmd-multiport```"
- "```banaction_allports = firewallcmd-allports```"
- "```action = firewallcmd-allports[name=NoAuthFailures]```"
- "```banaction = firewallcmd-multiport-log```"

Restart and make sure that ```fail2ban``` is properly running, with these two commands:

```text
systemctl restart fail2ban.service
fail2ban-client status
```

It should return:

```text
Status
|- Number of jail:      1
`- Jail list:   sshd
```

### configure chrony ###

This is the first of three files configurations that are borrowed from other great guides. There's no need to reinvent the wheel here, so I'm pointing you to [LovelyPool](https://github.com/lovelypool/)'s [chronysettings](https://github.com/lovelypool/cardano_stuff/blob/master/chronysettings.md) guide instead, but still provide the configuration for your convenience.

Make sure to **read** Lovelypool's **Chrony Settings** guide, to understand it fully, and to know why to use ```chrony```.

Place this in ```/etc/chrony/chrony.conf```:

```text
pool time.google.com       iburst minpoll 1 maxpoll 2 maxsources 3

# This directive specify the location of the file containing ID/key pairs for
# NTP authentication.
keyfile /etc/chrony/chrony.keys

# This directive specify the file into which chronyd will store the rate
# information.
driftfile /var/lib/chrony/chrony.drift

# Uncomment the following line to turn logging on.
#log tracking measurements statistics

# Log files location.
logdir /var/log/chrony

# Stop bad estimates upsetting machine clock.
maxupdateskew 5.0

# This directive enables kernel synchronisation (every 11 minutes) of the
# real-time clock. Note that it can’t be used along with the 'rtcfile' directive.
rtcsync

# Step the system clock instead of slewing it if the adjustment is larger than
# one second, but only in the first three clock updates.
makestep 0.1 -1

# Get TAI-UTC offset and leap seconds from the system tz database.
leapsectz right/UTC

# Serve time even if not synchronized to a time source.
local stratum 10
```

Restart Chrony:

```tet
systemctl restart chronyd.service
```

### configure limits ###

These are the other two, and last, files that I borrowed from other great guides. This time I borrowed from [Ilap](https://github.com/ilap/)'s [guide](https://gist.github.com/ilap/54027fe9af0513c2701dc556221198b2). For convenience, I do provide the configuration for these too. Again, **read** his reasoning [here](https://gist.github.com/ilap/54027fe9af0513c2701dc556221198b2), and check often for his updates.

Place these at the bottom of your ```/etc/security/limits.conf```:

```text
root soft nofile 32768
<YOUR_POOL_USER> soft nofile 32768
<YOUR_POOL_USER> hard nofile 1048577
```

Place these at the bottom of your ```/etc/sysctl.conf```:

```text
fs.file-max = 10000000
fs.nr_open = 10000000

net.core.netdev_max_backlog = 100000
net.core.somaxconn = 100000
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.ip_nonlocal_bind = 1
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 100000
net.ipv4.tcp_max_tw_buckets = 262144
net.ipv4.tcp_mem = 786432 1697152 1945728
net.ipv4.tcp_reordering = 3
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_sack = 0
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 5
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_wmem = 4096 16384 16777216

net.netfilter.nf_conntrack_max = 10485760
net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 15

vm.swappiness = 10
```

Load your newly configured variables:

```text
sysctl -p /etc/sysctl.conf
```

### configure systemd ###

It is time to manage ```jormungandr``` as you would manage any other service on your server: with ```root``` and ```systemd```. Place the following in ```/etc/systemd/system/jormungandr.service```, and **make sure to change** ```<YOUR_POOL_USER>``` and ```<REST_API_PORT>``` to match your system:

```text
[Unit]
Description=Shelley Staking Pool
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/jormungandr --config node-config.yaml --secret node-secret.yaml --genesis-block-hash 8e4d2a343f3dcf9330ad9035b3e8d168e6728904262f2c434a4f8f934ec7b676
ExecStop=/usr/local/bin/jcli rest v0 shutdown get -h http://127.0.0.1:<REST_API_PORT>/api
StandardOutput=journal
StandardError=journal
SyslogIdentifier=jormungandr

LimitNOFILE=32768

Restart=on-failure
RestartSec=5s
WorkingDirectory=~
User=<YOUR_POOL_USER>
Group=<YOUR_POOL_USER>

[Install]
WantedBy=multi-user.target
```

Let's unpack the ```unit``` file:

1. it runs ```jormungandr``` as ```<YOUR_POOL_USER>```.
2. it looks ```node-*.yaml``` in  ```<YOUR_POOL_USER>``` home directory
3. it provides for  ```systemctl``` start, stop and restart.
4. it restarts ```jormungandr``` on failures
5. it logs to ```journal```.
6. it sets the limits accordingly.

Reload ```systemd``` to read the new ```unit``` file.

```text
systemctl daemon-reload
```

Whenever you need to ```start```, ```stop```, and ```restart``` your node, do it with:

```text
systemctl start jormungandr.service
```

```text
systemctl stop jormungandr.service
```

```text
systemctl restart jormungandr.service
```

### configure logging ###

Now ```jormungandr``` is a system managed service, it's time to configure system level logging with ```rsyslog``` and ```logrotate```.

Place the following in ```/etc/rsyslog.d/90-jormungandr.conf```:

```text
if $programname == 'jormungandr' then /var/log/jormungandr.log
& stop
```

Place the following in ```/etc/logrotate.d/jormungandr```:

```text
/var/log/jormungandr.log {
    daily
    rotate 30
    copytruncate
    compress
    delaycompress
    notifempty
    missingok
}
```

Place the following in ```/etc/logrotate.d/firewalld```:

```text
/var/log/firewalld {
    daily
    rotate 30
    copytruncate
    compress
    delaycompress
    notifempty
    missingok
}
```

Restart the logging services:

```text
systemctl restart rsyslog.service
systemctl restart logrotate.service
```

Now you can check your logs as for any other service with:

```text
journalctl -f -u jormungandr.service
```

### configure node ###

Now that you have configured your server, hosting your pool, you may consider using my ```node-config.yaml```. It was refined every single day until my node run smoothly (for a testing stage software like ```jormungandr``` is as of this writing). This step is **completely optional**, feel free to skip it and trust your own experience and configuration.

By "*running smoothly*", I mean that the node bootstraps relatively quickly; that the "peerAvailableCnt:peerQuarantinedCnt" peers count ratio is reasonable; that the node has a decent amount of established connections, that the node has a great uptime, and a good sync to the network. It is not final by any means, and performance **it varies from node to node**.

For reference only, my node has the following specs:

| Resource | Specs                               |
| -------- | ----------------------------------- |
| CPU      | Intel  Xeon W3520 (4c/8t - 2,66GHz) |
| RAM      | 16GB DDR3 ECC 1333 MHz              |
| SSD      | SoftRaid 2x2TB                      |
| Network  | 100Mpbs                             |
| Traffic  | Unlimited                           |

Should you decide to use it, place the following in ```/home/<YOUR_POOL_USER>/node-config.yaml```. The only adjustment you should take care of, **besides changing the variables to match your system**, is to change the ```trusted_peers``` order to place the nearest to you at the top of the list.

```text
---
log:
  - output: stderr
    format: "plain"
    level: "info"
p2p:
  listen_address: "/ip4/0.0.0.0/tcp/<LISTEN_PORT>"
  public_address: "/ip4/<YOUR_NODE_PUBLIC_IP>/tcp/<LISTEN_PORT>"
  topics_of_interest:
    blocks: high
    messages: high
  max_connections: 1024
  max_connections_threshold: 256
  max_unreachable_nodes_to_connect_per_event: 32
  gossip_interval: 8s
  policy:
    quarantine_duration: 15m
  trusted_peers:
    - address: "/ip4/13.56.0.226/tcp/3000"
      id: 7ddf203c86a012e8863ef19d96aabba23d2445c492d86267
    - address: "/ip4/54.183.149.167/tcp/3000"
      id: df02383863ae5e14fea5d51a092585da34e689a73f704613
    - address: "/ip4/52.9.77.197/tcp/3000"
      id: fcdf302895236d012635052725a0cdfc2e8ee394a1935b63
    - address: "/ip4/18.177.78.96/tcp/3000"
      id: fc89bff08ec4e054b4f03106f5312834abdf2fcb444610e9
    - address: "/ip4/3.115.154.161/tcp/3000"
      id: 35bead7d45b3b8bda5e74aa12126d871069e7617b7f4fe62
    - address: "/ip4/18.182.115.51/tcp/3000"
      id: 8529e334a39a5b6033b698be2040b1089d8f67e0102e2575
    - address: "/ip4/18.184.35.137/tcp/3000"
      id: 06aa98b0ab6589f464d08911717115ef354161f0dc727858
    - address: "/ip4/3.125.31.84/tcp/3000"
      id: 8f9ff09765684199b351d520defac463b1282a63d3cc99ca
    - address: "/ip4/3.125.183.71/tcp/3000"
      id: 9d15a9e2f1336c7acda8ced34e929f697dc24ea0910c3e67
rest:
  listen: 127.0.0.1:<REST_API_PORT>
storage: "/home/<YOUR_POOL_USER>/"
mempool:
  fragment_ttl: 5m
  log_ttl: 1h
  garbage_collection_interval: 15m
leadership:
  log_ttl: 48h
  garbage_collection_interval: 30m
```

Restart ```jormungandr``` to use the new configuration:

```text
systemctl restart jormungandr.service
```

## What's Next ##

Congratulations!!! If you made it this far, you are running a leader candidate node for your pool. This is only the beginning, though. Running a successful pool takes more than having a good uptime. The pool needs to participate in the network, and crunch blocks. To do so, it needs delegations, **a lot of them**, and to be scheduled to participate into the blocks generation, and win them too.

### Helping Hands ###

At the time of this writing, my pool *hasn't done much*, so I'm not the right guy to advise you on all of this, for the time being. One thing I can help you with, though, is to provide you with tools that will help you manage your server and your node.

```jor_wrapper``` and ```node_helpers``` are a set of ```bash``` scripts to help pool operators manage their nodes. These spun off [Chris G ```.bash_profile```](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/config/.bash_profile). I have *ported them to bash (scripts)*, improved some of the commands, adapted others to the ```NACG``` guide setup, and implemented brand new features and scripts.

Head over to the [**scripts page**](SCRIPTS.md) to learn about ```jor_wrapper``` and the ```node_helpers```. In there, you will also find suggested server management commands and tools, examples, teaser screenshots, and more resources. Follow [**insaladaPool**](https://twitter.com/insaladaPool)  on Twitter for future updates.

### Pool Operator Tools ###

#### Pool Tool ####

There a number of useful community created tools, and sites, that can be very helpful for a pool operator. One very useful site, is [**PoolTool**](https://pooltool.io/) by [papacarp](https://twitter.com/mikefullman). Create an account and register your pool, to keep others informed about the state of your pool. Here's [mine](https://pooltool.io/pool/93756c507946c4d33d582a2182e6776918233fd622193d4875e96dd5795a348c) as an example.

#### Stake Pool Bootstrap Channel ####

A **must have community resource** for people just starting their pool operator journey, where to help each others grow, is [Kyle Solomon](https://twitter.com/adafrog_pool)'s [Stake Pool Bootstrap Channel](https://t.me/StakePoolBootstrapChannel). It is a Telegram channel, where it is possible to participate if you follow some simple rules, where to stake with each others in turn, to give small pools a chance.

#### Other Resources ####

Other great community created tools are:

- [**Adapools**](https://adapools.org/)
- [**Pegasus Pool**](https://pegasuspool.info/)
- [**AdaTainement**](https://www.adatainment.com/)

Be sure to check them out!

If you are aware of more useful pool operators tools, please be kind and suggest them to me for inclusion.

### Telegram ###

Last but not least, should you need help at any stage of your pool operator journey, join the '[Cardano Shelley Testnet & StakePool Best Practice Workgroup](https://t.me/CardanoStakePoolWorkgroup)' group on Telegram; it is packed with knowledge, and great and helpful people.

Insalada Stake Pool also has a [Telegram chat](https://t.me/insaladaPool), should you want to follow us and ask anything about INSL :)
