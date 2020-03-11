

# Canfar user flow:


* user creates CADC account:
    -They need a VO Space account

* user needs to be added to OpenStack cloud: 
    - go to group managment system, canfar.net - login with cadc
    - add user to group arbutus-cloud-users as member
    - add user (cadc username) to cadc project


* ssh to batch.canfar.net as admin-> hosts cs and condor
    - sudo canfar_create_batch_user cadcusername projectname -> this must be on group cadc... important!
      eg: sudo canfar_create_batch_user casteels cadc
    - for new user, add key to .ssh/authorized_keys in users home directory 

* The user can then submit their jobs to the condor job pool with the "canfar_submit" command:
      eg: canfar_submit quick_start.sub quick_start-0.1 c2-7.5gb-31

* A proxy cert is issued from OpenStack GUI (generated from grid canada cert with expiry). getCert command pulls in (cadc_cert command in canfar_submit) (cadc_cert can be replaced by getcert)

* condor will upload cert to workers... gives access to vospace



# Steps to create new users:


  l. goto os arbutus gui using canfarops account, download name-openrc.sh file
  l. copy openrc file to batch under canfarops
  l. copy openrc into projects-openrc in canfarops dir
  l. sudo canfar_create_user username projectname
  l. canfar_project_remove_prompt name-openrc.sh (be sure to use canfarops password, for stats)
  l. mv name-openrc.sh /mnt/stats/openstack/projects/arbutus



# Flow diagram:

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

## canfar_submit:

### DESCRIPTION:

 User script for submitting jobs. A wrapper for canfar_translate_vm, canfar_job_validate and condor_submit. Normally a user should use canfar_translate_vm so that the job goes through the web service. This script avoids the web service and can submit jobs directly on the head node for testing purposes.

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
      canfar_submit [OPTION] JOB_FILE VM_IMAGE VM_FLAVOR

### FLOW:

  - Store all input options options

  - Verify input and warn if you are submitting jobs without a VOSPace access certificate

  - If one of the argument requirements fails, the script will exit.


  - Validate user's job file (in jdl format typically with a \*.sub extsion, although this doesn't matter in practice).

  - First the executable is extracted

  - Ensure user has authorized access to their op project via sourcing rc file..

  - Share the image and translate image and flavor names to their IDs, which is what canfar_job_validate expects.

  - "canfar_translate_vm" is called to share images to other projects, it then returns the image ID and flavor ID (UUID)

  - "canfar_job_validate" is then called and modifies the user submitted jdl file.  It adds some options and variables to the top of the user submitted job script to make it compatible with the conder and cloudscheduler v1 system.

  - "cadc_cert" is called to inject user certs into the vm (this is not often used... maybe not needed by most users.)

  - The modified jdl file is then summited condor by calling "condor_submit"




## canfar_translate_vm:

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
      canfar_translate_vm [options] VM_IMAGE VM_FLAVOR


### FLOW:

  - Get cloud credentials from system environment variables

  - Parse command line

  - Get cloud credentials from system environment variables

  - Need an image ID. If the user supplied a name, convert it to ID.

  - List images and search for ID

  - Share the image with batch project

  - CANFAR project ID is allowed to access user image (g is glance) 

  - We will require a flavor ID. If the user supplied a name, convert it to ID.



## canfar_job_validate:

### DESCRIPTION:

  A user provides a bare condor job description file, as well as image and flavor IDs.

  This script validates these inputs and writes an augmented condor job file including extra cloud scheduler parameters to stdout (or a specified output file), and also generates a cloud-config script that cloud scheduler will use to configure running instances of the VM to work with Condor.

  Bad exit status is set upon failure.

### INPUTS:
      CM_IP
      CERT_USER
      JOB_USER
      JOB_FILE
      JOB_SCRIPT
      VM_IMAGE_AND_FLAVOR_IDS

### USAGE:
      canfar_job_validate CM_IP CERT_USER JOB_USER JOB_FILE JOB_SCRIPT VM_IMAGE_AND_FLAVOR_IDS


### FLOW:

* Parse command line

* Check for valid UUIDs

* Check parameters in jobfile

* Re-write 'Executable' line since the proc web service will have placed it somewhere different from the user's original location

* Determine the name of the image from its UUID, and the name of the project that owns it. First we get a glance client to get the name of the given image ID. We then query that image's metadata to obtain its owner project id. Finally, we use a second keystone client scoped to the image's owner project to obtain its project name.

* Generate cloud config file for this user as follows:

   - inject a public ssh key into the generic user account
   - write and execute the cloud scheduler configuration script
   - image_name and image_user are used by canfar_batch_init to set the VMType. If not specified defaults to $HOSTNAME and $USER the full output path name of the configuration script when copied into the VM



# Other script descriptions:


- **cadc_cert** -> wrapper for getCert          

- **canfar_condor_user_stats** -> runs as a cronjob to extract stats from condor_history

- **canfar_list_quotas** -> gens csv cores, id, gigs (disk usage), ram name of canfar projects

- **canfar_project_stats** -> cronjob which creates stats for openstack, loops throught projects and rungs "openstack usage show"

- **canfar_update_default_image** -> perpares canfar default snapshots and shares them with all projects...

- **cadc_dotnetrc** - adds user creds for cadc 

- **canfar_create_batch_user** -> adds a user to batch.canfar.net with an accociated os project..

- **canfar_openstack_stats** -> outputs cores-years within a specified data range


- **canfar_share_vm** -> shares a vm/snapshot between projects. it also does acceptance on opentstack side, used by canfar_update_default_image

- **runCanfarJobValidate.sh** -> calls canfar_job_validate (not used...)

- **canfar_cloud_cleanup**  -> cleans up vms which get lost between condor and cs. (probably not needed with csv2). Cleans up zombie vms which have no more jobs to run and cs isn't shutting down... This is run every every 3 hours via cron

- **canfar_inject_cert** -> not used anymore

- **canfar_project_remove_prompt** -> store user creds inside rc file to remove need to input them every time... not very secure...

- **runCondorSubmit.sh** -> not used

- **canfar_condor_csv**  -> translates condor history file into csv for stats

- **canfar_job_validate** -> old and gone

- **canfar_project_restore_prompt** -> does opposite of canfar_project_remove_prompt







