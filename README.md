# Unraid Vendor Reset

I love Unraid. I think it's a nifty base that lets me forget my worries of what software I want to use as a base for my NAS
and just worry about the simple things like "where did I put my sons first steps. I mean, I know they've got to be on one
of these drives".

While Unraid does make it easy for me to just focus on my content and sharing it with others in the house I do wish that
some of the kernel modules that make Virtual Machines more viable were readily available to me. This is currently just a
Stock Unraid kernel that has the vendor_reset module built into bzModules since 6.8.3 lacked the overlay filesystem that
will be included in 6.9. This will be updated as need arises from suggestions about what things will be needed to really
make Unraid an acceptable Virtualization platform.

This buildscript was from ich777's unraid-kernel-helper docker container. I am unclear what happened with the container, 
but a few individuals asked me for help when ich777 no longer had the repository available on github. I had been using 
the container quite regularly to update my kernel with patches and I found that there were a lot of things that I liked
about how it operated. Regardless of the reasoning behind the container being taken down, I want to thank ich777 for a
great script that I have used as a base for my container that I use to build the Unraid kernel for myself and anyone
who may be interested in kernel development. As Unraid continues to be updated, I want this container to morph into a 
more generic module builder that can be called to build overlay modules for a running version of Unraid. This is the
first step towards that goal.

## What it does
 - Patches stock kernel config file to add requirements for vendor_reset
 - Clones latest vendor_reset from gnif's github repository and compiles it into the kernel

## Todo
 - Add configurable modules that are most commonly used
 - Add an output for modules that can be built and used without needing a custom kernel
 - Add multiple versioning to allow older versions of Unraid to work as well as testing future betas
