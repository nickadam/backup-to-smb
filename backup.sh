#!/bin/sh

# get share from SMB_SHARE
get_share () {
  n=0
  n_slashes=0
  share=''
  while [ "$n" -le "${#SMB_SHARE}" ] && [ "$n_slashes" -le 3 ]
  do
    c=${SMB_SHARE:$n:1}
    if [ "$c" == "/" ]
    then
      n_slashes=$(($n_slashes + 1))
    fi
    if [ "$n_slashes" -le 3 ]
    then
      share="$share$c"
    fi
    n=$(($n + 1))
  done
  echo $share
}

# check for subdirs on SMB_SHARE
get_subdir () {
  dir_num="$1"
  if [ -z "$dir_num" ]
  then
    dir_num=1
  fi
  dir_num=$((3 + $dir_num))
  n=0
  n_slashes=0
  dir=''
  while [ "$n" -le "${#SMB_SHARE}" ]
  do
    c=${SMB_SHARE:$n:1}
    if [ "$c" == "/" ]
    then
      n_slashes=$(($n_slashes + 1))
    fi
    if [ "$n_slashes" -eq "$dir_num" ] && [ "$c" != "/" ]
    then
      dir="$dir$c"
    fi
    n=$(($n + 1))
  done
  echo $dir
}

# get string with all subdirs
get_path () {
  n=1
  path=''
  while [ ! -z "$(get_subdir $n)" ]
  do
    if [ "$n" -eq 1 ]
    then
      path=$(get_subdir $n)
    else
      path="$path/$(get_subdir $n)"
    fi
    n=$(($n + 1))
  done
  echo $path
}

check_dir_exists () {
  dir="$1"
  smbclient -A /authfile $SHARE -m SMB3 -c "cd $dir" &>/dev/null
}

mkdir () {
  dir="$1"
  smbclient -A /authfile $SHARE -m SMB3 -c "mkdir \"$dir\"" &>/dev/null
}

make_subdirs () {
  n=1
  path=''
  while [ ! -z "$(get_subdir $n)" ]
  do
    if [ "$n" -eq 1 ]
    then
      path=$(get_subdir $n)
    else
      path="$path/$(get_subdir $n)"
    fi
    #check_dir_exists $path
    if ! check_dir_exists $path
    then
      mkdir "$path"
    fi
    n=$(($n + 1))
  done
}

# get list of existing backup directories
get_backups () {
  path="$(get_path)"
  if [ ! -z $path ]
  then
    path="cd \"$path\";"
  fi
  smbclient -A /authfile $SHARE -m SMB3 -c "$path dir" | \
  egrep -o "$BACKUP_NAME""_[0-9]{4}-[0-9]{2}-[0-9]{2}_[0-9]{2}\.[0-9]{2}-\S+" | \
  sort -n
}

count_backups () {
  IFS=$'\n'
  n=0
  for backup in $(get_backups)
  do
    n=$(($n + 1))
  done
  echo $n
}

make_backup () {
  make_subdirs
  backup_date=$(date "+%Y-%m-%d_%H.%M-%Z")
  path="$(get_path)""/$BACKUP_NAME""_$backup_date"
  mkdir "$path"
  if ! smbclient -A /authfile $SHARE -m SMB3 -c "prompt OFF; recurse ON; mask \"\"; cd \"$path\"; lcd /data; mput *" &>/dev/null
  then
    echo "$path Backup failed"
  fi
  delete_backups
}

delete_backups () {
  c=$(count_backups)
  path="$(get_path)"
  if [ ! -z $path ]
  then
    path="cd \"$path\";"
  fi
  if [ "$c" -gt "$RETENTION" ]
  then
    delete=$(($c - $RETENTION))
    IFS=$'\n'
    for backup in $(get_backups)
    do
      if [ $delete -gt 0 ]
      then
        smbclient -A /authfile $SHARE -m SMB3 -c "$path deltree \"$backup\"" &>/dev/null
        delete=$(($delete - 1))
      fi
    done
  fi
}

SHARE=$(get_share)

make_backup
