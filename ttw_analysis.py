"""
Simple analysis for ttZ->l+l- validation at LHE level
----------------------------------------------------- 
author: Carlos Vico (carlos.vico.villalba@cern.ch) 
"""
import awkward as ak
import hist
from utils.lhe_reader import lhe_reader


def analysis(reader):
    """ Useful distributions for 2lss final states """
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

	# Select two same sign leptons
    mask_samesign = leptons.id[:, 0] * leptons.id[:, 1] > 0

    leptons   = leptons[mask_samesign]
    particles = particles[mask_samesign]
    weights   = weights[mask_samesign]
    
    # Get the neutrinos
    neutrinos_muons = particles[abs(particles.id) == 14]
    neutrinos_electrons = particles[abs(particles.id) == 12]
    neutrinos = ak.concatenate((neutrinos_electrons, neutrinos_muons), axis = 1)
    
    # Get the jets
    ujets = particles[abs(particles.id) == 1 ]
    djets = particles[abs(particles.id) == 2 ]
    cjets = particles[abs(particles.id) == 3 ]
    sjets = particles[abs(particles.id) == 4 ]
    bjets = particles[abs(particles.id) == 5 ]
    jets = ak.concatenate((ujets, djets, cjets, sjets, bjets), axis = 1)
    
    # Sort jets by pt
    jets = jets[ak.argsort(jets.vector.pt, axis = 1, ascending = False)]
    
    # Now plot stuff
	# ============= weights ============= #
    reader.plot( weights, abs(weights), (2, -1, 1), ("Weight", "Count"), "weights" ) # Use abs(weights) so no negative bins appear

    # ============= Jet pts ============= #
    reader.plot( jets.vector.pt[:, 0], weights, (20, 0, ak.max(jets.vector.pt[:, 0])), (r"Leading jet $p_T$ [GeV]", "Count"), "jet1_pt" )
    reader.plot( jets.vector.pt[:, 1], weights, (20, 0, ak.max(jets.vector.pt[:, 1])), (r"Subleading jet $p_T$ [GeV]", "Count"), "jet2_pt" )

    # ============= mll ============= #
    reader.plot( (leptons.vector[:, 0] + leptons.vector[:, 0]).mass, weights, (20, 0, 150), (r"Leading jet $p_T$ [GeV]", "Count"), "jet1_pt" )

    return

if __name__ == "__main__":
	# Open options file
	reader = lhe_reader("options_ttlnu.json")
	analysis(reader)
    

