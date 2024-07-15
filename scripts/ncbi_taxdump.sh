#!/bin/bash

# ------------------ Configuration ----------------------------------------

db="NCBI_Taxdump"
basepath="/faststorage/project/EcoGenetics/databases"
dbpath="NCBI_Taxdump"
address="ftp://ftp.ncbi.nih.gov/pub/taxonomy/new_taxdump/new_taxdump.tar.gz"

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

[ -d "$basepath" ] || (echo 1>&2 "$basepath does not seem to exist" && exit 1)

cd "$basepath" || (echo 1>&2 "Something went wrong..." && exit 2)

[ -d "$dbpath" ] && rm -rf "$dbpath"

mkdir -p "$dbpath"

cd "$dbpath" || (echo 1>&2 "Something went wrong..." && exit 3)

echo "Downloading $db..." \
&& \
curl \
	-L \
	"$address" \
| tar -xzf - \
&& \
echo "$db available in $basepath/$dbpath"

update_versionlist "$basepath" "$db"

exit 0