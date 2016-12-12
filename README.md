# staskfarm

Simple taskfarm script for a Slurm environment.

## Purpose

Take a file of tasks (one per line) and create slurm multi-prog
config to execute those tasks. Each task can comprise of multiple commands.

For Slurm partitions with `OverSubscribe=Yes` (formerly `Shared=Yes`),
**Job Arrays** are a better solution for submitting multiple tasks. However, with
`OverSubscribe=Exclusive`, job arrays will allocate a full node for each serial
task, which is probably not what you want.

## Background

The slurm multi-prog setup can be difficult for some
scenarios:

* only one executable can be specified per task (e.g. no chain of commands
  or shell loops are possible, such as "cd dir01; ./my\_exec")
* a limitation on the maximum number of characters per task description (256)
* building the multi-prog file can be onerous, if you do not have the
  luxury of using the '%t' tokens in your commands or arguments
* the number of commands must match exactly the number of slurm tasks (-n),
  which means updating two files if you wish to add or remove tasks

As noted above, Slurm Job Arrays are a better option to multi-prog, unless
the `OverSubscribe=Exclusive` option is set on the partition.

## Usage

Usage: `staskfarm [-v] command\_filename`

The `<command_filename>` must have one individual task per
line. The task can comprise of multiple bash shell commands,
each separated by a semi-colon (;).

This would be placed inside a normal `sbatch` script as follows:

  #!/bin/sh
  #SBATCH -n 4
  #SBATCH -N 2
  #SBATCH -t 00:30:00     # 1 day and 3 hours
  #SBATCH -p debug        # partition name
  #SBATCH -J my\_job\_name  # sensible name for the job

  # add the staskfarm script to your PATH if necessary
  # run the script, optionally in verbose mode
  staskfarm -v commands.txt

In particular, set the `#SBATCH -n` and `#SBATCH -N` parameters to match
the number of nodes and/or cores that you need; `#SBATCH -n` will define
the maximum number of simultaneous tasks that will be executed..

## Examples

For example, the following `commands.txt` example shows 6 tasks:

    ./my_prog my_input01 > my_output01
    ./my_prog my_input02 > my_output02
    ./my_prog my_input03 > my_output03
    ./my_prog my_input04 > my_output04
    ./my_prog my_input05 > my_output05
    ./my_prog my_input06 > my_output06

Note that if you supply more tasks than allocated CPU cores, it
will allocate them in a simple round-robin manner. So if you have
allocated 8 cores, it is fine to have the following in the `commands.txt`:

    ./my_prog my_input01 > my_output01
    ./my_prog my_input02 > my_output02
    ./my_prog my_input03 > my_output03
    ./my_prog my_input04 > my_output04
    ./my_prog my_input05 > my_output05
    ./my_prog my_input06 > my_output06
    ./my_prog my_input07 > my_output07
    ./my_prog my_input08 > my_output08
    ./my_prog my_input09 > my_output09
    ./my_prog my_input10 > my_output10
    ./my_prog my_input11 > my_output11
    ./my_prog my_input12 > my_output12
    ./my_prog my_input13 > my_output13
    ./my_prog my_input14 > my_output14
    ./my_prog my_input15 > my_output15
    ./my_prog my_input16 > my_output16

A more complex sample `commands.txt`, showing 4 tasks which include loops:

    cd sample01; for i in controls patients; do ./my_prog $i; done
    cd sample02; for i in controls patients; do ./my_prog $i; done
    cd sample03; for i in controls patients; do ./my_prog $i; done
    cd sample04; for i in controls patients; do ./my_prog $i; done

Enabling verbose mode prints each command to stdout as it is
read from the command file.

## Limitations

* it writes the list of tasks to K files, where K is the value of
  of the `SLURM\_NTASKS` environment variable. The tasks are written
  in a simple round-robin manner over the K files. This makes no
  provision for how quickly any individual task might execute
  compared to the others, and so an equal division of labour
  between the `SLURM\_NTASKS` processors is not guaranteed at all.

* it makes no decisions about memory usage per task. The
  assumption is that the user has already calculated memory
  consumption, and has used a combination of `#SBATCH -n <n>`
  and `#SBATCH -N <N>` to fit. For example, if the node has 8
  cores and 16 GB of RAM, then `#SBATCH -n 8` will spread the
  tasks over 8 cores on one machine, and will assume that the
  total memory usage is no more than 16GB (2GB per task). If you
  need 4GB per task, then instead you must use `#SBATCH -n 8`
  and `#SBATCH -N 2` in order to spread the 8 tasks
  over 2 nodes.

* no output redirection is performed, so any stdout/stderr will
  be sent to the `slurm-NNNNN.out` file by default. This can
  be changed by adding individual redirects to each task.
  Care must be taken in that case so that the output files
  have unique names/paths.

Note that this program will create a temporary directory
(called .taskfarm\_job\_${SLURM\_JOB\_ID}) in which to store
the slurm multi-config files.

