# ttx-production
Configs and code to produce private LHE for Run3 ttX

# Generate pLHE from a gridpack
With the following command:

```python3 submit_plhe.py --nevents $NEVENTS --gridpack  $PATH_TO_GRIDPACK/gridpack_ttw.tar.xz --outpath $OUTPUT_PATH/ttlnu-1jet_newFxFx 352642 --mode slurm ```

That will create $NEVENTS/2000 folders in the output directory, each job will generate 2000 events itself. After producing the events the folder will be removed and we'll only keep the LHE. The fact that this produces batches of 2000 events is so far hardcoded.

# Plot stuff from LHE
Need to write an "options" json as the one provided as example. Then you can run analyses as:
```python3 ttw_analysis.py```

That code in particular will plot some interesting distributions for ttlnu production for the particular case of same-sign dilepton events. 