// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

process PICARD_COLLECTMULTIPLEMETRICS {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:options, publish_dir:getSoftwareName(task.process), publish_id:meta.id) }

    container (params.universalContainer? "${params.container}":"quay.io/biocontainers/picard:2.23.2--0")
    //container "https://depot.galaxyproject.org/singularity/picard:2.23.2--0"

    conda (params.conda ? "${params.conda_softwares.picard}" : null)

    input:
    tuple val(meta), path(bam)
    path fasta
    val options

    output:
    tuple val(meta), path("*_metrics"), optional:true, emit: metrics
    tuple val(meta), path("*.pdf"), optional:true, emit: pdf
    path "*.version.txt", emit: version

    script:
    def software  = getSoftwareName(task.process)
    def ioptions  = initOptions(options)
    def prefix    = ioptions.suffix ? "${meta.id}${ioptions.suffix}" : "${meta.id}"
    def avail_mem = 3
    if (!task.memory) {
        log.info '[Picard CollectMultipleMetrics] Available memory not known - defaulting to 3GB. Specify process memory requirements to change this.'
    } else {
        avail_mem = task.memory.giga
    }
    """
    picard \\
        -Xmx${avail_mem}g \\
        CollectMultipleMetrics \\
        $ioptions.args \\
        INPUT=$bam \\
        OUTPUT=${prefix}.CollectMultipleMetrics \\
        REFERENCE_SEQUENCE=$fasta

    echo \$(picard CollectMultipleMetrics --version 2>&1) | awk -F' ' '{print \$NF}' > ${software}.version.txt
    """
}
