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
  - [Monitor Your System](#monitor-your-system)
    - [Install Monitoring](#install-monitoring)
    - [Prometheus](#prometheus)
      - [Jormungandr Exporter](#jormungandr-exporter)
      - [Prometheus Configuration](#prometheus-configuration)
      - [Prometheus Alerting](#prometheus-alerting)
    - [Grafana](#grafana)
      - [Grafana Configuration](#grafana-configuration)
        - [[server]](#server)
        - [[users]](#users)
        - [[auth.anonymous]](#authanonymous)
      - [DNS Configuration](#dns-configuration)
      - [Firewalld Configuration](#firewalld-configuration)
      - [Nginx Reverse Proxy](#nginx-reverse-proxy)
      - [Let's Encrypt](#lets-encrypt)
      - [Installing Dashboards](#installing-dashboards)
  - [What's Next](#whats-next)
    - [Helping Hands](#helping-hands)
    - [Operator Resources](#operator-resources)
      - [Pool Tool](#pool-tool)
      - [Stake Pool Bootstrap](#stake-pool-bootstrap)
      - [Organic Design](#organic-design)
      - [ADA Stat](#ada-stat)
      - [ADAtainement](#adatainement)
      - [Adapools](#adapools)
      - [Pegasus App](#pegasus-app)
    - [Telegram](#telegram)

## The Guide ##

This guide is written with experienced users in mind. Things like creating a GitHub account, creating and using a pair of ssh keys, are a given. If you think you need help with those - there's nothing wrong with it - you should refer to Chris's [guide for newbs](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/docs/jormungandr_node_setup_guide.md).

This guide won't reinvent the wheel either. Its focus are the system and the node itself, and it will point you to [IOHK](https://iohk.io/)'s, when it's time to create, fund, and register your pool. IOHK [**guide**](https://github.com/input-output-hk/shelley-testnet/blob/master/docs/stake_pool_operator_how_to.md) and [**scripts**](https://github.com/input-output-hk/jormungandr-qa/tree/master/scripts) are all you need, and they are **official**.

The only note worth adding, before you venture into configuring a server and creating a pool, is that **you need to have enough tADA** - meaning ADA coins that were **in your wallet before the November 2019** snapshot - to register your pool. Otherwise, you won't be able to proceed with the pool registration.

**IMPORTANT**: this guide helps you configure and run a single pool with a single leader candidate node. If you are planning to run a multi-nodes cluster, this guide assumes that you know what you are doing. Having said that, a guide to satisfy a cluster configuration, complete with scripts to manage it, is coming soon. Stay tuned.

### License ###

This guide is licensed under the terms of a Creative Commons [**CC BY-NC-SA 4.0**](https://creativecommons.org/licenses/by-nc-sa/4.0/). If you are not familiar with Creative Commons licenses, here's a bit [I wrote about them](https://gacallea.info/posts/a-primer-on-linux-open-source-and-copyleft-hackers-included/#creative-commons) that clarify what Creative Commons licenses are about.

### System ###

This guide will be focusing on the latest **Debian stable**, and assumes you already have your server installed with a vanilla Debian 10 (Buster), **that you can already ```ssh``` into on port ```22```**. This guide will stick to official repositories, with the exception for ```jormungandr```, ```jcli```, and ```tcpping```. This guide will stick with best practices for stability (e.g: [backports](https://backports.debian.org/) vs [unstable](https://wiki.debian.org/DontBreakDebian)).

Lastly, this guide assumes that you are familiar with Linux, its shell, its commands and have some experience in managing a server. This guide will promote system administration over shortcuts and aliases. For example, it will favor and configure ```systemd``` over aliases to manage the node. It will favor using ```pidof jormungandr``` instead of configuring an alias. In this guide you'll be also configuring system wide logging, and using ```journalctl``` over typing "*logs*". You get the idea.

### Updates ###

Updates are implemented only after I'll have done so on my pool, and tested it. I will add more sections to the guide as needed. The same goes for any useful feature that could help pool owners run and manage the server and the pool. Follow [insaladaPool](https://twitter.com/insaladaPool) for future updates.

### Contributions ###

**If you have comments, issues, changes, and suggestions, please [file an issue](https://github.com/gacallea/cardanoRelatedStuff/issues) on Github**. Any insight is valuable and will be considered for integration and improvements. If these resources help you in any way, consider [buying me a beer](https://seiza.com/blockchain/address/Ae2tdPwUPEZGcgwWYE3wKGcpn9cfPmADjwegQqBnTrcBfsexUkbxnT4sciw).

## Prepare Your System ##

The guides assumes that the system will be managed with ```root```. Don't worry, to ```ssh``` and ```sudo```, there will be a dedicated **non-root user**. To run the pool, yet another *service user*, with neither a shell nor privileges. So, if you are wondering if the pool will run as ```root```, the answer is **no way.** Systemd will take care of running the pool as the *service user*. A *service user* without a shell or a password, means less surface attack for an hacker trying to exploit *testing quality* software.

**IMPORTANT: any command and action in this guide needs to run as ```root```.** ```sudo``` is fine too, but you **must prepend it** to commands where it's needed. If your Debian doesn't come with ```sudo``` preinstalled, install it now (**with the root user**):

```text
apt install sudo
```

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
- ```musl``` is a [C library](https://wiki.musl-libc.org/functional-differences-from-glibc.html), in case you want to run the [musl](https://musl.libc.org/) version of ```jormungandr```

```text
apt update
apt install bc cbm ccze chrony curl dateutils fail2ban htop jq musl net-tools ripgrep speedtest-cli sysstat tcptraceroute wget
```

Make sure that the ```backports``` repository is enabled in ```/etc/apt/sources.list```. Here's a complete ```sources.list``` file:

```text
deb http://deb.debian.org/debian buster main
deb-src http://deb.debian.org/debian buster main

deb http://security.debian.org/ buster/updates main
deb-src http://security.debian.org/ buster/updates main
deb http://deb.debian.org/debian buster-updates main
deb-src http://deb.debian.org/debian buster-updates main

deb http://deb.debian.org/debian buster-backports main
deb-src http://deb.debian.org/debian buster-backports main
```

And install ```firewalld``` and ```nftbales```:

```text
apt -t buster-backports install firewalld nftables
```

#### install jormungandr and jcli ####

You should stick [to the latest stable release](https://github.com/input-output-hk/jormungandr/releases), unless it introduces regressions. The following works for the current release for a ```x86_64``` architecture (PC/Mac - Intel/AMD Server) and [GNU](https://www.gnu.org/) ```glibc```.

```text
curl -sLOJ https://github.com/input-output-hk/jormungandr/releases/download/v0.8.16/jormungandr-v0.8.16-x86_64-unknown-linux-gnu-generic.tar.gz
tar xzvf jormungandr-v0.8.16-x86_64-unknown-linux-gnu-generic.tar.gz
mv jcli /usr/local/bin/
mv jormungandr /usr/local/bin/
chmod +x /usr/local/bin/jcli
chmod +x /usr/local/bin/jormungandr
chown -R root\: /usr/local/bin/
```

#### install tcpping ####

This is going to be the only alien piece of software, besides pool software, that you will be installing from a source that is not from official Debian repositories. It is used in my scripts.

```text
curl -s http://www.vdberg.org/~richard/tcpping -o /usr/local/bin/tcpping
chmod +x /usr/local/bin/tcpping
chown -R root\: /usr/local/bin/
```

## Create & Register Your Pool ##

Without a pool, there's no point in going any further. Before you can proceed with system configurations, now it is a good time to follow [IOHK](https://github.com/input-output-hk)'s [**guide**](https://github.com/input-output-hk/shelley-testnet/blob/master/docs/stake_pool_operator_how_to.md) and use their [QA Team](https://github.com/input-output-hk/jormungandr-qa) [**scripts**](https://github.com/input-output-hk/jormungandr-qa/tree/master/scripts) to create, register and start your leader candidate node.

Come back after you have successfully completed **all** the necessary steps, and once your pool will be started as a leader candidate and it will be available on Daedalus and Yoroi (testnet versions).

Should you need help at any stage of your pool operator journey, join the '[Cardano Shelley Testnet & StakePool Best Practice Workgroup](https://t.me/CardanoStakePoolWorkgroup)' group on Telegram; it is packed with knowledge, and great and helpful people.

**IMPORTANT:** if you happen to have already successfully created and registered your pool, you don't need to do it all over again. Just have the ```node-config.yaml``` and ```node-secret.yaml``` handy for later.

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

It should show the following:

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

Reload ```systemd``` to read the new ```unit``` file, and enable it.

```text
systemctl daemon-reload
systemctl enable jormungandr.service
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

**IMPORTANT: place  the ```node-config.yaml``` and ```node-secret.yaml``` in your ```/home/<YOUR_POOL_USER>/``` directory:**

```text
/home/<YOUR_POOL_USER>/node-config.yaml
/home/<YOUR_POOL_USER>/node-secret.yaml
```

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
  max_connections: 256
  max_inbound_connections: 128
  max_unreachable_nodes_to_connect_per_event: 32
  max_bootstrap_attempts: 3
  gossip_interval: 4s
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
    pool_max_entries: 10000
    log_max_entries: 100000
leadership:
    logs_capacity: 4096
http_fetch_block0_service:
- "https://github.com/input-output-hk/jormungandr-block0/raw/master/data/"
skip_bootstrap: false
bootstrap_from_trusted_peers: false
```

Restart ```jormungandr``` to use the new configuration:

```text
systemctl restart jormungandr.service
```

## Monitor Your System ##

Monitoring is indispensable for any given service. Monitoring, in layman's terms, *provides and automates real-time services health history*, and alerts you whenever something goes wrong. So that you don't have to be constantly connected to your server. Mind that monitoring doesn't substitute server administration. It is only a tool that informs the administrator about the health of the server and its services, and that lets one know it's time to connect and act upon alerts. It is still the administrator responsibility to fix any issue, and to keep the server healthy. Moreover, the history aspect that monitoring provides, can help you look into the big picture to understand what went wrong, even when you were not connected or sound asleep.

In this section you will configure and automate Prometheus and Grafana *to be there for you*. In a future revision of this guide, you will configure alerting to send you messages or emails, to let you know about issues when they happen. With alerting, if you don't receive any alerts, "*no news is good news*". If you do receive them, it's time connect and troubleshoot the issues.

**IMPORTANT:** this guide assumes a remote server with a working domain. [DNS](https://en.wikipedia.org/wiki/Domain_Name_System) needs to be configured to access you monitoring, remotely.

### Install Monitoring ###

You need to install [Prometheus](https://prometheus.io/) from the official Debian repository, and [Grafana](https://grafana.com/) from the [repository they provide](https://grafana.com/docs/grafana/latest/installation/debian/). You'll also install and configure [Nginx](https://www.nginx.com/) and [EFF](https://eff.org/)'s [Certbot](https://certbot.eff.org/) to automate the process of creating and managing [Let's Encrypt](https://letsencrypt.org/) certificates. Nginx is used to [reverse-proxy](https://en.wikipedia.org/wiki/Reverse_proxy) to Grafana, and the [SSL encryption](https://www.ssl.com/faqs/faq-what-is-ssl/) is necessary to securely connect to and peruse your remote monitoring, [while keeping safe from prying eyes](https://www.youtube.com/watch?v=-enHfpHMBo4). To install the needed software, use the following commands:

```text
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" > /etc/apt/sources.list.d/grafana.list
```

```text
apt update
apt install prometheus prometheus-alertmanager prometheus-node-exporter nginx certbot python3-pip python3-certbot-nginx grafana
```

### Prometheus ###

At the fundamental level, Prometheus collects data and generates metrics. The resulting metrics can be fed into a tool, like Grafana, to depict the big picture for you. Learn more about Prometheus [here](https://prometheus.io/docs/introduction/overview/). Prometheus works with [exporters](https://prometheus.io/docs/instrumenting/exporters/) to collect data from several services. You'll be using two: the official [Node Exporter](https://github.com/prometheus/node_exporter) (installed above), and the Jormungandr Exporter.

#### Jormungandr Exporter ####

This Python script, based on [the official IOHK one](https://github.com/input-output-hk/jormungandr-nix/blob/master/nixos/jormungandr-monitor/monitor.py), improves to use the latest ```peerConnectedCnt```, and will collect a number of Jormungandr metrics using ```jcli``` and the REST API. Let's install the necessary Python dependencies:

```text
pip3 install prometheus_client python-dateutil systemd-python ipython
```

To get the script in place, use the the following ```curl```, and **remember to change** ```<REST_API_PORT>``` to your REST API port in the ```jormungandr-monitor.py``` **or it will not work correctly**.

```text
curl -sLJ https://raw.githubusercontent.com/gacallea/cardanoRelatedStuff/master/monitoring/jormungandr-monitor.py -o /etc/prometheus/jormungandr-monitor.py
```

. ```jormungandr-monitor.py``` will be managed with ```systemd``` as well. Let's create the necessary unit file called ```/etc/systemd/system/jormungandr-monitor.service```

```text
[Unit]
Description="Jormungandr Monitoring Script"
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /etc/prometheus/jormungandr-monitor.py

StandardOutput=journal
StandardError=journal
SyslogIdentifier=jormungandr-monitor

Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
```

Reload ```systemd``` to read the new ```unit```:

```text
systemctl daemon-reload
```

#### Prometheus Configuration ####

Prometheus configuration is pretty straight-forward. Edit ```/etc/prometheus/prometheus.yml``` and use the following settings:

```text
# NACG Config for Prometheus.

global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.

  # Attach these labels to any time series or alerts when communicating with
  # external systems (federation, remote storage, Alertmanager).
  external_labels:
      monitor: 'Jormungandr Monitor'

# A scrape configuration containing exactly one endpoint to scrape:
scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    scrape_timeout: 5s
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']

  - job_name: 'jormungandr'
    static_configs:
      - targets: ['localhost:9101']
```

That's all its needed for Prometheus to be collecting data from the Node and Jormungandr exporters, and to generate metrics that will be later fed to Grafana. Make sure to enable the services and start them as well:

```text
systemctl enable prometheus.service
systemctl enable prometheus-node-exporter.service
systemctl enable jormungandr-monitor.service
systemctl restart prometheus.service
systemctl restart prometheus-node-exporter.service
systemctl restart jormungandr-monitor.service
```

#### Prometheus Alerting ####

Alerting with Prometheus will be implemented in a future revision of this guide. Follow [insaladaPool](https://twitter.com/insaladaPool) for future updates.

### Grafana ###

Grafana is a graphing software that provides dashboards that give you a complete view of what's going on with your server and with your pool. It can show backward history, as long there is data to graph on. This is you main point of entry to monitoring. Grafana can talk to a number of data sources that *feed data to it*. You are using and have configured Prometheus to be our source of data, now it's time to bring it all together.

#### Grafana Configuration ####

Grafana by default runs on port ```3000```. If ```jormungandr``` is running on port ```3000``` as well, you need to change either one. I suggest you use port ```3000``` for Grafana, and set ```jormungandr``` port to ```3001``` and its ```<REST_API_PORT>``` set to ```3101```. This way it can be easy to mnemonically associate ```jormungandr``` and its ```<REST_API_PORT>``` instance.

The Grafana configuration has pretty solid default values. You only need to change a handful to successfully configure it. Here, ```grafana.example.com``` is used as an example, you can use whatever suits you to replace the ```grafana.``` bit (for instance ```monitoring.```). However, **the domain has to match your actual domain**. Here's what needs changing (in which blocks):

##### [server] #####

```text
domain = grafana.example.com
root_url = https://grafana.example.com
```

##### [users] #####

```text
allow_sign_up = false
```

##### [auth.anonymous] #####

```text
enabled = false
```

Restart Grafana to reload the new configuration:

```text
systemctl restart grafana-server.service
```

#### DNS Configuration #####

Now that you have chosen your preferred monitoring [URL](https://en.wikipedia.org/wiki/URL), you need to configure it on your [DNS](https://en.wikipedia.org/wiki/Domain_Name_System) with an [A record](https://en.wikipedia.org/wiki/List_of_DNS_record_types) that points to your server. Follow your DNS provider's guide to do so. For example, if your server [IP address](https://en.wikipedia.org/wiki/IP_address) is ```1.2.3.4```, and your URL is ```grafana.example.com```, you will need an A record similar to the following:

```text
Type: A, Host: grafana, Value: 1.2.3.4
```

Here's Namecheap guide as a pointer: [How do I set up host records for a domain?](https://www.namecheap.com/support/knowledgebase/article.aspx/434/2237/how-do-i-set-up-host-records-for-a-domain)

**Make sure that your A record is working correctly and that is has propagated**, before proceeding with the rest of the guide. The following should return your server IP address, if it doesn't your record hasn't propagated yet.

```text
dig grafana.example.com +short a
```

#### Firewalld Configuration ####

In order for the next steps to work, and to be able to remotely connect to your monitoring, the firewall need to be open for port ```443```. Issue these commands to do so:

```text
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --complete-reload
```

To verify that everything has worked, issue the following and check for ```ports: 443/tcp```

```text
firewall-cmd --list-all
```

#### Nginx Reverse Proxy ####

[Nginx](https://www.nginx.com/) is a modern and reliable web server, in this case you'll be using it to [reverse-proxy](https://en.wikipedia.org/wiki/Reverse_proxy) to Grafana. The main reason to be using a web server, rather than the Grafana built-in, is to take advantage of the [SSL encryption](https://www.ssl.com/faqs/faq-what-is-ssl/) to securely connect to and peruse your remote monitoring, [while keeping safe from prying eyes](https://www.youtube.com/watch?v=-enHfpHMBo4).

Configuring it is very easy, and it involves three simple steps:

1. disabling the default server.
2. configuring the reverse proxy.
3. implementing SSL.

To disable the default Nginx server, simply remove it from ```sites-enabled```:

```text
rm -f /etc/nginx/sites-enabled/default
```

To configure the reverse-proxy, add this configuration to ```/etc/nginx/sites-available/grafana```

```text
server {
  listen 443 ssl http2;
  server_name grafana.example.com;

  location / {
    rewrite /(.*) /$1 break;
    proxy_pass http://localhost:3000/;
    proxy_redirect off;
    proxy_set_header Host $host;
  }
}
```

Enable it:

```text
cd /etc/nginx/sites-enabled/
ln -sf ../sites-available/grafana
systemctl restart nginx.service
```

#### Let's Encrypt ####

[Let's Encrypt is](https://letsencrypt.org/about/) an amazing initiative that aims to bring SSL to everyone, for free. Bigger companies and institutions may still need an higher grade of SSL, but Let's Encrypt is perfect for small time sites, like blogs, small indie websites, and your pool. It is also very smart and easy to configure, with [EFF](https://eff.org/)'s [Certbot](https://certbot.eff.org/). Certbot automates the process of creating, managing, and keeping [Let's Encrypt](https://letsencrypt.org/) certificates up to date for you. All it takes is this simple command:

```text
certbot --nginx -d grafana.example.com
```

If you need a more detailed guide to help you with ```certbot```, Digital Ocean has [a great guide](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-debian-10) that can help.

Upon the successful Certbot run, your Nginx configuration will be changed to use SSL. Do not touch it, as it is used and managed by Certbot at this point. Certbot will also set and run a ```systemd-timer``` to renew the SSL certificate when necessary.

Restart Nginx with:

```text
systemctl restart nginx.service
```

#### Installing Dashboards ####

It is now time to connect to Grafana by browsing to ```https://grafana.example.com```. Login with the default credentials (user: ```admin```, password: ```admin```). Upon a successful login, you will be asked to create a new password for the admin user.

It is time to install two dashboards. No need to reinvent the wheel here, please follow the official documentation if you need guidance: [Grafana Export/Import](https://grafana.com/docs/grafana/latest/reference/export_import/). Install the following dashboards to make use of Node Exporter and Jormungandr Exporter:

- Node Exporter Dashboard: [https://grafana.com/grafana/dashboards/1860](https://grafana.com/grafana/dashboards/1860)
- Jormungandr Dashboard: [gacallea/cardanoRelatedStuff/master/monitoring/jormungandr-monitor.json](https://raw.githubusercontent.com/gacallea/cardanoRelatedStuff/master/monitoring/jormungandr-monitor.json)

## What's Next ##

Congratulations!!! If you made it this far, you are running a leader candidate node for your pool, and you know its state and have an history thanks to monitoring. This is only the beginning, though. Running a successful pool takes more than having a good uptime. The pool needs to participate in the network, and crunch blocks. To do so, it needs delegations, **a lot of them**, and to be scheduled to participate into the blocks generation, and win them too.

### Helping Hands ###

One thing I can help you with, is to provide you with tools that will help you manage your server and your node.

```jor_wrapper``` and ```node_helpers``` are a set of ```bash``` scripts to help pool operators manage their nodes. These spun off [Chris G ```.bash_profile```](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/config/.bash_profile). I have *ported them to bash (scripts)*, improved some of the commands, adapted others to the ```NACG``` guide setup, and implemented brand new features and scripts.

Head over to the [**scripts page**](SCRIPTS.md) to learn about ```jor_wrapper``` and the ```node_helpers```. In there, you will also find suggested server management commands and tools, examples, teaser screenshots, and more resources. Follow [**insaladaPool**](https://twitter.com/insaladaPool)  on Twitter for future updates.

### Operator Resources ###

There a number of useful community created tools, guides, [scripts](SCRIPTS.md), and sites, that can be very helpful for a pool operator. Hereby you find a constantly updated collection of what can be useful to a pool operator. If you are aware of more useful pool operators tools, please be kind and suggest them in an [issue](https://github.com/gacallea/cardanoRelatedStuff/issues) on Github, for inclusion.

#### Pool Tool ####

One very useful site, is [**PoolTool**](https://pooltool.io/) by [papacarp](https://twitter.com/mikefullman). It has all sort of network and pools statistics, and offers a number of useful tools for pool operators. One of them is about one's own pool health and status. Create an account and register your pool, to keep others informed about the state of your pool. Here's [mine](https://pooltool.io/pool/93756c507946c4d33d582a2182e6776918233fd622193d4875e96dd5795a348c) as an example.

#### Stake Pool Bootstrap ####

A **must have community resource** for who's just starting their pool operator journey, **where we all help each others grow**, is [The Cardano Stake Pool Bootstrap Initiative](https://www.adafrog.io/bootstrap.php). It is a [Telegram group](https://t.me/StakePoolBootstrapChannel), where it is possible to participate if you follow some simple rules, where to stake with each others in turn, **to give small pools a chance**.

Anyone can join the party, as long as their pool meets these simple requirements to be eligible:

1. Delegate to other pools in the list.
2. Have a ticker (registered on CF GitHub).
3. Have less than 5M ADA already delegated to the pool.

Join us, and make sure to read the pinned message for all of the nitty gritty details.

#### Organic Design ####

Organic Design has a great deal of useful information on [Cardano](https://organicdesign.nz/Cardano), [Staking Pool FAQ](https://organicdesign.nz/Cardano_staking_pool_FAQ), and [Cardano terminology](https://organicdesign.nz/Cardano#Staking_in_Cardano). Familiarize with these, and your pool operator journey will improve a lot.

#### ADA Stat ####

[ADA Stat](https://adastat.net/en) offers a minimalistic and elegant approach to stats for the explorer and pools. It is accurate and a pleasure to use and look at. Here's INSL as an example: [Insalada Stake Pool](https://adastat.net/en/pool/93756c507946c4d33d582a2182e6776918233fd622193d4875e96dd5795a348c) statistics.

#### ADAtainement ####

[**Adatainement**](https://www.adatainment.com/) is one of the oldest community driven, informative site about Cardano. It also offers graphs, and statistics. Moreover it offers mobile apps, a calculator and a number of other useful tools. Be sure to check them out.

#### Adapools ####

In the same fashion to the above-mentioned Pool Tool, [**Adapools**](https://adapools.org/) offers a number of useful network statistics and pool operators' tools. You can find tools that check against the explorer to understand [if you are forked](https://adapools.org/amiforked); info on [what peers are currently best](https://adapools.org/peers) for your bootstrap, [blocks statistics](https://adapools.org/blocks), and more.

#### Pegasus App ####

[Pegasus App](https://pegasuspool.info/mobile) is a mobile application that provides statistics like the above sites, for pools and the explorer, and it can be with you at all times.

### Telegram ###

Last but not least, should you need help at any stage of your pool operator journey, join the '[Cardano Shelley Testnet & StakePool Best Practice Workgroup](https://t.me/CardanoStakePoolWorkgroup)' group on Telegram; it is packed with knowledge, and great and helpful people.

Insalada Stake Pool also has a [Telegram chat](https://t.me/insaladaPool), should you want to follow us and ask anything about INSL :)
