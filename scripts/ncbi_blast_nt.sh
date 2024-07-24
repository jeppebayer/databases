#!/bin/bash

# ------------------ Configuration ----------------------------------------

db="NCBI_BLAST_nt"
basepath="/faststorage/project/EcoGenetics/databases"
dbpath="NCBI_BLAST_DB/nt"
address="ftp://ftp.ncbi.nlm.nih.gov/blast/db"

# ------------------ Functions --------------------------------------------

update_versionlist() {
	[ -e "$1"/dbversions.tsv ] || echo -e "database\tlast_updated" > "$1"/dbversions.tsv

	versions="$(awk \
		-v db="$2" \
		-v date="$(date +%d-%m-%Y)" \
		-v user="$USER" \
		'BEGIN{FS = OFS = "\t"}
		{
		if ($1 == db)
			{
			$2 = date
			$3 = user
			add = "n"
			}
		print $0
		}
		END{
		if (add == "n")
			{exit}
		print db, date, user
		}' \
		"$1"/dbversions.tsv)"

	echo -n "$versions" > "$1"/dbversions.tsv
}

# ------------------ Main -------------------------------------------------

[ -d "$basepath" ] || { echo 1>&2 "$basepath does not seem to exist"; exit 1; }

cd "$basepath" || { echo 1>&2 "Something went wrong..."; exit 2; }

[ -d "$dbpath" ] && rm -rf "$dbpath"

mkdir -p "$dbpath"

cd "$dbpath" || { echo 1>&2 "Something went wrong..."; exit 3; }

# ^ anchors to beginning of line, [0-9] matches digits, + mathces one or more of the previous character, $ anchors to the end of the line
for i in $(curl -vs "$address"/ 2>&1 | awk '{if ($9 ~/^nt\.[0-9]+\.tar\.gz$/) {print $9}}'); do
	echo "Downloading $i..." \
	&& \
	curl \
		-L \
		"$address"/"$i" \
	| tar \
		-xzf \
		-
done
echo "$db available in $basepath/$dbpath"

update_versionlist "$basepath" "$db"

exit 0