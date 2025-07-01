The 'databases' directory contains files of various downloaded databases.
These databases should be regularly updated. If you use a database please help make sure it is up to date.
OUTDATED To help track the age of any database placed in this directory update 'dbversions.tsv' file with update database name and date:
To help track of the age of any database placed in this directory the database folder should now include the date of download in the format 'MMYYYY'

The 'software' directory is to contain scripts relating to the function of the databases.

The 'scripts' directory contains scripts for downloading and updating databases easily

------------------------------------
########## DATABASE SETUP ##########
------------------------------------

### NCBI Taxdump Database ###
DATE="$(date '+%m%Y')"
mkdir NCBI_Taxdump_"$DATE"
curl -L ftp://ftp.ncbi.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz -o NCBI_Taxdump_"$DATE".tar.gz
tar -zxf NCBI_Taxdump_"$DATE".tar.gz -C NCBI_Taxdump_"$DATE"
rm NCBI_Taxdump_"$DATE".tar.gz

### NCBI Nucleotide BLAST Database ###
DATE="$(date '+%m%Y')"
mkdir NCBI_nt_"$DATE"
wget "ftp://ftp.ncbi.nlm.nih.gov/blast/db/v5/nt.???.tar.gz" -P NCBI_nt_"$DATE"/ && for file in NCBI_nt_"$DATE"/*.tar.gz; do tar -zxf $file -C NCBI_nt_"$DATE" && rm $file; done
wget "https://ftp.ncbi.nlm.nih.gov/blast/db/v5/taxdb.tar.gz" && tar -zxf taxdb.tar.gz -C NCBI_nt_"$DATE" && rm taxdb.tar.gz
# OPTIONAL. Compress and clean up
tar -cvzf NCBI_nt_"$DATE".tar.gz NCBI_nt_"$DATE"
rm -r NCBI_nt_"$DATE"

### UniProt Reference Proteomes Database ###
# Path to current taxdump directory
TAXDUMP=
DATE="$(date '+%m%Y')"
mkdir UniProt_"$DATE"
cd UniProt_"$DATE"
mkdir extract
curl -L ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes//$(curl -vs ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/ 2>&1 | awk '/tar.gz/ {print $9}') | tar -xzf - -C extract
# Create a single fasta file with all the fasta files from each subdirectory:
find extract -type f -name '*.fasta.gz' ! -name '*_DNA.fasta.gz' ! -name '*_additional.fasta.gz' -exec cat '{}' '+' > reference_proteomes.fasta.gz
# Create the accession-to-taxid map for all reference proteome sequences:
find extract -type f -name '*.idmapping.gz' -exec zcat {} + | awk 'BEGIN {OFS="\t"; print "accession", "accession.version", "taxid", "gi"} $2=="NCBI_TaxID" {print $1, $1, $3, 0}' > reference_proteomes.taxid_map
# Create the taxon aware diamond blast database using DIAMOND
diamond makedb -p 16 --in reference_proteomes.fasta.gz --taxonmap reference_proteomes.taxid_map --taxonnodes $TAXDUMP/nodes.dmp --taxonnames $TAXDUMP/names.dmp -d reference_proteomes.dmnd
# Clean up and compress
mv extract/{README,STATS} .
rm -r extract
# OPTIONAL
cd ..
tar -cvzf UniProt_"$DATE".tar.gz UniProt_"$DATE"
rm -r UniProt_"$DATE"

### BUSCO Database ###
DATE="$(date '+%m%Y')"
mkdir BUSCO_"$DATE"
cd BUSCO_"$DATE"
wget -r -nH https://busco-data.ezlab.org/v5/data/
# tar gunzip all folders that have been stored as tar.gz, in the same parent directories as where they were stored:
find v5/data -name "*.tar.gz" | while read -r TAR; do tar -C `dirname $TAR` -xzf $TAR; done
find v5/data -name "*.tar.gz" | while read -r TAR; do rm $TAR; done
mv v5/data/* ./
rm -r v5/
for i in lineages/*/refseq_db.faa.gz; do chmod g+w "$i"; done
for i in lineages/*; do chmod g+w "$i"; done
# OPTIONAL. Compress and clean up
tar -cvzf BUSCO_"$DATE".tar.gz BUSCO_"$DATE"
rm -r BUSCO_"$DATE"