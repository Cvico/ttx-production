"""
This class acts as an interface to read LHE and get particle
information using pylhe (https://github.com/scikit-hep/pylhe/)
--------------------------------------------------------------
author: Carlos Vico (carlos.vico.villalba@cern.ch) 
"""
import math
import pylhe
import itertools
import hist
import json
import awkward as ak
import re
import matplotlib.pyplot as plt
import os 

class lhe_reader:
    pdgIds = {
        "g"           : 21,
        "tau"         : 15,
        "nu_muon"     : 14,
        "muon"        : 13,
        "nu_electron" : 12,
        "electron"    : 11,
        "bquark"      : 5,
        "squark"      : 4,
        "cquark"      : 3,
        "dquark"      : 2,
        "uquark"      : 1
    }

    def __init__(self, jsonfile):
        """ Constructor """
        # Get the options from json file
        self.opts = json.load( open(jsonfile, "rb") )
        
        self.open_file(self.opts["lhe-files"])
                
        if not os.path.exists(self.opts["outpath"]):
            os.mkdir(self.opts["outpath"])
        return

    def open_file(self, file_ = None):
        """ Load the events """
        if isinstance(file_, list):
            for file_ in file_:
                self.open_file(file_)
            return 
            
        print(" >> Reading %s"%file_)
        # Read the events
        events = pylhe.to_awkward(pylhe.read_lhe_with_attributes(file_)) 
        if not hasattr(self, "events"):
            self.events = events
        else:
            ak.concatenate((self.events, events), axis = 0)		
        return
    
    def plot(self, what, weights, binning, labels, name, logy = False):
        """ Method to plot stuff """
        fig = plt.figure()
        histo = hist.Hist.new.Reg(binning[0], binning[1], binning[2]).Double()
        histo.fill(
            what,
            weight = weights
        )
        artists = histo.plot1d()
        ax = artists[0].stairs.axes
        if logy: 
            ax.set_yscale('log') 
        ax.set_xlabel(labels[0])
        ax.set_ylabel(labels[1])
        fig.savefig("%s/%s.png"%(self.opts["outpath"], name))
        del fig
