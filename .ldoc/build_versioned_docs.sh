#!/usr/bin/env bash

# place this file in mod ".ldoc" directory


d_ldoc="$(dirname $(readlink -f $0))"

cd "${d_ldoc}/.."

d_root="$(pwd)"
d_export="${d_export:-${d_root}/docs/reference}"

cmd_ldoc="${d_root}/../ldoc/ldoc.lua"
if test -f "${cmd_ldoc}"; then
	if test ! -x "${cmd_ldoc}"; then
		chmod +x "${cmd_ldoc}"
	fi
else
	cmd_ldoc="ldoc"
fi

# clean old files
rm -rf "${d_export}"

# store current branch
main_branch="$(git branch --show-current)"

html_out="<html>\n<head></head>\n\n<body>\n\n<ul>\n"

# generate new doc files
mkdir -p "${d_export}"
for vinfo in $(git tag -l --sort=-v:refname | grep "^v[0-9]"); do
	echo -e "\nbuilding ${vinfo} docs ..."
	git checkout ${vinfo}
	d_temp="${d_ldoc}/temp"
	mkdir -p "${d_temp}"

	f_config="${d_ldoc}/config.ld"
	if test ! -f "${f_config}"; then
		# backward compat
		f_config="${d_root}/docs/config.ld"
	fi

	if test ! -f "${f_config}"; then
		echo -e "\nLDoc config not found, skipping build for ${vinfo} ..."
		continue
	fi

	parse_readme="${d_ldoc}/parse_readme.py"
	if test -f "${parse_readme}"; then
		if test ! -x "${parse_readme}"; then
			chmod +x "${parse_readme}"
		fi

		"${parse_readme}" "${vinfo}"
	else
		echo -e "\nparse_readme.py not found, skipping README.md parsing ..."
	fi

	echo
	"${cmd_ldoc}" --UNSAFE_NO_SANDBOX --multimodule -c "${f_config}" -d "${d_temp}" "${d_root}"; retval=$?
	if test ${retval} -ne 0; then
		echo -e "\nERROR: doc build for ${vinfo} failed!"
		rm -rf "${d_temp}"
		continue
	fi

	# show version info
	for html in $(find "${d_temp}" -type f -name "*.html"); do
		sed -i -e "s|^<h1>Sounds</h1>$|<h1>Sounds <span style=\"font-size:12pt;\">(${vinfo})</span></h1>|" "${html}"
	done

	# copy screenshot
	screenshot="${d_root}/screenshot.png"
	if test -f "${screenshot}"; then
		cp "${d_root}/screenshot.png" "${d_temp}"
	fi

	rm -f "${d_ldoc}/README.md"

	if test -d "${d_root}/textures"; then
		# copy textures to data directory
		echo -e "\ncopying textures ..."
		d_data="${d_temp}/data"
		mkdir -p "${d_data}"
		texture_count=0
		for png in $(find "${d_root}/textures" -maxdepth 1 -type f -name "*.png"); do
			t_png="${d_data}/$(basename ${png})"
			if test -f "${t_png}"; then
				echo "WARNING: not overwriting existing file: ${t_png}"
			else
				cp "${png}" "${d_data}"
				texture_count=$((texture_count + 1))
				printf "\rcopied ${texture_count} textures"
			fi
		done
	fi

	mv "${d_temp}" "${d_export}/${vinfo}"
	if test -z ${vcur+x}; then
		vcur="${vinfo}"
		ln -s "${d_export}/${vinfo}" "${d_export}/current"
		ln -s "${d_export}/${vinfo}" "${d_export}/latest"
		html_out="${html_out}  <li><a href=\"current/\">current</a></li>\n"
		html_out="${html_out}  <li><a href=\"latest/\">latest</a></li>\n"
	fi
	html_out="${html_out}  <li><a href=\"${vinfo}/\">${vinfo}</a></li>\n"
done

html_out="${html_out}</ul>\n\n</body></html>"

cd "${d_root}"
git checkout ${main_branch}

echo -e "${html_out}" > "${d_export}/index.html"

echo -e "\nDone!"
