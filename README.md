# Cardano Related Stuff #

**THIS GUIDE AND SCRIPTS HAVE BEEN SUPERSEDED BY ```ITN1 CLUSTER```, PLEASE VISIT: [https://github.com/gacallea/itn1_cluster](https://github.com/gacallea/itn1_cluster)**

**THIS GUIDE AND SCRIPTS HAVE BEEN SUPERSEDED BY ```ITN1 CLUSTER```, PLEASE VISIT: [https://github.com/gacallea/itn1_cluster](https://github.com/gacallea/itn1_cluster)**

**THIS GUIDE AND SCRIPTS HAVE BEEN SUPERSEDED BY ```ITN1 CLUSTER```, PLEASE VISIT: [https://github.com/gacallea/itn1_cluster](https://github.com/gacallea/itn1_cluster)**

----------------

Hereby you find my humble contributions to the [Cardano](https://www.cardano.org/en/home/) ecosystem. I hope that they can be helpful to you. Enjoy :)

**IMPORTANT**: the guide and the scripts are written for the current Cardano node architecture, and will be updated and adapted to the newly announced [Haskell version](https://iohk.io/en/blog/posts/2020/02/12/new-cardano-node-explorer-backend-and-web-api-released/), as soon as our pool will have migrated to it and tested.

**IMPORTANT**: check back **often** for updates for both the scripts and the guide, as they are constantly improved and updated. I will implement proper versioning and tags at some point, so it would be easier to follow releases.

## Pool Operator Helper Scripts ##

```jor_wrapper``` and ```node_helpers``` are a set of ```bash``` scripts to help pool operators manage their nodes. These spun off [Chris G ```.bash_profile```](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/config/.bash_profile). I have *ported them to bash (scripts)*, improved some of the commands, adapted others to the ```NACG``` guide setup, and implemented brand new features. You will still be able to use ```jor_wrapper``` and the ```node_helpers``` scripts, regardless of the guide you used to set up your pool.

**If you have followed guides other than ```NACG``` to set up your pool, to fully take advantange of these scripts, all you need to add are the ```systemd``` (including the *service user*) and logging (```rsyslogd``` and ```logrotate```) integrations from the [guide](NACG.md).**

Head over to the [**scripts page**](SCRIPTS.md) to learn about ```jor_wrapper``` and the ```node_helpers```. In there, you will also find suggested server management commands and tools, examples, teaser screenshots, and more resources.

Last but not least, should you need help at any stage of your pool operator journey, join the '[Cardano Shelley Testnet & StakePool Best Practice Workgroup](https://t.me/CardanoStakePoolWorkgroup)' group on Telegram; it is packed with knowledge, and great and helpful people.

## Not Another Cardano Guide ##

```Not Another Cardano Guide``` is a guide that will help you setup a pool with Debian 10. You can [**find it here**](NACG.md).

With so many great resources to set up a [Cardano Stake Pool](https://staking.cardano.org/en/staking/) out there, like [Chris G guide for beginners](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/docs/jormungandr_node_setup_guide.md), [Lovepool's](https://github.com/lovelypool/cardano_stuff/blob/master/chrony.conf) and [ILAP's setup files and notes](https://gist.github.com/ilap/54027fe9af0513c2701dc556221198b2),  you may wonder - *"**why write the umpteenth guide?**"*

- **Firstly, it's convenience**. This guide recapitulates everything that helped me setup [INSL](https://shelleyexplorer.cardano.org/en/stake-pool/93756c507946c4d33d582a2182e6776918233fd622193d4875e96dd5795a348c/), into a single resource.

- **Secondly, it adds content**. This guide introduces my scripts, some server administration suggestions, and integrates ```jormungandr``` with ```systemd``` on Debian. I wouldn't write *yet another cardano guide*, if it was going to be *noise*.

- Thirdly, before even writing a guide, I have shared my scripts, and an addendum to his guide, with Chris G. Whether he decides to integrate them, it's out of my control. I owed to his work, and it was fair to share with him first.

- **Last but not least, it is about sharing**. It is a way to give back to the community that helped me with my many questions on Telegram. Hopefully, this is going to be useful to newcomers looking for help to set up a server and a pool.

### The Guide ###

```NACG``` is written with experienced users in mind. Things like creating a GitHub account, creating and using a pair of ssh keys, are a given. If you think you need help with those - there's nothing wrong with it - you should refer to Chris's [guide for newbs](https://github.com/Chris-Graffagnino/Jormungandr-for-Newbs/blob/master/docs/jormungandr_node_setup_guide.md).

This guide won't reinvent the wheel either. Its focus are the system and the node itself, and it will point you to [IOHK](https://iohk.io/)'s, when it's time to create, fund, and register your pool. IOHK [**guide**](https://github.com/input-output-hk/shelley-testnet/blob/master/docs/stake_pool_operator_how_to.md) and [**scripts**](https://github.com/input-output-hk/jormungandr-qa/tree/master/scripts) are all you need, and they are **official**.

## License ##

```Not Another Cardano Guide``` is licensed under the terms of the Creative Commons [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/) license.

```jor_wrapper``` and the ```node_helpers``` scripts are licensed under the terms of the [GPLv3](scripts/LICENSE) license.

## About Me ###

Should you be wondering about my technical background, [I've been a Linux professional](https://linkedin.com/in/gacallea/) for a long time. I love Open Source, and I've taught people about it. I strongly believe in Cardano. And it was a long time since I last contributed to a project.

I also run the [**Insalada Stake Pool**](https://insalada.io/), and this is what got me into this adventure. Follow [**insaladaPool**](https://twitter.com/insaladaPool)  on Twitter for future updates.

## Contributions ##

If you have comments, changes, suggestions for the guide and/or the scripts, please [file an issue](https://github.com/gacallea/cardanoRelatedStuff/issues) on Github. Any insight is valuable and will be considered for integration and improvements.

If these resources help you in any way, consider [buying me a beer](https://seiza.com/blockchain/address/Ae2tdPwUPEZ65aHRG92UQDyMqNoACXLc7ykRhET4sszVWqZdNobN87E1tTQ). Delegating [to my pool](https://insalada.io/) would also be nice. It'd be awesome if [INSL](https://pooltool.io/pool/93756c507946c4d33d582a2182e6776918233fd622193d4875e96dd5795a348c) started crunching numbers besides server bills.
