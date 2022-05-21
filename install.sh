#!/bin/bash
# @version		1.0.5

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

function printRed() {
  echo -e "\e[31m${*}\e[0m"
}

function printGreen() {
  printf "\e[32m${1}\e[0m"
}

function printBold() {
  printf "\033[1m${1}\033[0m"
}

function fail() {
  printRed $1
  exit 1
}

printBold "|\n|   Sysmon Installer\n|\n"

if [ $(id -u) != "0" ]; then
  fail "|\n| Error: Please run the agent as root. The agent will NOT run as root but root required to make the installation success\n|"
fi

SYSTEM="$(uname -s 2>/dev/null || uname -v)"
OS="$(uname -o 2>/dev/null || uname -rs)"
MACHINE="$(uname -m 2>/dev/null)"

printBold "System            : ${SYSTEM}\n"
printBold "Operating System  : ${OS}\n"
printBold "Machine           : ${MACHINE}\n"

if [ $# -lt 1 ]; then
  fail "|\n| Usage: bash $0 'token'\n|"
fi

if [ ! -n "$(command -v crontab)" ]; then
  echo "|" && read -p "|   Sysmon needs cron. Do you want to install it? [Y/n] " input_variable_install

  if [ -z $input_variable_install ] || [ $input_variable_install == "Y" ] || [ $input_variable_install == "y" ]; then
    if [ -n "$(command -v apt-get)" ]; then
      apt-get -y update
      apt-get -y install cron
    elif [ -n "$(command -v pacman)" ]; then
      pacman -S --noconfirm cronie
    elif [ -n "$(command -v yum)" ]; then
      yum -y install cronie

      if [ ! -n "$(command -v crontab)" ]; then
        yum -y install vixie-cron
      fi
    fi
  fi

  if [ ! -n "$(command -v crontab)" ]; then
    fail "|\n|   Error: Cannot install CronTab, please install the CronTab and run the script again\n|"
  fi
fi

if [ -z "$(ps -Al | grep cron | grep -v grep)" ]; then
  echo "|" && read -p "|   Cron is is down. Do you want to start it? [Y/n] " input_variable_service
  if [ -z $input_variable_service ] || [ $input_variable_service == "Y" ] || [ $input_variable_service == "y" ]; then
    if [ -n "$(command -v apt-get)" ]; then
      service cron start
    elif [ -n "$(command -v yum)" ]; then
      chkconfig crond on
      service crond start
    elif [ -n "$(command -v pacman)" ]; then
      systemctl start cronie
      systemctl enable cronie
    fi
  fi

  if [ -z "$(ps -Al | grep cron | grep -v grep)" ]; then
    fail "|\n|   Error: Error when trying to start the Cron\n|"
  fi
elif [ -z "$(ps -Al | grep crond | grep -v grep)" ]; then
  echo "|" && read -p "|   Cron is is down. Do you want to start it? [Y/n] " input_variable_service
  if [ -z $input_variable_service ] || [ $input_variable_service == "Y" ] || [ $input_variable_service == "y" ]; then
    if [ -n "$(command -v yum)" ]; then
      chkconfig crond on
      service crond start
    fi
  fi

  if [ -z "$(ps -Al | grep crond | grep -v grep)" ]; then
    fail "|\n|   Error: Error when trying to start the Cron\n|"
  fi
fi

if [ -f /etc/mSysmon/sys-agent.sh ]; then
  rm -Rf /etc/mSysmon

  if id -u mSysmon >/dev/null 2>&1; then
    (crontab -u mSysmon -l | grep -v "/etc/mSysmon/sys-agent.sh") | crontab -u mSysmon - && userdel mSysmon
  else
    (crontab -u root -l | grep -v "/etc/mSysmon/sys-agent.sh") | crontab -u root -
  fi
fi

mkdir -p /etc/mSysmon

printBold "|   Downloading sys-agent.sh to /etc/mSysmon\n|\n|   + $(wget -nv -o /dev/stdout -O /etc/mSysmon/sys-agent.sh --no-check-certificate https://raw.githubusercontent.com/Flarezen-Ltd/sysmon-agent/master/sys-agent.sh)"

# if [ -f /etc/syAgent/sh-agent.sh ]; then
#   echo "$1" >/etc/syAgent/sa-auth.log

#   useradd syAgent -r -d /etc/syAgent -s /bin/false

#   chown -R syAgent:syAgent /etc/syAgent && chmod -R 700 /etc/syAgent

#   chmod +s `type -p ping`

#   crontab -u syAgent -l 2>/dev/null | {
#     cat
#     echo "*/1 * * * * bash /etc/syAgent/sh-agent.sh > /etc/syAgent/sh-cron.log 2>&1"
#   } | crontab -u syAgent -

#   printBold "| ================================================\n"
# 	printGreen "| Success: The syAgent agent installed\n"
# 	printBold "| ================================================\n"

#   if [ -f $0 ]; then
#     rm -f $0
#   fi
# else
#   fail "\tError: The syAgent agent is not installed\n"
# fi
