#!/bin/bash

md5sum() {
  /usr/bin/md5sum $name > $name.md
}

main() {

  name=deploymgt-$1.tgz

  if [[ -d cmcc-la ]];then
    echo "tar $name file base on cmcc-la folder."
    tar -zcvf $name cmcc-la
    md5sum
  else
    echo "There don't have cmcc-la folder, check it please!"
  fi
}


if [ ! $1 ];then
  echo "Please input artifact id."
  exit 1
fi

main $1
