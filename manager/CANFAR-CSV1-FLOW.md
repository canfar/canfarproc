# CANFAR Batch Workflow using CloudScheduler V1

This document describes the workflow for running CANFAR batch processing jobs using CloudScheduler version 1. This is largely meant to be a historical document in preparation for migrating the batch system to using CloudScheduler version 2.


# Canfar new user flow:

1. The user creates CADC account. This will give them access to storage on VOSpace.
	- They need to have access to a storage space.
	- If none specified by user, require a name from user and run the `vospace-admin` to create one.

2. The user needs to be added to the Arbutus OpenStack cloud group: 
    - go to group management system, canfar.net
    - add user to group arbutus-cloud-users as member

If user needs batch, see below.

# Steps to create new batch users

1. Go to Openstack Arbutus web frontend using canfarops account, download projectname-openrc.sh file

2. `scp projectname-openrc.sh canfarops@batch.canfar.net`

3. `cp projectname-openrc.sh ~/projects-openrc/`

4. `sudo canfar_create_user username projectname`

5. `canfar_project_remove_prompt projectname-openrc.sh` (be sure to use canfarops password, for stats)

6. `mv name-openrc.sh /mnt/stats/openstack/projects/arbutus`

7.  Ask user ssh public key, add key to ~/.ssh/authorized_keys in user's home directory.


# Job submission flow

- The user can then submit their jobs to the condor job pool with the `canfar_submit` command.
      eg: canfar_submit quick_start.sub quick_start-0.1 c2-7.5gb-31

-  A proxy cert is issued from OpenStack (generated from grid canada cert with expiry). `cadc-get-cert`  command pulls in (`cadc_cert` wrapper command called from `canfar_submit`)
- condor will upload cert to workers and gives access to VOSpace



```
-> canfar_submit 
  |
  | --> canfar_job_validate --
  |                           |
  | <-------------------------
  |        
  |        
  | --> canfar_translate_vm --
  |                           |
  | <-------------------------
  |
  |
  v
  condor_submit
  |
  | 
  v
  condor       
    ^
    |
  cloudscheduler V1 (watches condor and starts VMs as needed)
```

# Script descriptions

## `canfar_submit`:

### DESCRIPTION:

A user script for submitting batch jobs. A wrapper for `canfar_translate_vm`, `canfar_job_validate` and `condor_submit`.  This script avoids the CANFAR proc web service which does not have enough features, and can submit jobs directly on the head node for testing purposes.

### INPUTS:
      JOB_FILE     - HTCondor job submission file
      VM_IMAGE     - OpenStack VM image used to process jobs (name or ID)
      VM_FLAVOR    - OpenStack VM resource flavor used to process jobs

### OPTIONS:
      -c, --cert=<path>         specify path for proxy to access VOSpace (default: ${HOME}/.ssl/cadcproxy.pem)
      -u, --user=<username>     specify user to run the jobs on the VM (default: automatically detected)
      -h, --help                display help and exit
      -V, --version             output version information and exit
      -v, --verbose             verbose mode for debugging

### USAGE:
      `canfar_submit [OPTION] JOB_FILE VM_IMAGE VM_FLAVOR`

### FLOW:

  1. Store all input options

  2. Verify input and warn if you are submitting jobs without a VOSPace access certificate

  3. If one of the argument requirements fails, the script will exit.

  4. Validate user's job submission file (with an executable).

  5. First the executable is extracted

  6. Ensure user has authorized access to their OpenStack project (which was done via sourcing rc file)

  7. Share the image and translate image and flavour names to their IDs, which is what `canfar_job_validate` expects.

  8. `canfar_translate_vm` is called to share images to other projects, it then returns the image ID and flavor ID (UUID)

  9. `canfar_job_validate` is then called and modifies the user submitted jdl file.  It adds some options and variables to the top of the user submitted job script to make it compatible with the conder and cloudscheduler v1 system.

  10. `cadc_cert` is called to inject user certs into the vm (this is not often used because many users still create a proxy certificate within their processing scripts).

  11. The modified HTcondor submission file is then summited condor by calling `condor_submit`




## `canfar_translate_vm`:

