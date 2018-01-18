#!/bin/sh

####
#
# Needs to be run with elevated credentials, sudo or #
# example: box1~$ sudo sh ./splunk-install.sh
# or
# example: box1:/home/user# sh ./splunk-install.sh
# On Centos 7, firewalld is on by default. Future version of script will put in allow port for firewalld
# Since this is for test only, i recommend stopping firewalld service on Centos7 install
#
####

# change this for redhat or centos installs only
SplunkBaseDir="/opt"
###

# change these for either deb or rpm installs
SplunkUser="splunk"
SplunkGroup="splunk"

# nothing should need to be changed from this point on
useradd $SplunkUser
groupadd $SplunkGroup
mkdir -p $SplunkBaseDir
SplunkRootDir=$SplunkBaseDir/splunk
SplunkRun="$SplunkRootDir/bin/splunk"

# curl the current version number of splunk enterprise.
# setting the user agent fools the site into thinking this is a legit request and not a scrape.
curl -A "Mozilla/5.0 (Windows NT 10.0; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0" -L -o /tmp/sem.html 'https://www.splunk.com/en_us/download/sem.html'

# set more VARs
splunk_version=`grep -o 'splunk-[0-9].[0-9].[0-9]-[0-9a-z]\{12\}' /tmp/sem.html | uniq`
splunk_number=`echo $splunk_version | awk -F '-' '{print $2}' | uniq`
deb_curl_url="https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=$splunk_number&product=splunk&filename=$splunk_version-linux-2.6-amd64.deb&wget=true"
rpm_curl_url="https://www.splunk.com/bin/splunk/DownloadActivityServlet?architecture=x86_64&platform=linux&version=$splunk_number&product=splunk&filename=$splunk_version-linux-2.6-x86_64.rpm&wget=true"
#cleanup
rm /tmp/sem.html
# multiple choice for versioning
read -p "Would you like the latest Splunk RPM or DEB or exit? (R/D/E) " ans;

case $ans in
  r|R)
   curl -L -o /tmp/$splunk_version-linux-2.6-x86_64.rpm "$rpm_curl_url"
   rpm -i --prefix=$SplunkBaseDir /tmp/$splunk_version-linux-2.6-x86_64.rpm
   rm /tmp/$splunk_version-linux-2.6-x86_64.rpm;;
  d|D)
   curl -L -o /tmp/$splunk_version-linux-2.6-amd64.deb "$deb_curl_url"
   dpkg -i /tmp/$splunk_version-linux-2.6-amd64.deb
   rm /tmp/$splunk_version-linux-2.6-amd64.deb;;
  *)
   exit;;
esac
# setup and start splunk 
# set splunk permissions
chown -R $SplunkUser:$SplunkGroup $SplunkRootDir 
# start splunk, accept license
sudo -H -u $SplunkUser $SplunkRun start --accept-license --answer-yes --auto-ports --no-prompt
# change the webconfig to be only ssl
cat $SplunkRootDir/etc/system/default/web.conf | sed 's/enableSplunkWebSSL\ \=\ false/enableSplunkWebSSL\ \=\ true/g' > $SplunkRootDir/etc/system/local/web.conf
# copy the sample app into deployment apps to enable forwarder management
sudo -H -u $SplunkUser cp -R $SplunkRootDir/etc/apps/sample_app $SplunkRootDir/etc/deployment-apps/
# enable start on boot for splunk
$SplunkRun enable boot-start
# restart one last time for all changes to take effect
sudo -H -u $SplunkUser $SplunkRun restart
