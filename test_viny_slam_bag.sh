#!/bin/bash

source /opt/ros/kinetic/setup.bash
source /home/artem/slam_test/devel/setup.bash

if (( $# != 3 )); then
    echo "Usage: test_tiny_slam.sh [dataset] [ground truth] [iters]"
    exit 0
fi

if [ ! -f evaluate_ate.py ]; then
    wget https://svncvpr.in.tum.de/cvpr-ros-pkg/trunk/rgbd_benchmark/rgbd_benchmark_tools/src/rgbd_benchmark_tools/evaluate_ate.py
    chmod +x evaluate_ate.py
fi

if [ ! -f associate.py ]; then
    wget https://svncvpr.in.tum.de/cvpr-ros-pkg/trunk/rgbd_benchmark/rgbd_benchmark_tools/src/rgbd_benchmark_tools/associate.py
    chmod +x associate.py
fi

if [ ! -f evaluate_ate.py -o ! -f associate.py ]; then
    echo "Error: unable to find/download evaluate script"
    exit 0
fi

total_res=""
tmp_output_file=$(pwd)"/"$(basename "$1")"_output.txt"

for i in `seq 1 $3`; do
    if [ "$4" == "gmapping" ]; then
        roslaunch slam_fmwk gmapping_test_run.launch path:=$1 pose_output:=$tmp_output_file rate:=2
    else
        roslaunch slam_fmwk  viny_mit_run.launch path:=$1 pose_output:=$tmp_output_file rate:=1
    fi    
    min_res=10000.0
    offset=-10
    for j in `seq -10 10`; do
        res=$(./evaluate_ate.py --max_difference 1 --save "pose_shifted.txt" --offset "$j" $2 $tmp_output_file)
        if (( $(echo "$res<$min_res" | bc -l) )); then
            offset=$j
            min_res=$res
        else
            break
        fi
    done
    rm -f $tmp_output_file
    total_res=$total_res""$min_res"\n"
    echo $i": "$min_res" offset: "$offset
done

tmp_res=$(printf "$total_res")
err_mean=$(echo "$tmp_res" | awk '{ sum += $1 } END { if (NR > 0) print sum/NR }')
err_std=$(echo "$tmp_res" | awk '{ sum += $1; sumsq += $1*$1 } END { print sqrt(sumsq/NR - (sum/NR)*(sum/NR)) }')

echo "mean: "$err_mean
echo "std dev: "$err_std

echo -e $total_res"\nmean: "$err_mean"\nstd: "$err_std > $(basename "$1")"_result.txt"


