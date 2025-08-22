# SoIB Container

SoIB container is a concept/package that allows you to run SoIB on any platform
without going through the process of installing any dependencies, and with a
minimum of privileges.  You'll typically get this package as as a ZIP
file : soib-container.zip

This file includes everything required to try out a subset of the SoIB computation.
Specifically, Part 3 Step 1. This is the compute intensive step that is typically
run across multiple machines. This container helps run a single iteration
(out of the 1000) for the full country, for testing and validation of the
container concept.

The container includes some of the SoIB code, an R installation with all
dependent packages, and some required data - including sensitive species.
So please do not pass on this container to people who are not supposed
to have access to the data.

The container can potentially package the entire dataset later (all region
masks, random IDs, etc). That is not done right now to keep the file size
smaller for testing.

# Operating Systems

The container may be used under Linux, or under Windows - using WSL(Windows
Subsystem for Linux).

# Getting Started and Basic Usage

Extract the ZIP package.  It includes a directory "soib-container". Change to
that directory on your terminal.  Then follow the OS specific steps.

## Linux

### Install Podman

Recommended tool to run the container is podman.  This may be installed
using your regular package manager.  E.g., on ubuntu, use

    $ sudo apt update && sudo apt install -y podman

### Create the container

Run this command

    $ podman load -i x86_64/soib.tar

You should see output such as:

    Getting image source signatures
    Copying blob 018061dfc73b skipped: already exists
    Copying blob aa8ee6a3b6ad skipped: already exists
    Copying blob d0112744eae5 skipped: already exists
    Copying blob 6e60de00e158 skipped: already exists
    Copying blob c5f08d14b7e1 skipped: already exists
    Copying blob 6f8f9d6a2dff skipped: already exists
    Copying blob e9c1249fc42c skipped: already exists
    Copying blob 4833e1223c04 skipped: already exists
    Copying blob 40411a808299 skipped: already exists
    Copying blob 418dccb7d85a skipped: already exists
    Copying blob be302c00df36 done   |
    Copying blob 7dd24ce0fe57 done   |
    Copying blob 4573d540eb85 done   |
    Copying blob 6124306be98e done   |
    Copying config adeeaae89d done   |
    Writing manifest to image destination
    Loaded image: localhost/soib:latest

The container is now installed.

### Running the container

Simply start run_container.sh as below

    $ sh run_container.sh

You'll see familiar output of execution of the script.

### Output

After the container finishes running successfully, the species trends output will be
in output/trends_1.csv

## Windows

To use the container, you need to have WSL(Windows Subsystem for Linux) installed.
Installation and usage of WSL is out of the scope of this document.

With WSL installed, the usage steps are exactly the same as Linux.  In Linux,
you would use the terminal to execute the commands. In WSL, you first run "wsl"
to start the WSL shell.

### Install Podman

Inside the wsl shell, execute

    $ sudo apt update && sudo apt install -y podman

### Create the Container

Run this command inside the wsl shell

    $ podman load -i x86_64/soib.tar

### Running the container

Simply start run_container.sh inside the wsl shell as below

    $ sh run_container.sh

You'll see familiar output of execution of the script.

### Output

After the container finishes running successfully, the species trends output will be
in output/trends_1.csv

### Memory Limits on WSL

By default, Windows allocates about 50% of your system's memory (RAM) to WSL.
SoIB needs a lot of memory to run. Without changing the amount of memory
allocated to WSL, you may find that the container takes a long time to finish,
as it won't start many parallel jobs to ensure the RAM limit is not hit.

You can setup a specific memory limit by editing the file .wslconfig in your
user profile directory. e.g. to setup a limit of 16 GB, the contents of the
file may look like below:

    [wsl2]
    memory=16GB

For the change to take effect, you will need to shutdown any running WSL instance,
using:

    wsl --shutdown

# Additional Usage Notes

The output directory has a file config.R, using which you can configure the
number of threads, as well as which species to run trends calculation for.

## Threads

By default, the container will try to run multiple threads - as many as half
the number of cores, subject to RAM limits.  This is a good default choice.
But you can bump this number up or down by setting the "threads" variable
in output/config.R . Bumping up the threads to match cores may make sense
on computers with a lot of memory bandwidth, eg

    threads <- 32

Reducing the number of threads is a useful thing for testing or observing
RAM and CPU consumption patterns.

    threads <- 1

## Species List

By default, trends calculations are done for all species.  You may choose
a subset of species by naming them "species_to_process" variable inside
output/config.R . E.g., to run for just two species:

    species_to_process <- c(
      "Coppersmith Barbet",
      "Oriental Magpie-Robin"
    )
 
Leaving the list empty or not defining species_to_process in config.R will
run the trends calculations for all species.  Species names are not validated,
so ensure they are in the list. Else the script may fail.
