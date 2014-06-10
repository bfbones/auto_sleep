Edit MasterPC and Netbook IP, add cron for 10 minutes and you're finished.

Use this for adding it to your users crontab/system-wide crontab:

*/10 * * * * /root/auto_sleep.sh
