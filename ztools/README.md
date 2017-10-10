# ztools

 * gitrepo

 * mavrothal's patch-generator.sh from  
 http://murga-linux.com/puppy/viewtopic.php?t=98740

 Modified to also work on "rationalise" branch, and to generate patch files of woof-CE build scripts.

## Usage

### gitrepo

Run `gitrepo` from the location where you want to clone woof-CE and follow the prompts.

### patch-generator.sh

Before using patch-generator.sh, copy it to the directory that contains the woof-CE directory.

To generate patches of the differences between the running system and woof-CE  
`./patch-generator.sh`

To generate patches of the differences between the running system's main sfs and woof-CE  
`./patch-generator.sh sfs`

To generate a patch file for a script in woof-out... that you edited, for example  
`./patch-generator.sh woof-out_x86_arm_raspbian_jessie/3builddistro-Z`

this will make a 3builddistro-Z.patch file in a directory named patches that contains any differences between
woof-out_x86_arm_raspbian_jessie/3builddistro-Z and woof-CE/woof-code/3builddistro-Z