### DESCRIPTION:

  This is a tool to share images/snapshots between canfar OpenStack projects.

  The client will authenticate to OpenStack in order to:
  - share the user VM with the batch processing project
  - translate image, project to UUID as needed
  - will output VM and flavour IDs.

### INPUTS:
      VM_IMAGE
      VM_FLAVOR


### USAGE:
      `canfar_translate_vm [options] VM_IMAGE VM_FLAVOR`


### FLOW:

  1. Get cloud credentials from system environment variables

  2. Parse command line

  3. Get cloud credentials from system environment variables

  4. Need an image ID. If the user supplied a name, convert it to ID.

  5. List images and search for ID

  6. Share the user image with batch project

  7. CANFAR project ID is allowed to access user image (g is glance) 

  8. We will require a flavor ID. If the user supplied a name, convert it to ID.



## `canfar_job_validate`:

### DESCRIPTION:

This script validates these inputs and writes an augmented condor job file including extra cloud scheduler parameters to stdout (or a specified output file), and also generates a cloud-config script that cloud scheduler will use to configure running instances of the VM to work with Condor. 
 
 A user provides a bare condor job description file, as well as image and flavor IDs.  Bad exit status is set upon failure.

### INPUTS:
      CM_IP
      CERT_USER
      JOB_USER
      JOB_FILE
      JOB_SCRIPT
      VM_IMAGE_AND_FLAVOR_IDS

### USAGE:
      `canfar_job_validate CM_IP CERT_USER JOB_USER JOB_FILE JOB_SCRIPT VM_IMAGE_AND_FLAVOR_IDS`


### FLOW:

1. Parse command line

2. Check for valid UUIDs

3. Check parameters in jobfile

4. Re-write 'Executable' line since the proc web service will have placed it somewhere different from the user's original location

5. Determine the name of the image from its UUID, and the name of the project that owns it. First we get a glance client to get the name of the given image ID. We then query that image's metadata to obtain its owner project id. Finally, we use a second keystone client scoped to the image's owner project to obtain its project name.

6. Generate cloud config file for the user as follows:

   - inject a public ssh key into the generic user account
   - write and execute the cloud scheduler configuration script
   - image_name and image_user are used by canfar_batch_init to set the VMType. If not specified defaults to $HOSTNAME and $USER the full output path name of the configuration script when copied into the VM

    - The following fields are added to the jdl file:
          VMTYPE
          VMAMI
          VMInstanceType
          VMAMIConfig
          VMKeepAlive


# Other script descriptions:


- **cadc_cert** 
	- tries to create a CADC proxy cert in many ways.

- **canfar_condor_user_stats**
	- runs as a cronjob to extract stats from rolling `condor_history`

- **canfar_list_quotas** 
	- gens csv cores, id, gigs (disk usage), ram name of canfar projects

- **canfar_project_stats** 
	- aimed to be run as a cron job which creates stats for openstack, loops throught projects and runs `openstack usage show`

- **canfar_update_default_image** 
	- perpares canfar default snapshots and shares them with all projects...

- **cadc_dotnetrc**
	- adds user creds for cadc 

- **canfar_create_batch_user**
	- adds a user to batch.canfar.net with an accociated os project..

- **canfar_openstack_stats**
	- outputs cores-years within a specified data range

- **canfar_share_vm**
	- shares a vm/snapshot between projects. it also does acceptance on opentstack side, used by `canfar_update_default_image`

- **runCanfarJobValidate.sh**
	- calls `canfar_job_validate` (was used by proc web service)

- **canfar_cloud_cleanup**
	- cleans up vms which get lost between condor and cs. (probably not needed with csv2). Cleans up zombie vms which have no more jobs to run and cs isn't shutting down... This is run every every 3 hours via cron

- **canfar_inject_cert**
	- not used anymore

- **canfar_project_remove_prompt**
	- store user creds inside rc file to remove need to input them every time... not very secure...

- **runCondorSubmit.sh**
	- calls `condor_submit` (was used by proc web service in the past)

- **canfar_condor_csv**
	- translates condor history file into csv for stats

- **canfar_job_validate**
	- old and gone

- **canfar_project_restore_prompt**
	- does opposite of `canfar_project_remove_prompt`
