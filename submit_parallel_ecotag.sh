#!/bin/bash
#CREDIT: CHRISTOPH HAHN
fasta=/home/524274/stanford/Cobble_final/swarm/cobble2012_SWARM13_seeds.fasta
seqs_per_file=300
files_per_dir=100
EMBL_DB=/home/524274/applications/db_obitools/taxo_Nov2017/new_taxo_Nov2017
COI_FASTA=/home/524274/applications/db_obitools/db_coi.v05.cobble2012.fasta
threads_per_job=28
basedir=$(pwd)
partition_script=/home/524274/applications/ectools/partition.py


###########

echo -e "\nsplitting up files\n"
#cat $fasta | sed 's/ .*//g' > $genome.fasta
python $partition_script $seqs_per_file $files_per_dir $fasta

count=$(ls -1 | grep -E "^[0-9]{4}" |wc -l)
for i in $(seq $count -1 1)
do
	current=$(printf "%04d" $i)
	echo -e "processing directory $current\n"
	cd $current
	
	for p in $(ls -1 | grep -E "p[0-9]{4}$" | sort -nr)
	do
			
		echo -e "#!/bin/bash
#SBATCH -J b-$current-$p-$prefix
#SBATCH -N 1
#SBATCH --ntasks-per-node $threads_per_job
#SBATCH -o job-%j.out
#SBATCH -e job-%j.out
#SBATCH -p compute

#LOAD MODULE
module load obitools/1.2.9
 
#
date
cd $basedir/$current

echo -e \"\\\nNumber of scaffolds to process:\\\t\$(cat $basedir/$current/${p} | grep \">\" | wc -l)\"
echo -e \"\\\nTotal length of scaffolds:\\\t\$(cat $basedir/$current/${p} | grep \">\" -v | perl -ne 'chomp; print \"\$_\"' | wc -m)\\\n\"


ecotag -d $EMBL_DB -R $COI_FASTA --sort=count -r ${p} > ${p}.ecotag.fasta



echo -e \"\\\nDONE\\\n\"
date" > run_blastn_${p}.slurm.sh
       		sbatch run_blastn_${p}.slurm.sh
	done
	cd ..
done

