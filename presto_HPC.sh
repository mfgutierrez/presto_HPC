#!/usr/bin/env bash
FilterSeq.py quality -s ${1}"_1.fastq" -q 20 --outname ${1}"_1" --log ${1}"_1.log"
FilterSeq.py quality -s ${1}"_2.fastq" -q 20 --outname ${1}"_2" --log ${1}"_2.log"
MaskPrimers.py score -s ${1}"_1_quality-pass.fastq" -p "Galaxy4-[IS_Mouse_R1_Primers.txt].fasta" \
	    --start 0 --mode cut --outname ${1}"-R1" --log ${1}"_MP1.log"
MaskPrimers.py score -s ${1}"_2_quality-pass.fastq" -p "Galaxy5-[IS_Mouse_R2_Primers.txt].fasta" \
	    --start 17 --barcode --mode cut --maxerror 0.5 --outname ${1}"-R2" --log ${1}"_MP2.log"
PairSeq.py -1 ${1}"-R1_primers-pass.fastq" -2 ${1}"-R2_primers-pass.fastq" \
	    --2f BARCODE --coord sra
BuildConsensus.py -s ${1}"-R1_primers-pass_pair-pass.fastq" --bf BARCODE --pf PRIMER \
	    --prcons 0.6 --maxerror 0.1 --maxgap 0.5 --outname ${1}"-R1" --log ${1}"_BC1.log"
BuildConsensus.py -s ${1}"-R2_primers-pass_pair-pass.fastq" --bf BARCODE \
	    --maxerror 0.1 --maxgap 0.5 --outname ${1}"-R2" --log ${1}"_BC2.log"
PairSeq.py -1 ${1}"-R1_consensus-pass.fastq" -2 ${1}"-R2_consensus-pass.fastq" \
	    --coord presto
AssemblePairs.py sequential -1 ${1}"-R2_consensus-pass_pair-pass.fastq" \
	    -2 ${1}"-R1_consensus-pass_pair-pass.fastq" -r "Galaxy7-[Immune_mouse_Ref.fasta].fasta" \
	        --coord presto --rc tail --scanrev --1f CONSCOUNT --2f CONSCOUNT PRCONS \
		    --aligner blastn --outname ${1}"-C" --log ${1}"_AP.log"

MaskPrimers.py align -s ${1}"-C_assemble-pass.fastq" \
	    -p 'Galaxy6-[IS_Mouse_C-Region.txt].fasta' --maxlen 100 --maxerror 0.3 \
	        --mode tag --revpr --skiprc --pf CREGION --outname ${1}"-C" --log ${1}"_MP3.log" 
ParseHeaders.py collapse -s ${1}"-C_primers-pass.fastq" -f CONSCOUNT --act min
CollapseSeq.py -s ${1}"-C_primers-pass_reheader.fastq" -n 20 --inner \
	    --uf CREGION --cf CONSCOUNT --act sum --outname ${1}"-C"
SplitSeq.py group -s ${1}"-C_collapse-unique.fastq" \
	    -f CONSCOUNT --num 2 --outname ${1}"-C"
ParseHeaders.py table -s ${1}"-C_atleast-2.fastq" -f ID CREGION CONSCOUNT DUPCOUNT
ParseLog.py -l ${1}"_FS1.log" ${1}"_FS2.log" -f ID QUALITY
ParseLog.py -l ${1}"_MP1.log" ${1}"_MP2.log" ${1}"_MP3.log" -f ID PRIMER BARCODE ERROR
ParseLog.py -l ${1}"_BC1.log" ${1}"_BC2.log" -f BARCODE SEQCOUNT CONSCOUNT PRCONS PRFREQ ERROR
ParseLog.py -l ${1}"_AP.log" -f ID REFID LENGTH OVERLAP GAP ERROR IDENTITY
