#!/bin/sh

date >> /tmp/test.txt

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
  smbclient -A /authfile $SHARE -m SMB3 -c "mkdir $dir" &>/dev/null
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
      mkdir $path
    fi
    n=$(($n + 1))
  done
}

SHARE=$(get_share)

make_subdirs
