# HomeServer Laptop Configuration

This repo contains various scripts, tools, reminders or notes on configuration of a home server.

## To-do manually

- [ ] Configure additional internal and external disks
- [ ] Configure vsftpd
- [ ] Configure NFS Shares
- [ ] Configure additional scripts from the scripts folder
- [ ] Configure $HOSTNAME env var for OwnCloud Infinite Scale (ocis)
- [ ] Configure and share Network Printers

## Scripts

This section describes the scripts in the `scripts` folder, their purpose and how to use them. 

### PruneDir

PruneDir checks if the size of a directory is greater than a threshold passed as a parameter, and deletes files starting with the oldest until the disk usage of the directory does not pass the threshold anymore. 

```shell
# can be run as
prune_dir.sh $DIR $THRESHOLD

# i.e. to check if /media/ssd/somefolder is using moer than 1GB of memory, run:
prune_dir.sh /media/ssd/somefolder 1G 
```

It can be run as a cron job. 

### Windows NFS Configuration

Due to how the NFS client on Windows is working, the UID and GID are not properly set for the NFS mounts, therefor, access to the NFS mounts will not work as expected, or they will return an access error. 

To fix this, use the following script to set the value of the Anonymous UID and GID. Keep in mind that the values must be the values that correspond to your NFS server mounts. 

```commandline
windows_configure_nfs_uid.ps1
```

If the UID and GID are not properly configured, you may have access to the folders but not see the contents. 

### Windows NFS Mount

To mount an NFS path, use `Command Prompt` specifically and run the following:

```bat
mount -o anon \\192.168.1.1\ Z:
```

Or use the following script:
```
windows_mount_nfs.bat
```

Keep in mind, the proper URL and Path to the NFS Share needs to be used. 

#### NFS Auto Mount

To automount, create a batch `.bat` script in `C:\Users\$USER\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup` with the mount command. This will be run at startup and mount the NFS path. 

## FAQ

### How to see cron job logs
```shell
grep CRON /var/log/syslog
```

### How to configure NFS Shares

https://wiki.archlinux.org/title/NFS
