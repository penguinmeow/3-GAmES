#!/bin/bash




command -v singularity >/dev/null 2>&1 || { echo >&2 "3' GAmES requires singularity version > 3.0, please load this and try again."; exit 1; }




### reading in the variables passed in the command line... 

while getopts 'a: i: o: g: t: e: m: c: p: s:' OPTION; do
	  case "$OPTION" in
		      a)
			      avalue="$OPTARG"
			  echo "the adapter trimmed has the sequence $OPTARG"
				          ;;
	
					      i)
						      ivalue="$OPTARG"
						        echo "the input directory containing QuantSeq data is $OPTARG"
							          ;;
										
							o) 
								ovalue="$OPTARG"
								echo "the output directory is $OPTARG"
									;;

							
							 g) 
								 genome="$OPTARG"
								 echo "the genome is specified in $OPTARG"
								 ;;

							t) 
								threshold="$OPTARG"
								echo "the threshold to consider priming sites is $OPTARG"
								;;
							e)
								ensembldir="$OPTARG"
								echo "the ensembl directory specified is $OPTARG"
								;;
							m)
								RNAseqMode="$OPTARG"
								echo "the rnaseq mode is $OPTARG"
								;;
							c)
								Condition="$OPTARG"
								echo "the condition is $OPTARG"
								;;
							p)
								PIPELINE="$OPTARG"
								echo "the pipeline is here $OPTARG"
								;;
							 s)
								STOP="$OPTARG"
								echo "Stopping after running $OPTARG"
								;;


					  			  ?)
										 echo "script usage: $(basename $0) [-a adapter] [-i input directory] [-o output directory] [-g genome file] [-t threshold for priming sites] [-e ensemblDir] [-m mode rnadeq p/s/S] [-c condition] [-p path 3GAmES folder] [-s part of pipeline to stop at]" >&2
														        exit 1
															      ;;
															        esac
															done
															shift "$(($OPTIND -1))"




if [ "x" == "x$avalue" ]; then
	  echo "-a [adapter] is required"
	    exit
 fi



 if [ "x" == "x$ivalue" ]; then
	echo "-i [input directory] is required"
	exit
fi



 if [ "x" == "x$ovalue" ]; then
	         echo "-o [output directory] is required"
		         exit
fi
		     

 if [ "x" == "x$genome" ]; then
	 echo "please provide -g [genome] in fasta format"
	exit
fi



 if [ "x" == "x$threshold" ]; then
	          echo "please provide -t [threshold for priming site identification]"
		          exit
		  fi




if [ "x" == "x$ensembldir" ]; then
	              echo "please provide -u [path to folder with ENSEMBL  annotations]"
	exit
fi   


if [ "x" == "x$RNAseqMode" ]; then
	   echo "please provide -m [RNAseq counting mode]"
	exit
fi


if [ "x" == "x$Condition" ]; then
	           echo "please provide -c "
		           exit
fi


if [ "x" == "x$STOP" ]; then
	                   echo "please provide -s "
			                              exit
					      fi



##### defining required directories

QUANT_ALIGN=$ovalue/polyAmapping_allTimepoints
QUANT_MAP=$ovalue/polyAmapping_allTimepoints/n_100_global_a0/
QUANT_PASPLOTS=$ovalue/PASplot
QUANT_INTERGENIC=$ovalue/intergenicPeaks

mkdir -p "$QUANT_ALIGN"
mkdir -p "$QUANT_MAP"
mkdir -p "$QUANT_PASPLOTS"
mkdir -p "$QUANT_INTERGENIC"
mkdir -p $ovalue/ExtendingINtergenicRegions
mkdir -p $ovalue/coverage
mkdir -p $ovalue/final90percent


### create a log file... 

touch "$ovalue"/"$Condition".txt
date >"$ovalue"/"$Condition".txt

#### creating some pre-requisite files


	### creatig a genome size file, required for further steps....


	singularity exec "$PIPELINE"/bin/dependencies_latest.sif  /usr/bin/samtools-1.9/samtools  faidx "$genome" -o  "$QUANT_MAP"/"$genome".fai 
	cut -f1,2 "$genome".fai > "$QUANT_MAP"/sizes.genome


printf "\n" >> "$ovalue"/"$Condition".txt 
echo "#######################################################################"  >> "$ovalue"/"$Condition".txt
echo "Checking for thre presence of required input file formats and files..." >> "$ovalue"/"$Condition".txt
echo "#######################################################################"  >> "$ovalue"/"$Condition".txt
printf "\n" >> "$ovalue"/"$Condition".txt



