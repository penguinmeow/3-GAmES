# 3'GAmES (3´-terminal Gene Annotation from mRNA 3´End Sequencing datasets)
3' GAmES is a pipeline to refine and extend mRNA 3' end annotations using 3' end sequencing datasets. 

## Installation 

### Clone from github

git clone https://github.com/poojabhat1690/3-GAmES.git

Please make sure the singularity version you have is > 3.0. 

	cd 3-GAmES/bin
	run the script "getDependencies.sh"
	In this step, we'll load singularity from HPCF, then pull singularity image: (1) dependencies_latest.sif ; (2) slamdunk_v0.3.4.sif


## Description
the main steps involved in the pipeline are outlined :
[The main steps of the pipeline are outlined here](primingSites/flowchart.pdf).
A description of the different steps outlined can be found in the wiki.

Input raw files include SLAM-Seq and RNA-seq data.
For example, the SLAM-seq data in our test dataset is Zebra fish 1 day post fertilization (Pharyngula period of embryo development, according to PMID: 8589427) embryo. Total RNA was isolated and librarby were prepared using QuantSeq Kit.
The RNA-seq data in test dataset are zebrafish embryos collected at 1-cell stage (Zygote period) then strand-specific libraries for 76 bp paired-end sequencing were prepared, sequenced with Illumina HiSeq 2000.


## Requirements
After cloning 3'GAmES and pulling the dependencies
1. Organize the input data: 3'GAmES requires an input folder that contains. 

		a. A folder named 'quantseq', which contains fastq files in formal *.fq, *.fastq or *.gz
		b. A folder named 'rnaseq' [optional], which contains mapped RNAseq files, and the corresponding indices. The data in this folder is needed for extending the analysis to identification of intergenic ends. 

The pipeline can be run without RNAseq data - in which case, please provide only a 'quantseq' in the input directory. In this mode, intergenic ends will not be identified.

	 
2. create ENSEMBL and refSeq annotation files (description provided below)

### Annotations required
To start, 3' GAmES requires  the dependencies  as singularity images and an annotation set from refSeq and ENSEMBL. 

5 different annotation files are required. Please retain the file names as below.

	1. refSeq_mrna_utrsPresent.bed - RefSeq 3' UTR annotations  
	2. proteinCoding_annotatedUTRs.bed - ENSEMBL 3' UTR annotations 
	3. exonInfo_proteinCodingGenes.bed - ENSEMBL exon annotations 
	4. intronInfo_proteinCodingGenes.bed - ENSEMBL intron annotations 
	5. transcriptStartsAndEnds_all.txt - ENSEMBL transcript annotation  	

All the annotations should be tab separated and should contain the following information (without column headers): chromosome, start, end, gene name, score, strand, transcript id.

Please also include the transcript biotype (protein coding, non-coding etc) as the 8th column of  transcriptStartsAndEnds_all.txt


All the above annotations can be obtained from the UCSC table browser:

	For example:
		
	for 3' UTR annotations from (refSeq) UCSC genome browser                                                                                                                                    
             1. Form UCSC table browser, select:
                a. clade = mammal 
                b. genome = mouse
                c. assembly = Dec. 2011 (GRCm38/mm10)
                d. group = genes and gene prediction
                e. track = refSeq genes
                f. table = refGene
              2. select bed format and 3' UTR. 

## Quick start -  Running 3'GAmES

The script required to run the whole pipeline is run_3GAmES.sh. You will find this in the 3GAmES/bin/

run_3GAmES.sh -a [adapter] -i [input directory] -o [output directory] -g [genome file] -t [threshold for priming sites]
-u [ucscDir] -e [ensemblDir] -m [mode rnaseq p/s/S] -c [condition] -p [path]
 
 
 	-a 3' Adapter sequences that has to be removed using cutadapt
 
 	-i Input directory containing two folders named - quantseq, rnaseq
                   quantseq: contains *.fastq, *.fq.gz, *fq  files. 
                   rnaseq: mapped, sorted and indexed bam files. 
 
 	-o Output directory
 
 	-t Threshold of the number of reads to define a priming site.
 	
	-e Ensembl directory containing the 5 annotation files described above. 
 
 	-m mode of counting for RNAseq coverage, derived from bedtools multicov (s: counting on the same strand, 
            p: paired end reads, S: counting on the opposite strand
 
 	-c condition of sample (example: timepoint or organism)
	
	-p path to the 3-GAmES folder

	-s step after which pipeline will stop [options: preprocessing, primingsites, intergenicends, all]


example: run_3GAmES.sh -a AGATCGGAAGAGCACACGTCTGAACTCCAGTCACNNNNNNATCTCGTATGCCGTCTTCTGCTTG -i xcondition_input/ -o xcondition_output/ -g danio_rerio/dr11/danRer11.fa -t 2  -e annotations_all/ -m p -c trialSample -p /scratch/3-GAmES -s all

## Output description
The final output and all intermediate files are organized in the following folders:

#### finalEnds:
 1. highConfidenceEnds.bed :  contains the high confidence mRNA 3' ends 
 2. countingWindows.bed :  250nt counting windows (overlapping counting windows merged), used to count quantseq reads.
 3. countingWindows_transcriptionalOutput.bed : genomic loci to filter multimappers using SLAMdunk. These include all counting windows + all 3' UTRs + all extended counting windows. 
 4. highConfidenceIntergenicEnds.bed: list of the intergenic counting windows created using presence of continuous RNAseq signal.

#### PASplots:
Contains nucleotide profiles for priming sites overlapping with annotations, sparated by presence or absence of the poly A signal (PAS) and separated by downstream genomic A content. 

## test data - Zebrafish 1 day post fertilization

 1. 3' end sequencing data (1dpf) can be downloaded from the GEO database (GSE146738).
 2. Optionally RNAseq data from the same stage can be downloaded (SRR372798, SRR372799) and mapped and indexed using standard tools (example : mapping using STAR and indexing using samtools). 
 3. Annotations required to run 3' GAmES are on the git (https://github.com/poojabhat1690/3-GAmES/tree/master/testdata/annotations/)

## Contact
Pooja Bhat (pooja.bhat@imba.oeaw.ac.at)        


