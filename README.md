# Ultraviolet-Tutorial
This is an unofficial quick start tutorial for NYU's UltraViolet HPC, intended for statistical analysts with no prior experience with remote SSH or Linux.

- Official guide: https://hpcmed.org/guide
- Wiki: http://bigpurple-ws.nyumc.org/wiki/index.php/BigPurple_HPC_Cluster

## Before getting started: software recommendataions
### Windows
- MobaXTerm (console access + file transfer + light editing): https://mobaxterm.mobatek.net/

Also consider:
- WinSCP (file transfer): https://www.winscp.net/

### Mac
- Terminal (console access): Included

Also consider:
- Filezilla (file transfer): https://filezilla-project.org/
- XQuartz (enable graphic user interface for Stata and SAS): https://filezilla-project.org/

### Web interface
OnDemand: https://ondemand.hpc.nyumc.org/

Navigate your directories and submit batch jobs on your web browser. VPN needed.

### Text editors
Consider [Sublime Text](https://www.sublimetext.com/) or [VSCode](https://code.visualstudio.com/) to edit Stata or R scripts.


## Logging into UltraViolet
VPN access is needed when you’re off-campus: https://atnyulmc.org/help-documentation/NYU-Langone-Advanced-Access-App

Read this first: https://hpcmed.org/guide/bigpurple

Once you log in, you'll see:
```
   __  __  __  __                   _    __  _           __         __
  / / / / / / / /_  _____  _____   | |  / / (_) ____    / / ___    / /_
 / / / / / / / __/ / ___/ / __  |  | | / / / / / __ \  / / / _ \  / __/
/ /_/ / / / / /_  / /    / /_/  |  | |/ / / / / /_/ / / / /  __/ / /_
\____/ /_/  \__/ /_/     \____/\_\ |___/ /_/  \____/ /_/  \___/  \__/
                                           NYU Langone Health HPC

Use the following commands to adjust your environment:

module avail            - show available modules
module add <module>     - adds a module to your environment for this session
module initadd <module> - configure module to be loaded at every login


    BigPurple User Guide available at: http://bigpurple-ws.nyumc.org/wiki
    New HPC Portal: https://hpcmed.org/


    HPC Community town hall is held every Thursday from 12 to 1 PM.
    Meeting link: https://nyumc.webex.com/meet/siavoa01

    You may email <hpc_admins@nyumc.org> for any further assistance.


    Quarterly maintenance, schaduled for June 9th, 2024 IS POSTPONED.
    The new date will be announced well in advance to reduce the
    impact to computational researches.

Loading default-environment
  Loading requirement: slurm/current

[baes03@bigpurple-ln2 ~]$
```
You are in the login node. Your command prompt shows `ln2`. 

## Developing your script in an interactive session - Part 1
Use this workflow only for light development purposes. Your final results must come from a batch job for reproducibility.

Read this first: https://hpcmed.org/guide/slurm#headings2

### 1. Log in to an actual computing node. 

Run this command: `srun -p cpu_short --mem-per-cpu=4G -t 00-02:00:00  --pty bash`

```
[baes03@bigpurple-ln2 ~]$ srun -p cpu_short --mem-per-cpu=4G -t 00-02:00:00  --pty bash
srun: job 48302015 queued and waiting for resources
srun: job 48302015 has been allocated resources
[baes03@cn-0012 ~]$
```
Now your command prompt shows `cn-0012`.

You can request more memory by increasing  `--mem-per-cpu` and longer runtime by increasing `-t`.

### 2. Load modules

Loading stata: `module load stata`

Loading R: `module load r`

List of available modules: https://hpcmed.org/guide/modules

### 3. Starting programs

Stata (CLI): `stata`

Stata (GUI): `xstata` (You need X11. Use MobaXTerm or XQuartz.)

R (CLI): `R`


## [VS Code only] Developing your script in an interactive session - Part 2
VS Code uses Remote-SSH, which occupies the login node. It can cause problems. 

If you want to use VS Code and run any sort of actual analyses interactively, use this workflow instead. Your final results must still come from a batch job for reproducibility.

### 1. Request a computing node.
Run this command: `sbatch --time=04:00:00 --mem=10GB --wrap "sleep infinity"`

```
[baes03@bigpurple-ln3 ~]$ sbatch --time=04:00:00 --mem=10GB --wrap "sleep infinity"
Submitted batch job 54768978
[baes03@bigpurple-ln3 ~]$ status
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          54740899 cpu_mediu Full_mod   baes03  R    5:28:15      1 cn-0012
          54768978 cpu_short     wrap   baes03  R       0:01      1 cn-0008
```
Now you have a session on `cn-0008`.

On VS Code, open 'Remote Explorer' from the menu bar on the left. On the top, there's a row named SSH. Bring your mouse pointer and click on the gear icon named 'Open SSH Config File'. Probably pick the first one. Add these lines and save.

```
Host bigpurple-compute
  HostName [Change this to the computing node you got. In this example, this should be cn-0008]
  User [Your ID]
  ProxyJump [Your ID]@bigpurple.nyumc.org
  StrictHostKeyChecking no
  UserKnownHostsFile /dev/null
  LogLevel ERROR
```
Now on your Remote Explorer, you'll find a new server called 'bigpurple-compute'. Open it in a new window. VS Code connects directly to `cn-0008` without bothering the login node.

Next time, you just need to update the `HostName` to match the computing node you were assigned to.


## Where to find datasets
### SRTR
Go to `/gpfs/data/massielab/data/srtr`. You’ll see many subdirectories named `srtrYYMM`. 

`YY` and `MM` are the year and month of the release. SRTR releases datasets quarterly, plus when necessary. We will use the latest release with the standard analysis files (SAFs) in most cases. 

You’ll probably start with the TX_KI dataset. 

Data dictionary available here: https://www.srtr.org/requesting-srtr-data/saf-data-dictionary/

### USRDS
The latest release available here: `/gpfs/data/easelab/data/USRDS/stata`

Previous versions (e.g. 2022 release) here. You probably won’t need this: `/gpfs/data/easelab/data/USRDS/USRDS2022`

USRDS researcher’s guide has data file descriptions, data dictionary, and more: https://www.niddk.nih.gov/about-niddk/strategic-plans-reports/usrds/for-researchers/researchers-guide


## Running your completed script as a batch job
### R
Suppose you want to run an R script called `demo.r`, which is stored at `~/demo_project`.

Create a text file called `run_demo.sh`, with the script below. Make sure you update `[YOUR EMAIL]`
```
#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=10:00:00
#SBATCH --mem=8GB
#SBATCH --job-name=demo
#SBATCH --mail-user=[YOUR EMAIL]
#SBATCH --mail-type=END
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

module load r

cd ~/demo_project
R CMD BATCH --no-restore --no-save demo.r
```

Now, go to the directory where you stored `run_demo.sh`, and run
```sbatch run_demo.sh```


### Stata
Suppose you want to run a Stata script called `demo.do`, which is stored at `~/demo_project`.

Create a text file called `run_demo.sh`, with the script below. Make sure you update `[YOUR EMAIL]`
```
#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --time=10:00:00
#SBATCH --mem=8GB
#SBATCH --job-name=demo
#SBATCH --mail-user=[YOUR EMAIL]
#SBATCH --mail-type=END
#SBATCH --output=/dev/null
#SBATCH --error=/dev/null

module load stata

cd ~/demo_project
stata-mp -b do demo.do
```

Now, go to the directory where you stored `run_demo.sh`, and run
```sbatch run_demo.sh```

### Check the status of your batch jobs
```
squeue -u $USER
```

### Cancel batch jobs
Basic command: `scancel [JOBID]`

In action:

Check your JOBID first
```
[baes03@cn-0032 bin]$ squeue -u $USER
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
          48302494 cpu_short     bash   baes03  R       0:27      1 cn-0032
```
Then cancel it!
```scancel 48302494```



### Creating shortcuts for `sbatch`
1. Go to `~/bin`. If you don't have one, create one.
```
cd ~/
mkdir bin
cd ~/bin
```

2. Create two files.
   
First, create `srun_r` (no extension). Open the file in any text editor (like the MobaXTerm internal editor). Put the script below into `srun_r` and save it.
```
echo '#!/bin/bash
module load stata
stata-mp -b do '$1 | sbatch --output=/dev/null --error=/dev/null --job-name=$1 --time=24:00:00 --ntasks=1 --cpus-per-task=1 --mem-per-cpu=6G --mail-user=[YOUR EMAIL HERE] --mail-type=END,FAIL
```

Second, create `srun_stata` (no extension). Put the script below.
```
echo '#!/bin/bash
module load r
R CMD BATCH --no-restore --no-save '$1 | sbatch --output=/dev/null --error=/dev/null --job-name=$1 --time=24:00:00 --ntasks=1 --cpus-per-task=1 --mem-per-cpu=6G --mail-user=[YOUR EMAIL HERE] --mail-type=END,FAIL
```

All done! Let's try these. 

Go to your project directory, and run your script. Let's say its name is `demo.r`
```
cd ~/demo_project
srun_r demo.r
```

If Stata,
```
cd ~/demo_project
srun_stata demo.do
```

