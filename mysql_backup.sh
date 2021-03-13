#!/bin/bash

. ./mysql_backup.config

mkdir --parents --verbose $BACKUP_DIR

DATABASES=`mysql --host=$HOST --user=$USER --password=$PASSWORD -e "SHOW DATABASES;" | tr -d "| " | grep -v Database`

for database in $DATABASES
  do
    flag=true
    for (( i=0; i < ${#EXCLUDES[@]}; i++ ))
    do
      if [ "$database" = ${EXCLUDES[$i]} ] ; then
        let flag=false
      fi
    done
 
    if [ $flag = true ] ; then
      echo "++ $database"
      mkdir --parents --verbose "$BACKUP_DIR/$database"
      cd $BACKUP_DIR/$database
      number=`ls -l $BACKUP_DIR/$database | grep -v ^l | wc -l`
    
      if [ $((number-1)) -gt $ROTATION_FILO_LENGTH ] ; then
        oldest_file_name=`find -type f -printf "%T+%p\n"  | sort | head -n 1 | cut -d '/' -f 2`
        echo "DELETING: " $oldest_file_name
	      rm -f $oldest_file_name
      fi
      
      backup_name="$CURRENT_DATE""_backup.$database.sql"
      tarball_name="$backup_name.gz"
      `/usr/bin/mysqldump -h "$HOST" --databases "$database" -u "$USER" --password="$PASSWORD"  --single-transaction | gzip -9 > "$backup_name".gz`
      echo "BACKUPING $backup_name"
      fi
  done 

echo "DONE"
