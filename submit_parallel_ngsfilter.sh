#!/bin/bash
#CREDIT: CHRISTOPH HAHN
fasta=/home/524274/stanford/Cobble_final/ngsfilter_demulti/Good_cobbleCOI.fasta
ngsfilter=/home/524274/stanford/Cobble_final/ngsfilter_cobble2012.txt
seqs_per_file=5000
files_per_dir=100
threads_per_job=28
basedir=$(pwd)
partition_script=home/524274/peter/applications/ectools/partition.py


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

ngsfilter -t $ngsfilter --fasta-output -u ${p}_unidentified_cobbleCOI.fasta ${p} --DEBUG > ${p}.filtered.fasta


echo -e \"\\\nDONE\\\n\"
date" > run_ngsfilter_${p}.slurm.sh
       		sbatch run_ngsfilter_${p}.slurm.sh
	done
	cd ..
done