####### checking the input files ...  this should consist if two directories

	### quantseq - containing all the zipped files of the quantSeq data
	### rnaseq - containing all the rnaseq data for the condition, mapeed and indexed. 

##### checking if these directories exist... 

if [ -d "$ivalue" ]; then
	          ### Take action if $DIR exists ###
	echo "input directory exists, proceeding to check if folders for quantseq and RNAseq exist." >> "$ovalue"/"$Condition".txt
			          else          
	###  Control will jump here if $DIR does NOT exists ###
	echo "Error: "$ivalue" not found. Can not continue, required input folder is missing :(." >> "$ovalue"/"$Condition".txt
exit 1
	fi




if [ -d "$ivalue"/quantseq ]; then
	  ### Take action if $DIR exists ###
	    echo "quantseq directory exists, proceeding to check if folder for RNAseq exists." >> "$ovalue"/"$Condition".txt
    else
	      ###  Control will jump here if $DIR does NOT exists ###
	        echo "Error: "$ivalue"/quantseq not found. Can not continue, required input folder is missing :(." >> "$ovalue"/"$Condition".txt
		  exit 1
	  fi


if [ -d "$ivalue"/rnaseq ]; then
	echo "rnaseq directory exists." >> "$ovalue"/"$Condition".txt
		else
	echo ""$ivalue"/rnaseq not found. Running pipeline without intergenic end extension" >> "$ovalue"/"$Condition".txt
		
	fi


echo "quantseq and rnaseq input directories exist!" >> "$ovalue"/"$Condition".txt
printf "\n" >> "$ovalue"/"$Condition".txt

######################## check for the presence of fastq files 


