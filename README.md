# ttx-production
Configs and code to produce private LHE for Run3 ttX

## Install code
This automatically installs all the code needed to run mg5_aMC@NLO (3.3.X).
```
./makeit.sh
```

## Generate events
Choose a card from the cards file and execute.
```
cp cards/$PROCESS/* .
source configure.sh # To activate python3.9
mg5_aMC proc_card.dat
```

This will take it's time to compile all the directories, once it is done, copy the remaining cards (run_card, proc_card, param_card and madspin_card into the created directory). For example for ttW the workflow would be:

```
cp cards/TTWJetsToLNu_5f_fxfx/* .
source configure.sh # To activate python3.9
mg5_aMC proc_card.dat

cp *dat TTWJetsToLNu_5f_fxfx/Cards/
cd TTWJetsToLNu_5f_fxfx

# Now generate events up to parton level
python3 bin/generate_events.py -p 
```



