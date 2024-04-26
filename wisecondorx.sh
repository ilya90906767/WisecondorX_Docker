docker build -t wisecondorx:latest . 
WORKDIR="/home"


CONTAINER="wisecondorx:latest"
operation=$1 


if [ "$operation" = "convert" ]; then 

    bam_folder=$2
    output_folder=$3
    threads=$4

    mkdir -p "$output_folder"
         
    bam_files=($(find "$bam_folder" -type f -name "*.bam"))
    echo "Converting BAM files to NPZ using WisecondorX..."
    for bam_file in "${bam_files[@]}"; do
        output_file="${output_folder}/${bam_file%.bam}.npz"
        echo "Converting $bam_file to $output_file"
        echo "docker run \
         --rm -v ${bam_folder}:${bam_folder}:ro -v ${output_folder}:${output_folder}:ro $CONTAINER WisecondorX convert /${bam_file} /${output_file}"  >> WiseConvert.logs
        docker run \
         --rm -v ${bam_folder}:${bam_folder}:ro -v ${output_folder}:${output_folder}:ro $CONTAINER \
         WisecondorX convert /${bam_file} /${output_file} &
    done | xargs -P "$threads" -n 1

   wait
   echo "All BAM files converted to NPZ successfully!" >> WiseConvert.logs
  echo "Conversion complete."

elif [ "$operation" = "newref" ]; then 

    input_folder=$2
    output_file=$3
    threads=$4
    docker run --rm -v ${input_folder}:${input_folder} -v ${output_file}:${output_file} $CONTAINER \
    WisecondorX newref /${input_folder}/*.npz /${output_file} --cpus $threads
    echo "All NPZ files processed successfully using WisecondorX newref!"

elif [ "$operation" = "predict" ]; then 

    input_folder=$2
    reference=$3 
    output_folder=$4
    threads=$5
    
    npz_to_predict=($(find "$input_folder" -type f -name "*.npz"))
    echo "Predicting NPZ files using WisecondorX..."
    for npz_file in "${npz_to_predict[@]}"; do 
        output_id="${output_folder}/${npz_file%.npz}"
        echo "Predicting $output_id"
        echo "docker run --rm -v ${input_folder}:${input_folder} -v ${reference}:${reference} -v ${output_folder}:${output_folder} $CONTAINER WisecondorX predict /${npz_file} /${reference} /${output_folder} --plot --bed &" >> WisePredict.logs
        docker run --rm -v ${input_folder}:${input_folder} -v ${reference}:${reference} -v ${output_folder}:${output_folder} $CONTAINER \ 
        WisecondorX predict /${npz_file} /${reference} /${output_folder} --plot --bed &
    done | xargs -P "$threads" -n 1

    wait 
    echo "All NPZ files were predicted. You can check results in $output_folder"
    echo "Prediction complete"

else
  echo "Invalid operation. Please use 'convert' as the first argument."
fi

    # INPUT_BAM_DIR="$1"
    # THREADS=$2

    # if [ $# -ne 2]; then 
    #     echo "Usage: $0 [path_to_bam_files] [threads]"
    #     exit 1 
    # fi 

    # if [ ! -d "$INPUT_BAM_DIR" ]; then 
    #     echo "Directory does not exist: $INPUT_BAM_DIR"
    #     exit 1 
    # fi 

    # docker_run_function() {
    #     bamfile=$1
    #     echo "Processing BAM file: $bamfile"
    #     docker run --rm -v "$INPUT_BAM_DIR":/data "$CONTAINER" sh -c "samtools view -q 30 /data/$bamfile | python2 /home/karyo_RxRy_script.py --chr21"
    # }

    # export -f docker_run_function

    # rm -f results.txt 

    # find "$INPUT_BAM_DIR" -type f -name "*.bam" -print0 | xargs -O -n 1 -P $THREADS -I {} bash -c 'docker_run_function "{}" >> results.txt' _
