# Batch processing using HTCondor and CSV2

CANFAR provides a batch scheduling service which allows users to run jobs using prepared VM images. The base system consists of a submission host (condor.canfar.net) running HTCondor and a companion server running Cloudscheduler V2 (CSV2) which allows jobs to be run on multiple clouds simultaneously.  This multi-cloud job scheduling system aims to be easy to use and robust, due to its distributed nature. This document describes the steps needed to use this system.

The general procedure for submitting jobs consists of first preparing a VM image on the Arbutus CANFAR Openstack cloud. The user then connects to the condor submission host via ssh and prepares a submission script.

Before you can use the batch system, you will need to have a CADC account… (link)

Once you have your account, send an email to CANFAR support (email) and include:

a CADC account name
a rough amount of required resources (storage capacity and processing capabilities), and if you need batch processing
a few sentences describing what you want to do.
Your request will be reviewed and you will be contacted by the CANFAR team which will also take care of your registration to Compute Canada infrastructure.

## Super Quick Guide:

- Prepare a VM Image on CANFAR Arbutus and create a snapshot with a unique name
- Connect to condor.canfar.net via ssh and prepare a job submission file based on the example included in your home folder.
- Submit your jobs using the command canfar_submit myjob.sub

Now let’s go through these steps in detail:


## VM image preparation

- Login to the CANFAR Arbutus and navigate to the “Instances” section. 
- Launch a new VM instance using the “Launch Instance button on the upper right. 
- In the “Source” section select the base image you wish to use. This document will assume Ubuntu 20.04, but other Linux types are also acceptable.
- In the “Flavor” section select an appropriate VM type for your job requirements.
- In the “Network” section select the network appropriate to your project.
- In the “Key Pair” section select the ssh key pair you wish to use to access your VM. If you haven’t already added a key pair, you can do so using either the “Create Key Pair” or “Import Key Pair” buttons at the top of the window.
- Review the other available options to ensure all is as you want.
- Launch your instance using the “Launch Instance” button on the lower right.
- Once the instance is running, assign it a Floating IP using the dropdown menu under the “Actions” column.

### Configuring your VM:

- SSH into your running instance using the key pair your selected.
- Update your VM to as required. For ubuntu run sudo apt-get update
- Install the HTCondor package. This is essential for the condor server and CSV2 to communicate with your future jobs. For ubuntu it can be installed with: sudo apt-get install -y htcondor
- Configure the VM to run your job as required. Make sure the job actually runs on the VM before continuing to the batch submission steps. You’ll save yourself a lot of headaches if you do this.
- When you are satisfied your job runs on the VM, create a snapshot of the running instance using the “Create Snapshot” option from the dropdown menu in the Actions column in Openstack. Give the snapshot a unique name. This is very important as CSV2 relies on your VM image having a unique name to correctly select it. 
- 

## Prepare your batch submission file:

- Connect to the batch submission host using your CADC username: ssh username@condor.canfar.net
- In your home directory you will find an example directory with a sample job. As a first test look at the example.sub file and submit a test job using canfar_submit example.sub
- To prepare a submission file to run your jobs, you can you the example.sub file as a template. Let’s review the required parameters:

`+VMImage = "canfar-rocky-8"`
- This should be the name of the VM snapshot you created previously.

`request_cpus = 1

request_memory = 1000

request_disk = 1000`
-These are the resources required to run your job. By default the memory is given in Kb and the disk space in Mb.

`should_transfer_files = yes`
- This option ensures executable is transferred from the condor submission host to the VM which is booted by the batch system.

`Executable = simple`
- This is the name of the executable you wish to run on your prepared VM image. When preparing your VM image and snapshot you should test to make sure this executable runs as expected and has the required dependencies. This executable should should exist in the directory you submit your jobs from, or you can specify a relative path if it rests elsewhere on condor.canfar.net.

`Arguments  = 600 10`
- These are the command line arguments you would supply to the executable when running in manually in a terminal. Again, this should be tested while preparing the VM image and snapshot.

`Log        = simple1.log
Output     = simple1.out
Error      = simple1.log`
- These are the names of the log files produces when running the executable. These can output to the same file, or be separate files for each log type.

`Queue`
- This indicates the end of a job entry. As shown in example.sub you can have multiple jobs submitted simultaneously with different input parameters.

You may include other condor parameters as you see fit to run your job. A complete list of options can be found here: https://htcondor.readthedocs.io/en/latest/users-manual/submitting-a-job.html

Once your submission file is prepared, ensure your executable file is in the same directory as the submission file, and submit your job using:
  canfar_submit yourjob.sub

The canfar_submit command is a wrapper script which reads your submission file and checks its validity and then adds some extra parameters needed by condor. It then calls the condor_submit command. The script also interacts with CSV2 and transfers your image snapshot to the batch processing clouds. 

## Monitoring your jobs:

Once your jobs are submitted you can check their status using several different methods.

On the condor submission host you can execute the following useful commands:

condor_status
- This will show your running jobs in table format. If your jobs are all completed or failed to run, then this will return nothing. This command is a good place to start.

condor_q -better-analyze
- This command will give you detailed information about your submitted jobs, including those that failed. If your jobs fail to start, look carefully at the output of this command and it will usually tell you the problem.

You can also view the status of CSV2 using the publically available dashboard. This will give you a global view of the system which includes data on all jobs which are running, including from other users: https://csv2-canfar.heprc.uvic.ca/cloud/status/?canfar