if ls "$ivalue"/quantseq/*.{gz,fastq,fq} 2> /dev/null | grep . > /dev/null; then
	   echo "input exists" >> "$ovalue"/"$Condition".txt
   else
	   echo "Error: there are no quantseq input files. Please check  "$ivalue"/quantseq/" >> "$ovalue"/"$Condition".txt
   fi


###################### check for the presence of bam files 


	#### if no bam or bai files, run without intergenic end identification...

if ls "$ivalue"/rnaseq/*.bam 2> /dev/null | grep . > /dev/null; then
	           echo "bam files exist" >> "$ovalue"/"$Condition".txt
		  
		      else
			   echo " Seems like there are no bam files, running 3'GAmES without intergnic end identification " >> "$ovalue"/"$Condition".txt
		 fi
		 
		 
		 
		 

if ls "$ivalue"/rnaseq/*.bai 2> /dev/null | grep . > /dev/null; then
	                   echo "bam indices exist" >> "$ovalue"/"$Condition".txt
			              else
		echo " Seems like there are no bam files, running 3'GAmES without intergnic end identification " >> "$ovalue"/"$Condition".txt  
	fi

echo "Input data exists! Last checks in progress...."  >> "$ovalue"/"$Condition".txt
echo "#######################################################################"  >> "$ovalue"/"$Condition".txt
printf "\n" >> "$ovalue"/"$Condition".txt

echo "#######################################################################"  >> "$ovalue"/"$Condition".txt
echo "Checking if the required annotations from ENSEMBL and refSeq exist" >> "$ovalue"/"$Condition".txt
echo "#######################################################################"  >> "$ovalue"/"$Condition".txt




if [ -d "$ensembldir" ]; then
	### Take action if $DIR exists ###
	echo "The directory for ENSEMBL annotations exists." >> "$ovalue"/"$Condition".txt
		else
			
	echo "Error: please check if "$ensembldir" exists :(." >> "$ovalue"/"$Condition".txt
	exit 1
	fi


printf "\n" >> "$ovalue"/"$Condition".txt


if ls "$ensembldir"/refSeq_mrna_utrsPresent.bed 2> /dev/null | grep . > /dev/null; then
	    echo "the required refSeq annotation exists... " >> "$ovalue"/"$Condition".txt
	


	else
		echo "Error: the required refSeq annotation does not exist Please check  "$ensembldir" ">> "$ovalue"/"$Condition".txt
	exit 1
	fi


if ls "$ensembldir"/proteinCoding_annotatedUTRs.bed 2> /dev/null | grep . > /dev/null; then
	            echo "the ensembl annotation proteinCoding_annotatedUTRs.bed exists. " >> "$ovalue"/"$Condition".txt
		                
		            else
				                    echo "Error: the required annotation proteinCoding_annotatedUTRs.bed does not exist Please check  "$ensembldir" ">> "$ovalue"/"$Condition".txt
						            exit 1  
							            fi



if ls "$ensembldir"/exonInfo_proteinCodingGenes.bed 2> /dev/null | grep . > /dev/null; then
	echo "the ensembl annotation exonInfo_proteinCodingGenes.bed exists. " >> "$ovalue"/"$Condition".txt
	else
																                                                        echo "Error: the required annotation exonInfo_proteinCodingGenes.bed does not exist Please check  "$ensembldir" ">> "$ovalue"/"$Condition".txt
exit 1  
																							fi


if ls "$ensembldir"/intronInfo_proteinCodingGenes.bed 2> /dev/null | grep . > /dev/null; then
	        echo "the ensembl annotation intronInfo_proteinCodingGenes.bed exists. " >> "$ovalue"/"$Condition".txt
		        else
				                                                                                                                                                                     echo "Error: the required annotation intronInfo_proteinCodingGenes.bed does not exist Please check  "$ensembldir" ">> "$ovalue"/"$Condition".txt
																								exit 1  
	fi  


	
if ls "$PIPELINE"/bin/dependencies_latest.sif 2> /dev/null | grep . > /dev/null; then
	                echo "Dependency container exists" >> "$ovalue"/"$Condition".txt
			                        else
							                                                                                                                                                     echo "Please run  getDependencies.sh" >> "$ovalue"/"$Condition".txt
																								exit 1  
																							fi  


if ls "$PIPELINE"/bin/slamdunk_v0.3.4.sif 2> /dev/null | grep . > /dev/null; then
	echo "SLAMdunk container exists" >> "$ovalue"/"$Condition".txt
	
	else
		echo "Please run  getDependencies.sh" >> "$ovalue"/"$Condition".txt
	exit 1
	fi





printf "\n" >> "$ovalue"/"$Condition".txt

echo "#######################################################################"  >> "$ovalue"/"$Condition".txt
echo "Starting 3'GAmES...." >> "$ovalue"/"$Condition".txt
echo "#######################################################################"  >> "$ovalue"/"$Condition".txt


ls "$ivalue"/quantseq/*.{gz,fastq,fq} | perl -pe "s#$ivalue/quantseq/##" > $QUANT_ALIGN/sampleInfo.txt


INPUT="$ivalue"/quantseq/

PARAMETER="$QUANT_ALIGN/sampleInfo.txt"

#set dirs

OUTDIR=$QUANT_ALIGN
LOG=$QUANT_ALIGN/logs/
mkdir -p $LOG


#init files
touch "$OUTDIR"/logFile.txt ## initialise a log file
touch "$OUTDIR"/readStats.txt ## initialise a file to store your read stats at different processing steps
touch "$OUTDIR"/processingSteps.txt ### just another file to list the processing steps 
touch "$LOG"/stderr_"$index".txt
touch "$LOG"/stdo_"$index".txt

date >"$OUTDIR"/logFile.txt
date >>"$LOG"/stderr_"$index".txt
date >>"$LOG"/stdo_"$index".txt

#################
echo "Starting pre-processing...." >> "$ovalue"/"$Condition".txt
#################



while read index; do
	
	
	
	
	echo "		processing $index ............" >> "$ovalue"/"$Condition".txt
  
	############################################################
	### trimming adapter and adding the relavant information. 
	############################################################

	
	singularity exec "$PIPELINE"/bin/dependencies_latest.sif  cutadapt -a $avalue -o "$OUTDIR"/"$index"_trimmed.fastq  --trim-n $INPUT/"$index" 2>"$LOG"/stderr_"$index".txt 1>>"$LOG"/stdo_"$index".txt
  	
	if [ $? -eq 0 ]
	then
		      echo "                  adapters trimming finished" >> "$ovalue"/"$Condition".txt
	    else
		        echo "			adapter trimming failed for "$index" " >> "$ovalue"/"$Condition".txt
		fi

	adapterTrimming=$(cat  "$OUTDIR"/"$index"_trimmed.fastq | echo $((`wc -l`/4)))
 	echo the number of reads after adapter trimming is "$adapterTrimming" >>"$LOG"/stdo_"$index".txt
	
	#### just adding an N to empty lines.... 
	
	sed 's/^$/N/' "$OUTDIR"/"$index"_trimmed.fastq > "$OUTDIR"/"$index"_trimmed_emptyRemoved.fastq

	
	#####################################################################
	############# trimming 5' end 
	#####################################################################

	echo "fastx_trimmer to remove 12 nts from the 5 end of the reads" >>"$LOG"/stdo_"$index".txt  

	
	singularity exec "$PIPELINE"/bin/dependencies_latest.sif fastx_trimmer -Q33 -f 13 -m 1 -i "$OUTDIR"/"$index"_trimmed_emptyRemoved.fastq   > "$OUTDIR"/"$index"_5primetrimmed_trimmed.fastq 2>"$LOG"/stderr_"$index".txt 
	
	
	       if [ $? -eq 0 ]
		               then
				         echo "                  5' nucleotides trimmed" >> "$ovalue"/"$Condition".txt
			else
				echo "                  5' trimming failed for "$index" " >> "$ovalue"/"$Condition".txt
				 exit 1  
		fi




	
	###################################################################
	#### removing A's from the 3' end
	###################################################################

	
	egrep -A2 -B1 'AAAAA$' "$OUTDIR"/"$index"_5primetrimmed_trimmed.fastq  | sed '/^--$/d' > "$OUTDIR"/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads.fastq  2>"$LOG"/stderr_"$index".txt
	polyAreads=$(cat "$OUTDIR"/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads.fastq | echo $((`wc -l`/4)))
	echo readd withs polyA "$polyAreads"  >>"$LOG"/stdo_"$index".txt
	echo remove the polyAs at the end of polyA reads >>"$LOG"/stdo_"$index".txt



	#cut super long polyA to avoid internal polyA cutting of 5 or more As
	
	 singularity exec "$PIPELINE"/bin/dependencies_latest.sif cutadapt --no-indels -m 18 -e 0 -a "A{1000}"  -o "$OUTDIR"/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved.fastq  "$OUTDIR"/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads.fastq 1>>"$LOG"/stdo_"$index".txt 2>"$LOG"/stderr_"$index".txt
	
	
	                if [ $? -eq 0 ]
				 then
					 echo "                  poly(A) reads processed" >> "$ovalue"/"$Condition".txt
						else   
							echo "                  poly(A) read processing failed "$index" " >> "$ovalue"/"$Condition".txt
							 exit 1  
				fi      
																								                   
	
	
	 finalReads=$(cat "$OUTDIR"/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved.fastq | echo $((`wc -l`/4)))
	
	 echo final reads after size filtering "$finalReads"  >>"$LOG"/stdo_"$index".txt
	
	  
	


	################
	# write stats
	#################

	touch "$LOG"/preProcessingNumbers_"$index".txt


	echo adapterTrimmed:"$adapterTrimming" >>"$LOG"/preProcessingNumbers_"$index".txt
	echo polyAcontaining:"$polyAreads" >>"$LOG"/preProcessingNumbers_"$index".txt
	echo finalFile:"$finalReads" >>"$LOG"/preProcessingNumbers_"$index".txt
	echo the pre processing before mapping has been completed.  >>"$LOG"/stdo_"$index".txt


	#################
	# getting the read length distribution 
	#################

	awk 'NR%4 == 2 {lengths[length($0)]++} END {for (l in lengths) {print l, lengths[l]}}' "$OUTDIR"/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved.fastq >"$OUTDIR"/"$index"_lengthDistribution.txt
	

	

	###### mapping the data 	
	
		############### download the SLAMdunk singularity module...
	
	singularity exec "$PIPELINE"/bin/slamdunk_v0.3.4.sif slamdunk map -r $genome -o $QUANT_MAP/ -n 100 -5 0 -a 0 -t 1 -e "$QUANT_ALIGN"/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved.fastq  
		
	                        if [ $? -eq 0 ]
					        then
						echo "SLAMdunk mapping complete" >> "$ovalue"/"$Condition".txt
						else   
						echo "SLAMdunk mapping failed " >> "$ovalue"/"$Condition".txt
						 exit 1  
 fi      
																																			                                             


	singularity exec "$PIPELINE"/bin/slamdunk_v0.3.4.sif slamdunk filter -o $QUANT_MAP -mq 0 -mi 0.95 -t 1  $QUANT_MAP/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved_slamdunk_mapped.bam         


	
		  if [ $? -eq 0 ]
			        then
				echo "SLAMdunk filtering complete" >> "$ovalue"/"$Condition".txt
				else
					echo "SLAMdunk mapping failed " >> "$ovalue"/"$Condition".txt
					 exit 1  
fi      
			




	 singularity exec "$PIPELINE"/bin/dependencies_latest.sif  bedtools bamtobed -i $QUANT_MAP/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved_slamdunk_mapped_filtered.bam  > $QUANT_MAP/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved_slamdunk_mapped.bam_bamTobed.bed 
	
		if [ $? -eq 0 ]
		               then
				         echo ""
			else
				echo " ERR: bamtobed failed">> "$ovalue"/"$Condition".txt
				 exit 1  
		fi



		 awk -vFS="\t" '$6 == "-"' $QUANT_MAP/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved_slamdunk_mapped.bam_bamTobed.bed > $QUANT_MAP/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved_slamdunk_mapped.bam_bamTobed_minusStrand.bed
		  
			  awk -vFS="\t" '$6 == "+"' $QUANT_MAP/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved_slamdunk_mapped.bam_bamTobed.bed > $QUANT_MAP/"$index"_5primetrimmed_trimmed_sizefiltered_polyAreads_polyAremoved_slamdunk_mapped.bam_bamTobed_plusStrand.bed

	echo "Pre-processing for "$index" completed" >> "$ovalue"/"$Condition".txt


  done <"$QUANT_ALIGN/sampleInfo.txt"



  ###### putting a stop sign here...

       if [ $STOP ==  "preprocess" ]
	             then
			echo "Pre-processing completed" >> "$ovalue"/"$Condition".txt
			exit 1 
	else
		echo "proceeding with priming site identification." >> "$ovalue"/"$Condition".txt
	fi              
																										                           
  
 ########################## Once this is done. I need to find the priming site ##################################

printf "\n" >> "$ovalue"/"$Condition".txt
 echo "#######################################################################"  >> "$ovalue"/"$Condition".txt
 echo "Identifying priming sites..." >> "$ovalue"/"$Condition".txt
 echo "#######################################################################"  >> "$ovalue"/"$Condition".txt


#################### identification of priming sites... 



	cat $QUANT_MAP/*_bamTobed_minusStrand.bed | awk -vFS="\t" '{print $1,$2}'  | sort | uniq -c | perl -pe 's#^\s+##'  > $QUANT_MAP/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique.bed

	cat $QUANT_MAP/*_bamTobed_plusStrand.bed | awk  -vFS="\t" '{print $1,$3}' | sort | uniq -c | perl -pe 's#^\s+##' > $QUANT_MAP/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique.bed


	onPositive=$(wc -l  "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique.bed)
	onNegative=$(wc -l  "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique.bed)



	awk -vT=$threshold '{ if ($1 >=T) print  }' "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique.bed >"$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique_greaterThan"$threshold".bed

	awk -vT=$threshold '{ if ($1 >=T) print  }' "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique.bed >"$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique_greaterThan"$threshold".bed


	awk -vOFS="\t" '{print $2, $3-1, $3, $1}' $QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique_greaterThan"$threshold".bed" | sort -k1,1 -k2,2n  > "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique_greaterThan"$threshold".bed_sorted.bed_changedCoordinates.bed

	awk -vOFS="\t" '{print $2, $3, $3+1, $1}' $QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique_greaterThan"$threshold".bed" | sort -k1,1 -k2,2n  > "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique_greaterThan"$threshold".bed_sorted.bed_changedCoordinates.bed




 singularity exec "$PIPELINE"/bin/dependencies_latest.sif bedtools merge -d 0 -i "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique_greaterThan"$threshold".bed_sorted.bed_changedCoordinates.bed -c 4 -o count,collapse >   "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique_greaterThan"$threshold".bed_sorted_merged.bed

		if [ $? -eq 0 ]
		               then
				         echo ""
			else
				echo " ERR: bedtools merge failed">> "$ovalue"/"$Condition".txt
				 exit 1  
		fi


    singularity exec "$PIPELINE"/bin/dependencies_latest.sif  bedtools merge  -d 0  -i "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique_greaterThan"$threshold".bed_sorted.bed_changedCoordinates.bed -c 4 -o count,collapse > "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique_greaterThan"$threshold".bed_sorted_merged.bed 
 
 
		if [ $? -eq 0 ]
		               then
				         echo ""
			else
				echo " ERR: bedtools merge failed">> "$ovalue"/"$Condition".txt
				 exit 1  
		fi




		  ###### putting a stop sign here...

		  if [ $STOP ==  "primingsites" ]
			then
			echo "Priming sites identified..." >> "$ovalue"/"$Condition".txt
			exit 1  
		else            
			echo " "  >> "$ovalue"/"$Condition".txt
		fi
																			        
																			                                                            
																			       

 	


######################################
###3 getting the sequences +/- 60 nts around the priming sites... 
######################################



singularity exec "$PIPELINE"/bin/dependencies_latest.sif  Rscript  --vanilla $PIPELINE/scripts/overlappingPolyApeaks.R "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_plusStrand_countsUnique_greaterThan"$threshold".bed_sorted_merged.bed "$QUANT_MAP"/polyAreads_polyAremoved_pooled_slamdunk_mapped_filtered_bamTobed_minusStrand_countsUnique_greaterThan"$threshold".bed_sorted_merged.bed "$QUANT_MAP"/peaks_"$threshold"_120bps.bed "$QUANT_MAP"/sizes.genome

		if [ $? -eq 0 ]
		               then
				         echo ""
			else
				echo " ERR: the script overlappingPolyApeaks returned an error">> "$ovalue"/"$Condition".txt
				 exit 1  
		fi

	

singularity exec "$PIPELINE"/bin/dependencies_latest.sif  bedtools getfasta -s -fi $genome -bed "$QUANT_MAP"/peaks_"$threshold"_120bps.bed -fo "$QUANT_MAP"/peaks_"$threshold"_120bps.fa 2>"$LOG"/stderr_"$index".txt 

	if [ $? -eq 0 ]
		               then
				         echo ""
			else
				echo " ERR: bedtools getfasta failed">> "$ovalue"/"$Condition".txt
				 exit 1  
		fi

	

#### getting sequences in the 120 nucleotide window

rmd="$PIPELINE/scripts/sequencesForNucleotideProfile.R"

	singularity exec "$PIPELINE"/bin/dependencies_latest.sif  Rscript --vanilla -e "InPath='$QUANT_MAP';threshold="$threshold";source('$rmd')"

			if [ $? -eq 0 ]
		               then
				         echo ""
			else
				echo " ERR: the script sequencesForNucleotideProfile.R returned an error">> "$ovalue"/"$Condition".txt
				 exit 1  
		fi


#####################
#### creating nucleotie profile plots...


rmd="$PIPELINE/scripts/nucleotideProfiles_markdown.new.R"

 singularity exec "$PIPELINE"/bin/dependencies_latest.sif  Rscript --slave -e "PPath='$PIPELINE'; InPath='$QUANT_MAP'; OutPath='$QUANT_PASPLOTS'; ensemblDir='$ensembldir';source('$rmd')"

					if [ $? -eq 0 ]
		               then
				         echo ""
			else
				echo " ERR: the script nucleotideProfiles_markdown.new returned an error">> "$ovalue"/"$Condition".txt
				 exit 1  
		fi

	
	
 	printf "\n" >> "$ovalue"/"$Condition".txt
	echo "Nucleotide profiles to check for internal priming..." >> "$ovalue"/"$Condition".txt

#### Another stop sign here..
	    if [ $STOP ==  "internalpriming" ]
		then
		echo "Internal priming sites removed..." >> "$ovalue"/"$Condition".txt
		exit 1  
	else            
		echo " "  >> "$ovalue"/"$Condition".txt
	fi



############# #######
#### addin intergenic peak information 
######################

### removing old coverage files


echo "Finding intergenic ends... this will take some time....." >> "$ovalue"/"$Condition".txt

rm $ovalue/coverage/*



	#### checking if the directory exists...if RNAseq folder exists, check the bam and bai files... 

	
	
	if [ -d "$ivalue"/rnaseq/ ]; then
	 
		echo "using the RNAseq samples in the folder $ivalue/rnaseq/ "  

			if ls "$ivalue"/rnaseq/*.bam 2> /dev/null | grep . > /dev/null; then
				  echo "bam files exist" >> "$ovalue"/"$Condition".txt
			else
				echo "bam files of RNAseq are missing. Please check "$ivalue"/rnaseq/ " >> "$ovalue"/"$Condition".txt
				exit 1
			fi

			if ls "$ivalue"/rnaseq/*.bai 2> /dev/null | grep . > /dev/null; then
				echo "bam indices exist" >> "$ovalue"/"$Condition".txt
			
			else
					echo " bam files dont seem to be indexed, performing indexing " >> "$ovalue"/"$Condition".txt  
			
					cd "$ivalue"/rnaseq/
					for bamfile in *.bam
						do
							singularity exec "$PIPELINE"/bin/dependencies_latest.sif  /usr/bin/samtools-1.9/samtools index "$bamfile"  
						done
			fi
			
		rmd="$PIPELINE/scripts/getLongestUTR.R"

		singularity exec "$PIPELINE"/bin/dependencies_latest.sif  Rscript --slave -e "PPath='$PIPELINE'; InPath='$QUANT_MAP'; OutPath='$QUANT_INTERGENIC'; ensemblDir='$ensembldir';source('$rmd')"

			 if [ $? -eq 0 ]
			then
				echo ""
			else
				echo " ERR: the script getLongestUTR returned an error">> "$ovalue"/"$Condition".txt
				exit 1
			fi
																										               
		sort -k1,1 -k2,2n $QUANT_INTERGENIC/allExons_refSeq_ensembl.bed > $QUANT_INTERGENIC//allExons_refSeq_ensembl_sorted.bed

		  ### this is the bed file of the most distal 3' position per gene. 

		sort -k1,1 -k2,2n $QUANT_INTERGENIC/toExtend_longestEnsembl_refSeq_n100.bed > $QUANT_INTERGENIC/toExtend_longestEnsembl_refSeq_n100_sorted.bed

		 ##### we want to calculate the distance between the most distal 3' end per gene and the next annotation (ensembl), to prevent considering RNAseq singal coming from another annotation. 

		         singularity exec "$PIPELINE"/bin/dependencies_latest.sif  bedtools closest -d -s -io -iu -D a -a $QUANT_INTERGENIC/toExtend_longestEnsembl_refSeq_n100_sorted.bed -b $QUANT_INTERGENIC/allExons_refSeq_ensembl_sorted.bed > $QUANT_INTERGENIC/toExtend_longestEnsembl_refSeq_n100_sorted_distances.bed
			

			if [ $? -eq 0 ]
				    then
					echo ""
				    else
					echo " ERR: bedtools closest returned an error">> "$ovalue"/"$Condition".txt
				   exit 1  
			fi

			  ## adding intergenic peaks                                                                                                                                                   

			  source $PIPELINE/scripts/intergenicPeakId.sh

			
			if [ $? -eq 0 ]; then
						echo ""
				else
					echo " ERR: intergenicPeakId returned an error">> "$ovalue"/"$Condition".txt
				exit 1
			fi

	else
			
		  rmd="$PIPELINE/scripts/getLongestUTR.R"

	                singularity exec "$PIPELINE"/bin/dependencies_latest.sif  Rscript --slave -e "PPath='$PIPELINE'; InPath='$QUANT_MAP'; OutPath='$QUANT_INTERGENIC'; ensemblDir='$ensembldir';source('$rmd')"
	                              
		                         if [ $? -eq 0 ]
					       then
								echo ""
						else
							echo " ERR: the script getLongestUTR returned an error">> "$ovalue"/"$Condition".txt
						exit 1
					fi
  	sort -k1,1 -k2,2n $QUANT_INTERGENIC/allExons_refSeq_ensembl.bed > $QUANT_INTERGENIC//allExons_refSeq_ensembl_sorted.bed

                  ### this is the bed file of the most distal 3' position per gene. 
	sort -k1,1 -k2,2n $QUANT_INTERGENIC/toExtend_longestEnsembl_refSeq_n100.bed > $QUANT_INTERGENIC/toExtend_longestEnsembl_refSeq_n100_sorted.bed

			                 ##### we want to calculate the distance between the most distal 3' end per gene and the next annotation (ensembl), to prevent considering RNAseq singal coming from another annotation. 

				  singularity exec "$PIPELINE"/bin/dependencies_latest.sif  bedtools closest -d -s -io -iu -D a -a $QUANT_INTERGENIC/toExtend_longestEnsembl_refSeq_n100_sorted.bed -b $QUANT_INTERGENIC/allExons_refSeq_ensembl_sorted.bed > $QUANT_INTERGENIC/toExtend_longestEnsembl_refSeq_n100_sorted_distances.bed
						                        




		echo "the rnaseq directory does not exist. Running the analysis without intergenic end identification" >>  "$ovalue"/"$Condition".txt  
		singularity exec "$PIPELINE"/bin/dependencies_latest.sif Rscript  --slave -e "BOut='$ovalue';source('"$PIPELINE"/scripts/writePassingNonOverlappingEnds.R')"
		singularity exec "$PIPELINE"/bin/dependencies_latest.sif bedtools sort -i "$ovalue"/polyAmapping_allTimepoints/n_100_global_a0/nonOverlapping_total_passing.bed > "$ovalue"/polyAmapping_allTimepoints/n_100_global_a0/nonOverlapping_total_passing_sorted.bed
		singularity exec "$PIPELINE"/bin/dependencies_latest.sif bedtools closest -d -s -io   -a "$ovalue"/polyAmapping_allTimepoints/n_100_global_a0/nonOverlapping_total_passing_sorted.bed -b "$ovalue"/intergenicPeaks/toExtend_longestEnsembl_refSeq_n100_sorted_distances.bed | cat - > "$ovalue"/intergenicPeaks/intergenicPeaks_noRNAseq.bed


	fi




#### Another stop sign here..
            

	if [ $STOP ==  "intergenicends" ]
		    then 
			echo "Internal priming sites removed..." >> "$ovalue"/"$Condition".txt
			exit 1  
		else
			echo " "  >> "$ovalue"/"$Condition".txt
			fi

######################## final filtering steps

	rmd="$PIPELINE/scripts/assignToUTRs.R"
	singularity exec "$PIPELINE"/bin/dependencies_latest.sif Rscript --slave -e "BIn='$ivalue'; BOut='$ovalue'; ensemblDir='$ensembl';source('$rmd')"
	
	

if [ $? -eq 0 ]
		    then
				         echo ""
			else
				echo  " ERR: the script assignToUTRs returned an error" >> "$ovalue"/"$Condition".txt
				 exit 1  
		fi





	rmd="$PIPELINE/scripts/90PercentFiltering.R"

	singularity exec "$PIPELINE"/bin/dependencies_latest.sif Rscript --slave -e "BIn='$ivalue'; BOut='$ovalue'; ensemblDir='$ensembldir';source('$rmd')"
	
	if [ $? -eq 0 ]
		    then
				         echo ""
			else
				echo  " ERR: the script 90PercentFiltering returned an error" >> "$ovalue"/"$Condition".txt
				 exit 1  
		fi



	echo "Filtering out positions with low read counts.." >> "$ovalue"/"$Condition".txt


	singularity exec "$PIPELINE"/bin/dependencies_latest.sif  Rscript --vanilla -e "BIn='$ivalue'; BOut='$ovalue'; ensemblDir='$ensembldir'; source('$PIPELINE/scripts/mergingCounting.new.R')"

 echo "Cleaning up a bit....and then we're done!" >> "$ovalue"/"$Condition".txt
###### cleaning up a bit... 


##### pre-processing data...

mkdir -p $ovalue/pre-processingLogs
cp "$ovalue"/polyAmapping_allTimepoints/logs/*  $ovalue/pre-processingLogs/
rm -r "$ovalue"/polyAmapping_allTimepoints

##### coverage (redundant - not used anymore)
rm -r "$ovalue"/coverage
rm -r "$ovalue"/intergenicPeaks
rm -r "$ovalue"/ExtendingINtergenicRegions


#### final 3' end annotations
mkdir -p $ovalue/finalEnds
cp "$ovalue"/final90percent/ends_greater90percent_intergenic_n100.bed "$ovalue"/finalEnds/highConfidenceEnds.bed
cp "$ovalue"/final90percent/allAnnotations.bed "$ovalue"/finalEnds/countingWindows.bed
cp "$ovalue"/final90percent/countingWindows_transcriptionalOutput.bed "$ovalue"/finalEnds/countingWindows_transcriptionalOutput.bed
cp "$ovalue"/final90percent/onlyIntergenic_90percent_n100.bed "$ovalue"/finalEnds/highConfidenceIntergenicEnds.bed

rm -r "$ovalue"/final90percent

#### PAS plots
mkdir -p $ovalue/nucleotideProfiles
 cp "$ovalue"/PASplot/belowAboveThreshold.pdf  $ovalue/nucleotideProfiles
rm -r  "$ovalue"/PASplot/

echo "Finished cleaning up....."



