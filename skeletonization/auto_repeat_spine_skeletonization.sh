#!/bin/bash

for target_pc in 1800 1100 1300 2100 2000 8100 4900 8200 5000 7800 8300 4800 17500 1802 400 402
do
	for start_num in 1 2001 4001 6001 8001 10001 12001 14001 16001 18001 20001 22001 24001
        do
            end_num=$((start_num+1999))
            echo "from $start_num to $end_num of target pc $target_pc"
            matlab -nojvm -nodisplay -nosplash -r "cd /data/research/iys0819/cell_morphology_pipeline/code/; start_num = $start_num; end_num = $end_num; target_pc = $target_pc; auto_repeat_spine_skel(target_pc, start_num, end_num); exit;"
        done
done

# to avoid memory overflow, spines are divided into batches and the process recurred on the batches.