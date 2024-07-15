#!/bin/bash

# ------------------ Configuration ----------------------------------------

# Sources necessary environment
if [ "$USER" == "jepe" ]; then
	# shellcheck disable=1090
	source /home/"$USER"/.bashrc
	#shellcheck disable=1091
	source activate assembly
fi

basepath="/faststorage/project/EcoGenetics/databases"

dbpath="NCBI_BLAST_DB/nt"

[ -d "$basepath" ] || (echo "$basepath does not seem to exist" && exit 1)

cd "$basepath" || (echo "Something went wrong..." && exit 2)

[ -d "$dbpath" ] && rm -rf "$dbpath"

mkdir -p "$dbpath"

cd "$dbpath" || (echo "Something went wrong..." && exit 3)

update_blastdb.pl \
	--source ncbi \
	--num_threads 20 \
	--force_ftp \
	--passive \
	--decompress \
	nt

exit 0

wget "ftp://ftp.ncbi.nlm.nih.gov/blast/db/nt.*.tar.gz"

for i in */; do
	tar -xzf "$i" && rm "$i"
done

exit 0