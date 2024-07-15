#!/bin/bash

# ------------------ Configuration ----------------------------------------

db="UniProt"
basepath="/faststorage/project/EcoGenetics/databases"
dbpath="UniProt"
address="http://ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/$(curl -vs ftp.ebi.ac.uk/pub/databases/uniprot/current_release/knowledgebase/reference_proteomes/ 2>&1 | awk '{if ($9 ~ /tar.gz/) {print $9}}')"

# ------------------ Functions --------------------------------------------

update_versionlist() {
	[ -e "$1"/dbversions.tsv ] || echo -e "database\tlast_updated" > "$1"/dbversions.tsv

	versions="$(awk \
		-v db="$2" \
		-v date="$(date +%d-%m-%Y)" \
		'BEGIN{FS = OFS = "\t"}
		{
		if ($1 == db)
			{
			$2 = date
			add = "n"
			}
		print $0
		}
		END{
		if (add == "n")
			{exit}
		print db, date
		}' \
		"$1"/dbversions.tsv)"

	echo -n "$versions" > "$1"/dbversions.tsv
}

# ------------------ Main -------------------------------------------------

command -v diamond > /dev/null 2>&1 || { echo 1>&2 "DIAMOND sequence aligner need to be available in current environment..."; exit 4; }

[ -d "$basepath" ] || (echo 1>&2 "$basepath does not seem to exist" && exit 1)

cd "$basepath" || { echo 1>&2 "Something went wrong..."; exit 2; }

[ -d "$dbpath" ] && rm -rf "$dbpath"

mkdir -p "$dbpath"

cd "$dbpath" || { echo 1>&2 "Something went wrong..."; exit 3; }

echo "Downloading $db..." \
&&
curl \
	-L \
	"$address" \
| tar -xzf - -C .\
&& \
echo "$db available in $basepath/$dbpath"

update_versionlist "$basepath" "$db"

echo "Concatenating protein sequence files..." \
&& \
cat \
	"$(find . -mindepth 3 \
	| grep "fasta.gz" \
	| grep -v 'DNA' \
	| grep -v 'additional' \
	| xargs)" \
	> reference_proteomes.fasta.gz \
&& \
echo "reference_proteomes.fasta.gz complete.."

echo "Creating taxon ID map..." \
&& \
cat \
	./*/*/*.idmapping \
| awk \
	'BEGIN{
	FS = OFS = "\t"
	print "accession", "accession.version", "taxid", "gi"
	}
	{
	if ($2 == "NCBI_TaxID")
		{print $1, $1, $3, "0"}
	}' \
	> reference_proteomes.taxidmap \
&& \
echo "reference_proteomes.taxidmap complete..."

echo "Making DIAMOND database file..." \
&& \
diamond makedb \
	--threads 2 \
	--in reference_proteomes.fasta.gz \
	--taxonmap reference_proteomes.taxidmap \
	--taxonnodes ../NCBI_Taxdump/nodes.dmp \
	-d reference_proteomes.dmnd \
&& \
echo "reference_proteomes.dmnd complete..."

exit 0