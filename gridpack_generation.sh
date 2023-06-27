######################################################
# Gridpack generation using private MG installation  #
# author: Carlos Vico (carlos.vico.villalba@cern.ch) #
######################################################


# Define some variables
# -- Locations
name=${1}
carddir=${2}


set_run_card_pdf () {
    name=$1
    CARDSDIR=$2
    maindir=$3
    pdfExtraArgs=""
    
    # This is not a general script so just set that we produce with 5FS
	pdfExtraArgs+="--is5FlavorScheme "
    

    if grep -q -e "\$DEFAULT_PDF_SETS" $CARDSDIR/${name}_run_card.dat; then
        local central_set=$(python $maindir/utils/getMG5_aMC_PDFInputs.py -f "central" -c run3 $pdfExtraArgs)
        echo "INFO: Using default PDF sets for Run 3 production"

        sed "s/\$DEFAULT_PDF_SETS/${central_set}/g" $CARDSDIR/${name}_run_card.dat > ./Cards/run_card.dat
        sed -i "s/ *\$DEFAULT_PDF_MEMBERS.*=.*//g" ./Cards/run_card.dat
    else
        cat << EOF

        WARNING: You've chosen not to use the PDF sets recommended for 2017 production!
        If this isn't intentional, and you prefer to use the recommended sets,
        insert the following lines into your process-name_run_card.dat:

            '\$DEFAULT_PDF_SETS = lhaid'
            '\$DEFAULT_PDF_MEMBERS = reweight_PDF'
        
EOF
        echo "copying run_card.dat file"
        cp $CARDSDIR/${name}_run_card.dat ./Cards/run_card.dat
   fi
}

# Make some replacements in run card (mostly related to PDF)
# and copy to correct directory
# Args: <process_name> <cards directory> <is5FlavorScheme> 
prepare_run_card () {
    name=$1
    CARDSDIR=$2
	maindir=$3

    set_run_card_pdf $name $CARDSDIR $maindir

    # Set maxjetflavor according to PDF scheme
    nFlavorScheme=5
    if grep -Fxq "maxjetflavor" ./Cards/run_card.dat ; then
        sed -i "s/.*maxjetflavor.*/${nFlavorScheme}\ =\ maxjetflavor/" ./Cards/run_card.dat 
    else
        echo "${nFlavorScheme} = maxjetflavor" >> ./Cards/run_card.dat 
    fi

	# This is not a general script so just set that we produce at NLO
	echo "False = reweight_scale" >> ./Cards/run_card.dat 
	echo "False = reweight_PDF" >> ./Cards/run_card.dat 
	echo "True = store_rwgt_info" >> ./Cards/run_card.dat 
    
}

make_gridpack () {
	mainpath=`pwd`
	MGSOURCE=/nfs/fanae/MadGraph.3.3.2/
	CARDSDIR=$mainpath/$carddir

	# 0. Few checks to ensure we have everything available
	if [ ! -d $CARDSDIR ]; then
	echo $CARDSDIR " does not exist!"
	if [ "${BASH_SOURCE[0]}" != "${0}" ]; then return 1; else exit 1; fi
	fi

	if [ ! -e $CARDSDIR/${name}_proc_card.dat ]; then
	echo $CARDSDIR/${name}_proc_card.dat " does not exist!"
	if [ "${BASH_SOURCE[0]}" != "${0}" ]; then return 1; else exit 1; fi
	fi

	if [ ! -e $CARDSDIR/${name}_madspin_card.dat ]; then
	echo $CARDSDIR/${name}_madspin_card.dat " does not exist!"
	if [ "${BASH_SOURCE[0]}" != "${0}" ]; then return 1; else exit 1; fi
	fi

	if [ ! -e $CARDSDIR/${name}_run_card.dat ]; then
	echo $CARDSDIR/${name}_run_card.dat " does not exist!"
	if [ "${BASH_SOURCE[0]}" != "${0}" ]; then return 1; else exit 1; fi
	fi 

	# 1. Make a temporal workspace
	tmpdir=${name}_workspace
	mkdir -p $tmpdir
	cd ${tmpdir}


	# 2. Prepare utilities
	#   2.1 LHAPDF
	LHAPDFCONFIG=`echo "$MGSOURCE/bin/lhapdf-config"`
	LHAPDFINCLUDES=`$LHAPDFCONFIG --incdir`
	LHAPDFLIBS=`$LHAPDFCONFIG --libdir`
	export LHAPDF_DATA_PATH=`$LHAPDFCONFIG --datadir`  

	#   2.2 Config script
	echo "set auto_update 0" > mgconfigscript
	echo "set automatic_html_opening False" >> mgconfigscript
	echo "set auto_convert_model True" >> mgconfigscript
	echo "set lhapdf_py3 $LHAPDFCONFIG" >> mgconfigscript
	echo "set run_mode 2" >> mgconfigscript
	echo "save options" >> mgconfigscript

	# 3. Generate events
	#   3.1 Setup environment and compile card
	source $MGSOURCE/configure.sh
	mg5_aMC mgconfigscript
	
	#   3.2. Compile the folder with the process card
	cp $CARDSDIR/* .
	mg5_aMC ${name}_proc_card.dat
	
	#   3.3. Copy the cards into the process folder
	cd $name
	cp ../${name}_madspin_card.dat Cards/madspin_card.dat
	cp ../${name}_run_card.dat Cards/run_card.dat
	cp ../${name}_param_card.dat Cards/param_card.dat
	
	#   3.4. Few more configurations 
	echo "shower=OFF" > makegrid.dat
	echo "reweight=OFF" >> makegrid.dat
	echo "done" >> makegrid.dat
	echo "done" >> makegrid.dat
	prepare_run_card $name $CARDSDIR $mainpath

	
	#   3.5. Launch the generation
	cat makegrid.dat | ./bin/generate_events -n pilotrun
	echo "finished pilot run"
	
	echo "mg5_path = $MGSOURCE/MG5_aMC" >> ./Cards/amcatnlo_configuration.txt
	echo "cluster_temp_path = None" >> ./Cards/amcatnlo_configuration.txt
	
	# 4. Store output
	cd ../
	mkdir gridpack
	mv $name gridpack/process
	cd gridpack
	cp $mainpath/utils/runcmsgrid.sh .
	cp $mainpath/utils/merge.pl .
	
	# 5. Modify the output a bit
	pdfSysArgs=$(python3 ${maindir}/utils/getMG5_aMC_PDFInputs.py -f systematics -c run3 --is5FlavorScheme)
    sed -i s/PDF_SETS_REPLACE/${pdfSysArgs}/g runcmsgrid.sh
    
    # 6. Clean the gridpack
    ${maindir}/utils/cleangridmore.sh
	
}

make_tarball () {
    echo "Creating tarball"
    cd $maindir/$tmpdir/gridpack


	XZ_OPT="--lzma2=preset=9,dict=512MiB"

    mkdir InputCards
    cp $CARDSDIR/${name}*.* InputCards
    
    ### include merge.pl script for LO event merging 
    if [ -e merge.pl ]; then
        EXTRA_TAR_ARGS+="merge.pl "
    fi
    XZ_OPT="$XZ_OPT" tar -cJpf ${maindir}/${name}_mg33x_tarball.tar.xz process runcmsgrid.sh gridpack_generation*.log InputCards $EXTRA_TAR_ARGS

    echo "Gridpack created successfully at ${maindir}/${name}_mg33x_tarball.tar.xz"
    echo "End of job"

    if [ "${BASH_SOURCE[0]}" != "${0}" ]; then return 0; else exit 0; fi
}

make_gridpack

make_tarball
