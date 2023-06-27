"""
Script to generate LHE from a CMS gridpack
--------------------------------------------------
author: Carlos Vico (carlos.vico.villalba@cern.ch)
"""

import os
import sys
from optparse import OptionParser
import random
import time

def add_parsing_opts():
    """ Function with base parsing arguments used by any script """
    parser = OptionParser(usage = "python nanogen_analysis.py [options]", 
                        description = "Main options for running nanogen analysis") 
    parser.add_option("--nevents", dest = "nevents", default = 2000, type = int,
                help = "Number of events to be generated.")
    parser.add_option("--gridpack", dest = "gridpack", default = "gridpacks/gridpack_ttw_ptj20.tar.xz",
                help = "gridpack to run with")
    parser.add_option("--mode", dest = "mode", default = "local",
                help = "Whether to run on local or batch mode. Available: slurm.")
    parser.add_option("--outpath", dest = "outpath", default = "foolder",
                help = "Outpath where to write files.")
    parser.add_option("--pretend", dest = "pretend", default = False, action="store_true",
                help = "Do not execute the commands, just print them.")
    return parser

def logmsg(class_obj, func, msg):
    print("[{}::{}]: {}".format(class_obj.__class__.__name__, func, msg) )
    return

class job(object):
    abort_submit = False
    def __init__(self, jobmetadata, jobid, seed):
        """ Instance of a job """
        self.jobmetadata = jobmetadata
        self.jobid = jobid
        self.seed = seed
        self.prepare_job()
        return
    
    def create_folder(self):
        outf = os.path.join( self.jobmetadata.outpath, "job%d"%self.jobid )
        if not os.path.exists(outf):
            os.system("mkdir -p %s"%outf)
        else:
            logmsg(self, "create_folder", "WARNING: Output folder {} already exists! ".format(outf))
        self.outf = outf
        return
    
    def check_gridpack(self):
        """ Check if the gridpack is visible from the production folder for a given job """
        doesExists = os.path.exists(self.jobmetadata.gridpack)
        if not doesExists:
            logmsg(self, "check_gridpack", "ERROR: Gridpack {} not visible from {} --> \
                Please give full paths to gridpacks to avoid these problems.".format(
                self.jobmetadata.gridpack,
                os.getcwd()
            ))
            sys.exit()
        return True
    
    def prepare_job(self):
        """ Prepare output """
        # 1. Output folder
        self.create_folder()
        submission_path = os.getcwd()
        os.chdir(self.outf)
        self.check_gridpack()
            
        # 2. Prepare script
        # Create the file
        f = open("submit.sh", "w")
        
        script = [
            "#!/bin/bash",
            "seed={}".format(self.seed),
            "gridpack={}".format(self.jobmetadata.gridpack),
            "here=`pwd`",
            "# --- Untar the gridpack",
            "mkdir -p temp_folder",
            "tar -xvf $gridpack -C temp_folder",
            "# --- Change directory and run the production",
            "cd temp_folder",
            "./runcmsgrid.sh {nevents} {seed} 1".format(nevents = self.jobmetadata.nevents_per_job, 
                                                        seed = self.seed),
            "mv cmsgrid_final.lhe ../",
            "cd ../",
            "# Now remove the temporary folder",
            "rm -rf temp_folder",
            "cd $here"
        ]
        f.write("\n".join(script))
        f.close()
    
        # Make it executable
        os.system("chmod +x ./submit.sh")
        
        # 3. Return to the main folder
        os.chdir(submission_path)
        return job
    
class job_submitter(object):
    """ Class to handle job submission in batch """
    nevents_per_job = 2000 # Hardcoded
    def __init__(self, metadata):
        """ Constructor """
        self.gridpack = metadata.gridpack
        self.nevents  = metadata.nevents
        self.outpath  = metadata.outpath
        self.pretend  = metadata.pretend
        self.mode     = metadata.mode
        
        self.configure_jobsubmission()
        return

    def configure_jobsubmission(self):
        """ Configure job submission metadata. """
        self.njobs = self.nevents // self.nevents_per_job
        return
    
    def PrepareJobs(self):
        """ Instance and configure each job before submission"""
        self.jobs = [job(self, jobid, random.randint(0, 65535)) for jobid in range(self.njobs)]       
        return 
    def get_submit_cmd(self, mode):
        if mode == "local":
            return "./submit.sh"
        elif mode == "slurm":
            return "sbatch -J plhe './submit.sh'"
        return 
    
    def SubmitJobs(self):
        """ Proceed with the submission """
        here = os.getcwd()
        for job in self.jobs:
            # Change to the folder where the script is stored
            os.chdir(job.outf)
            
            cmd = self.get_submit_cmd(self.mode)
            os.system(cmd)
            os.chdir(here)
        return   
    
if __name__ == "__main__":
    print(" >> Generating private LHE")
    parser = add_parsing_opts()
    (opts, args) = parser.parse_args()

    # Few checks for the seed because it's very important
    # since this main seed is later used for seeding each
    # job.

    if len(args) != 1:
        raise RuntimeError("PROBLEM!!! Please give just one argument for the seed! Be aware that this number \
            is used for seeding each job, so be very careful.")
    
    seeds_file = "used_seeds.dat"
    opt = "r"
    if not os.path.exists(seeds_file):
        opt = "w"
    
    if opt == "r":
        f = open(seeds_file, opt)
        seeds = [seed.replace("\n", "") for seed in f.readlines()]
        if args[0] in seeds:
            print("PROBLEM!!! Seed {} has already been used before!!! Check very carefully \
                you are not using the same seed as in a previous production of the same process.".format(args[0]))
            f.close()
            sys.exit()
        f.close()
    
    # If the check is ok, add the seed to the list of used seeds
    f = open(seeds_file, "a")
    f.write(args[0] + "\n")
    f.close()
    
    random.seed = int(args[0])
    js = job_submitter(opts)
    
    print(" >> Preparing jobs...")
    preparejobs = js.PrepareJobs()
    
    # Wait a bit just to make sure everything is written
    time.sleep(10)

    print(" >> Submitting jobs...")
    js.SubmitJobs()
    print(" >> All jobs submitted!")


