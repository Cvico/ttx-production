"""
Simple analysis for ttZ->l+l- validation at LHE level
----------------------------------------------------- 
author: Carlos Vico (carlos.vico.villalba@cern.ch) 
"""
import awkward as ak
import hist
from utils.lhe_reader import lhe_reader


def analysis(reader):
    """ Useful distributions for pp > ttl+l- final states """
    particles = reader.events.particles
    weights   = reader.events.eventinfo.weight

    # Create masks to define signal region
    # Exactly two leptons
    mask_2m = ak.count(particles.id[abs(particles.id) == 13], axis = 1) == 2
    mask_2e = ak.count(particles.id[abs(particles.id) == 11], axis = 1) == 2
    mask_2l = (mask_2m | mask_2e)  

	# Apply selection
    selection = particles[mask_2l]
    weights   = weights[mask_2l]

    # Reconstruct the lepton pair
    muons = selection[abs(selection.id) == 13]
    electrons = selection[abs(selection.id) == 11]
    leptons = ak.concatenate((muons, electrons), axis = 1)
    
    ll = leptons.vector[:, 0] + leptons.vector[:, 1]

	# Now plot stuff
	# ============= weights ============= #
    reader.plot( weights, abs(weights), (2, -1, 1), ("Weight", "Count"), "weights" )
    
    # ============= mll ============= #
    reader.plot( ll.mass, weights, (20, 0, 150), ("Mass [GeV]", "Count"), "inv_mass", logy = True )

    return

if __name__ == "__main__":
	# Open options file
	reader = lhe_reader("options_ttll.json")
	analysis(reader)
    

