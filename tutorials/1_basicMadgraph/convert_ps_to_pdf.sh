inpath=$1

# First convert each one in pdf
for file in $(ls $inpath/P*/*ps); do
  ps2pdf $file $file.pdf
done

# Now unite them
pdfunite $inpath/P*/*pdf feynman_diagrams.pdf
