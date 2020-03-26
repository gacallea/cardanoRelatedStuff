#!/bin/bash

# the --help command -- show the usage text
function usage() {
cat<<USAGE

Usage: '$SCRIPTNAME command [options]'

        COMMANDS                                OPTIONS                         DESCRIPTION

        -h|--help                                                               show this help message and exit
        --settings                                                              show node settings and exit
        --set-vars                                                              set variables in ~/.bashrc (run only once) -- CHANGE your variables in jor_config first!

        --account-balance                                                       check $POOL_TICKER account balance
        --current-stakes                                                        check $POOL_TICKER current stakes balance
        --live-stakes                                                           check $POOL_TICKER live stakes balance
        --epoch-stakes                          <epoch>                         check $POOL_TICKER specific epoch stakes balance
        --epoch-rewards                         <epoch>                         check $POOL_TICKER specific epoch rewards balance
        --rewards-balance                                                       check $POOL_TICKER rewards balance
        --rewards-history                       <length>                        check $POOL_TICKER rewards history of the <length> from last epoch(s) from tip

        --leader-logs                                                           check if $POOL_TICKER is currently scheduled as leader
        --scheduled-slots                                                       check how many slots is $POOL_TICKER scheduled for
        --scheduled-dates                                                       show which DATE in this epoch for schedules
        --scheduled-time                                                        show which TIME in this epoch for schedules
        --scheduled-next                                                        show when in the NEXT scheduled block for $POOL_TICKER

        --live-logs                                                             show $POOL_TICKER live logs (scrolls on terminal)
        --last-logs                             5000                            show #N lines of logs
        --problems                              5000                            check for serious problems (e.g: stuck) in #N lines of logs
        --issues                                5000                            check for WARN|ERRO issues in #N lines of logs

        --snapshot                                                              show a brief overview of $POOL_TICKER
        --bstrap-time                                                           calculate how long the bootstrap took
        --last                                  --full                          show when was jormungandr last restarted (from the logs)

        --node-stats                                                            show $POOL_TICKER NODE stats
        --pool-stats                                                            show $POOL_TICKER POOL stats
        --net-stats                                                             show $POOL_TICKER NETWORK stats
        --sys-stats                                                             show a TOP snapshot of jourmungandr
        --date-stats                            5000 20                         count received block announcement from network

        --current-tip                                                           show the current tip for $POOL_TICKER
        --next-epoch                                                            show a countdown to NEXT EPOCH
        --block-now                                                             show SHELLEY current block
        --block-delta                                                           show $POOL_TICKER block delta (as in how far behind it is)
        --block-valid                           <blockid>                       check a block against the REST API to verify its validity

        --check-peers                                                           check ping to trusted peers with tcpping
        --connected-estab                                                       show how many other nodes is $POOL_TICKER connected to
        --connected-ips                         5                               count how many #N connections to a specific IP
        --is-quarantined                                                        check if $POOL_TICKER is quarantined (or was quarantined recently)
        --quarantined-ips                                                       show quarantined IPs
        --quarantined-ips-count                                                 count of quarantined IPs

        --fragments                                                             list all fragments_id
        --fragments-count                                                       show the fragmented_id count
        --fragment-status                       <fragment_id>                   check a fragment_id/transaction status

USAGE
}

