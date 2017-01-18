/* findpkgs-dep-helper.c
 *
 * A compiled helper program to speed up the dependency checking in
 * woof-CE/woof-code/support/findpkgs
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>


/* The lines from the files specified on the command line, for example
 * /tmp/findpkgs_tmp/compat_log1 /tmp/findpkgs_tmp/pet_log1
 * are stored in memory as a linked list of pkglist_entry_struct structures.
 */
struct pkglist_entry_struct
{
	char *mem_buffer;
	char *pkg_name;
	char *pkg_version;
	char *pkg_filename;
	char *pkg_distro_binary_compat;
	char *pkg_distro_compat_version;
	char *pkg_from_package_list;
	char *pkg_dependency_field;
};

/* The pkg_dependency_field, DEPCONDS in findpkgs, is separated into
 * a linked list of one_depcond_struct structures.
 */
struct one_depcond_struct
{
	char dep_op[3];
	char *dep_ver;
};

/* A structure with a union to implement the linked lists.
*/
struct list_item_struct
{
	union
	{
		char *pkg_alias;
		struct pkglist_entry_struct *pkglist_entry;
		struct one_depcond_struct *one_depcond;
		struct list_item_struct *list_item;
	};
	struct list_item_struct *next;
};


// current_pkglist_item needs to be global so
// multiple input files don't overwrite each other
// and get_next_versioned_dependency() works
struct list_item_struct **current_pkglist_item;
struct list_item_struct *root_pkglist_item;

struct list_item_struct *root_pkg_aliases_item;

struct list_item_struct *root_fnd_ok_deps_item;
struct list_item_struct *root_fnd_ok_apps_item;


/* The functions ver_cmp and vercmp_func were originally from vercmp.c */

/* vi: set sw=4 ts=4: */
/*
 * libdpkg - Debian packaging suite library routines
 * vercmp.c - comparison of version numbers
 *
 * Copyright (C) 1995 Ian Jackson <iwj10@cus.cam.ac.uk>
 *
 * Licensed under GPLv2, see file LICENSE in this source tree
 *
 * location: woof-arch/<arch>/target/rootfs-skeleton/bin/vercmp
 */

static int ver_cmp(const char *val, const char *ref)
{
	int vc, rc;
	long vl, rl;
	const char *vp, *rp;
	const char *vsep, *rsep;

	for (;;) {
		vp= val;  while (*vp && !isdigit(*vp)) vp++;
		rp= ref;  while (*rp && !isdigit(*rp)) rp++;
		for (;;) {
			vc= val == vp ? 0 : *val++;
			rc= ref == rp ? 0 : *ref++;
			if (!rc && !vc) break;
			if (vc && !isalpha(vc)) vc += 256; /* assumes ASCII character set */
			if (rc && !isalpha(rc)) rc += 256;
			if (vc != rc) return vc - rc;
		}
		val= vp;
		ref= rp;
		vl=0;  if (isdigit(*vp)) vl= strtol(val,(char**)&val,10);
		rl=0;  if (isdigit(*rp)) rl= strtol(ref,(char**)&ref,10);
		if (vl != rl) return vl - rl;

		vc = *val;
		rc = *ref;
		vsep = strchr(".-", vc);
		rsep = strchr(".-", rc);
		if (vsep && !rsep) return -1;
		if (!vsep && rsep) return +1;

		if (!*val && !*ref) return 0;
		if (!*val) return -1;
		if (!*ref) return +1;
	}
}

int vercmp_func(char *arg1, char *arg2, char *arg3)
{
	int r, res;
	r = ver_cmp(arg1, arg3);

	if      (!strcmp(arg2, "le")) res = !(r <= 0);
	else if (!strcmp(arg2, "ge")) res = !(r >= 0);
	else if (!strcmp(arg2, "lt")) res = !(r < 0);
	else if (!strcmp(arg2, "gt")) res = !(r > 0);
	else if (!strcmp(arg2, "eq")) res = !(r == 0);
	else { printf("unknown operator: %s", arg2); return 1; }

	//printf("%s\n", res == 0 ? "true" : "false");
	return res;
}

int read_one_file(char *filename)
{
	int i;
	struct pkglist_entry_struct *one_pkglist_entry = NULL;

	int bytes_read;
	char *one_line = NULL;
	size_t line_length;

	const char delim[3] = "|\n";
	char *token = NULL;

	// open one file
	FILE *my_stream;
	my_stream = fopen(filename, "r");

	if (my_stream == NULL)
	{
		printf("File %s could not be opened\n", filename);
		return 1;
	}

	i=0;
	while (1)
	{
		// read each line
		bytes_read = getline(&one_line, &line_length, my_stream);
		if (bytes_read == -1)
		{
			free(one_line);
			break;
		}

		i++;
		// allocate a new list item
		*current_pkglist_item = (struct list_item_struct*)
			malloc(sizeof(struct list_item_struct));
		(*current_pkglist_item)->next = NULL;

		// allocate a new pkglist_entry
		one_pkglist_entry = (struct pkglist_entry_struct*)
			malloc(sizeof(struct pkglist_entry_struct));
		(*current_pkglist_item)->pkglist_entry = one_pkglist_entry;

		// store pointer to memory allocated by getline
		one_pkglist_entry->mem_buffer = one_line;


		// read pkg_name, not optional
		token = strsep(&one_line, delim);
		if (token == NULL || *token == '\0' || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_name = token;

		// read pkg_version, not optional
		token = strsep(&one_line, delim);
		if (token == NULL || *token == '\0' || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_version = token;

		// read pkg_filename
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_filename = token;

		// read pkg_distro_binary_compat
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_distro_binary_compat = token;

		// read pkg_distro_compat_version
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_distro_compat_version = token;

		// read pkg_from_package_list
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_from_package_list = token;

		// read pkg_dependency_field, is optional
		token = strsep(&one_line, delim);
		if (token == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_dependency_field = token;


		// prepare for next new list item
		current_pkglist_item = &(*current_pkglist_item)->next;

		// prepare to read next line
		one_line = NULL;
		line_length = 0;
	}

	// close file
	fclose(my_stream);
	return 0;

	read_one_file_error:

	printf("Error processing file: %s line: %d \n", filename, i);
	return 1;

}

int write_file(char *filename, struct list_item_struct *list)
{
	struct list_item_struct **current_list_item = NULL;
	int close_error = 0;

	// open one file
	FILE *my_stream;
	my_stream = fopen(filename, "w");

	if (my_stream == NULL)
	{
		printf("\nFile %s could not be opened\n", filename);
		return 1;
	}

	current_list_item = &list;
	while (*current_list_item != NULL)
	{
		if ((*current_list_item)->pkglist_entry != NULL)
		{
			fprintf(my_stream, "%s|",
				(*current_list_item)->pkglist_entry->pkg_name);
			fprintf(my_stream, "%s|",
				(*current_list_item)->pkglist_entry->pkg_version);
			fprintf(my_stream, "%s|",
				(*current_list_item)->pkglist_entry->pkg_filename);
			fprintf(my_stream, "%s|",
				(*current_list_item)->pkglist_entry->pkg_distro_binary_compat);
			fprintf(my_stream, "%s|",
				(*current_list_item)->pkglist_entry->pkg_distro_compat_version);
			fprintf(my_stream, "%s|",
				(*current_list_item)->pkglist_entry->pkg_from_package_list);
			fprintf(my_stream, "%s\n",
				(*current_list_item)->pkglist_entry->pkg_dependency_field);
		}
		current_list_item = &(*current_list_item)->next;
	}


	// close file
	close_error = fclose(my_stream);
	if (close_error != 0)
	{
		printf("\nError writing file: %s\n", filename);
		return 1;
	}
	return 0;
}

int get_next_versioned_dependency()
{
	// not much code here, but it makes the while loop in
	// process_versioned_dependencies() clearer
	while (*current_pkglist_item != NULL &&
		strchr((*current_pkglist_item)
		->pkglist_entry->pkg_dependency_field, '&') == NULL)
	{
		current_pkglist_item = &(*current_pkglist_item)->next;
	}
	if (*current_pkglist_item == NULL)
		return 1;

	return 0;
}

int comp_alias(char *alias, char *name)
{
	size_t compare_length = 0;
	char *alias_pointer = NULL;
	char *name_pointer = NULL;

	// if alias up to any "*" matches name
	compare_length = strcspn(alias, "*");
	if (strncmp(name, alias, compare_length) == 0)
	{
		// if there is no "*" in alias
		if (compare_length == strlen(alias))
		{
			// and both strings are the same length
			if (strlen(alias) == strlen(name))
			{
				// it matches
				return 0;
			}
		}
		else // there is a "*" in alias
		{
			// if the "*" is at the end of alias
			alias_pointer = alias+strlen(alias)-1;
			if (rindex(alias, '*') == alias_pointer)
			{
				// it matches
				return 0;
			}
			else // the "*" is in the middle of alias
			{
				// starting at the ends of alias and name
				name_pointer = name+strlen(name)-1;
				while (*alias_pointer != '*')
				{
					// check if each character matches
					if (*alias_pointer == *name_pointer)
					{
						alias_pointer--;
						name_pointer--;
					}
					else
					{
						// it didn't match
						return 1;
					}
				}
				// if it made it all the way to the "*" in alias
				// it matches
				return 0;
			}
		}
	}
	// it didn't match
	return 1;
}

void process_versioned_dependencies()
{
	struct list_item_struct *root_depcond_item = NULL;
	struct list_item_struct **current_depcond_item = NULL;
	struct list_item_struct *temp1_depcond_item = NULL;
	struct list_item_struct *temp2_depcond_item = NULL;

	struct list_item_struct **fndpkg_pkglist_item = NULL;

	struct list_item_struct **current_fnd_ok_deps_item = NULL;
	struct list_item_struct **current_fnd_ok_apps_item = NULL;

	struct list_item_struct **current_pkg_item = NULL;
	struct list_item_struct **current_alias_item = NULL;

	char *mem_buffer = NULL;
	char *dep_conds = NULL;
	char *dep_name = NULL;
	char *temp = NULL;

	// fake_pkg_item to use if no aliases found
	struct list_item_struct fake_alias_item;
	struct list_item_struct fake_pkg_item;
	struct list_item_struct *fake_pkg_item_pointer;
	fake_pkg_item.list_item = &fake_alias_item;
	fake_pkg_item.next = NULL;
	fake_alias_item.next = NULL;
	fake_pkg_item_pointer = &fake_pkg_item;

	root_fnd_ok_deps_item = NULL;
	root_fnd_ok_apps_item = NULL;

	current_pkglist_item = &root_pkglist_item;

	// equivalent to "for ONESPEC" in findpkgs
	while (get_next_versioned_dependency() == 0)
	{


		// ### Start processing pkg_dependency_field ###

		// copy the pkg_dependency_field to a new chunk of memory
		mem_buffer = strdup((*current_pkglist_item)
								->pkglist_entry->pkg_dependency_field);
		dep_conds = mem_buffer;
		// seperate it into seperate dep_name and dep_conds strings
		dep_name = strsep(&dep_conds, "&");

		root_depcond_item = NULL;
		current_depcond_item = &root_depcond_item;

		while (dep_conds != NULL)
		{
			// allocate a new depcond_item
			*current_depcond_item = (struct list_item_struct*)
				malloc(sizeof(struct list_item_struct));
			(*current_depcond_item)->next = NULL;

			(*current_depcond_item)->one_depcond =
				(struct one_depcond_struct*)
				malloc(sizeof(struct one_depcond_struct));

			(*current_depcond_item)->one_depcond->dep_op[0] = '\0';
			(*current_depcond_item)->one_depcond->dep_op[1] = '\0';
			(*current_depcond_item)->one_depcond->dep_op[2] = '\0';

			// store one set of dep_conds
			temp = strsep(&dep_conds, "&");
			strncpy((*current_depcond_item)->one_depcond->dep_op, temp, 2);
			(*current_depcond_item)->one_depcond->dep_ver = &temp[2];

			// prepare for next depcond_item
			current_depcond_item = &(*current_depcond_item)->next;
		}
/*
		// test, print all depcond_items to stdout
		current_depcond_item = &root_depcond_item;
		while (*current_depcond_item != NULL)
		{
			printf("%s%s ", (*current_depcond_item)->one_depcond->dep_op,
				(*current_depcond_item)->one_depcond->dep_ver);
			current_depcond_item = &(*current_depcond_item)->next;
		}
*/

		// ### End processing pkg_dependency_field ###


///////////////////////////////////////////////////////////////////////////////
		printf("%s ", dep_name);
//		fflush(stdout); // may be helpful for debugging, but slows things down
///////////////////////////////////////////////////////////////////////////////


		// ### Start processing pkg_aliases ###

		current_pkg_item = &root_pkg_aliases_item;
		while (*current_pkg_item != NULL)
		{
			current_alias_item = &(*current_pkg_item)->list_item;
			while (*current_alias_item != NULL)
			{
				if (comp_alias((*current_alias_item)->pkg_alias, dep_name) == 0)
				{
					goto finished_searching_aliases;
				}
				// alias didn't match
				current_alias_item = &(*current_alias_item)->next;
			}
			current_pkg_item = &(*current_pkg_item)->next;
		}
		finished_searching_aliases:

		// set up fake_pkg_item so following code
		// can treat dep_name the same as an alias
		if (*current_pkg_item == NULL)
		{
			current_pkg_item = &fake_pkg_item_pointer;
			fake_alias_item.pkg_alias = dep_name;
		}

		current_alias_item = &(*current_pkg_item)->list_item;
/*
		// test, print dep_name and matching alias to stdout
		if (*current_alias_item != NULL &&
			(*current_alias_item)->pkg_alias != NULL)
			printf("dep_name=%s pkg_alias=%s\n",
				dep_name, (*current_alias_item)->pkg_alias);
*/
		// ### End processing pkg_aliases ###


		// ### Start processing pkg_version ###

		// equivalent to "for namePTN in $aliasPTNS" in findpkgs
		while (*current_alias_item != NULL)
		{
			// equivalent to "for FNDPKG" in findpkgs
			fndpkg_pkglist_item = &root_pkglist_item;
			while (*fndpkg_pkglist_item != NULL)
			{
				// check if FNDPKG matches current_alias_item
				if (comp_alias((*current_alias_item)->pkg_alias,
						(*fndpkg_pkglist_item)->pkglist_entry->pkg_name) == 0)
				{
					// check if FNDPKG matches the dependency requirements
					current_depcond_item = &root_depcond_item;
					while (*current_depcond_item != NULL)
					{
						if (vercmp_func(
							(*fndpkg_pkglist_item)->pkglist_entry->pkg_version,
							(*current_depcond_item)->one_depcond->dep_op,
							(*current_depcond_item)->one_depcond->dep_ver) != 0)
						{
/*							// test that vercmp_func is working properly
							printf("pkglist_version=%s dep_op=%s dep_ver=%s\n",
							(*fndpkg_pkglist_item)->pkglist_entry->pkg_version,
							(*current_depcond_item)->one_depcond->dep_op,
							(*current_depcond_item)->one_depcond->dep_ver);
*/
							goto next_pkglist_entry;
						}
						current_depcond_item = &(*current_depcond_item)->next;
					}
				}
				else
				{
					goto next_pkglist_entry;
				}

//				#version is ok.
//				#log dep info, make sure only latest version is logged...

				// search for an existing entry in fnd_ok_deps
				current_fnd_ok_deps_item = &root_fnd_ok_deps_item;
				while (*current_fnd_ok_deps_item != NULL)
				{
					if (comp_alias(
						(*current_alias_item)->pkg_alias,
						(*current_fnd_ok_deps_item)->pkglist_entry->pkg_name
						) == 0)
					{
						break;
					}
					current_fnd_ok_deps_item =
						&(*current_fnd_ok_deps_item)->next;
				}

				// if an existing entry was not found, add one
				if (*current_fnd_ok_deps_item == NULL)
				{
					// allocate a new fnd_ok_deps_item
					*current_fnd_ok_deps_item = (struct list_item_struct*)
						malloc(sizeof(struct list_item_struct));
					(*current_fnd_ok_deps_item)->next = NULL;
					// add pkglist_entry
					(*current_fnd_ok_deps_item)->pkglist_entry =
						(*fndpkg_pkglist_item)->pkglist_entry;
				}
				else
				{
					// check if current entry is newer than existing entry
					if (vercmp_func(
							(*fndpkg_pkglist_item)->pkglist_entry->pkg_version,
							"gt",
							(*current_fnd_ok_deps_item)
								->pkglist_entry->pkg_version) == 0)
					{
/*
						// test, print any upgraded versions to stdout
						printf("old_version=%s\nnew_version=%s\n\n",
							(*current_fnd_ok_deps_item)
								->pkglist_entry->pkg_version,
							(*fndpkg_pkglist_item)->pkglist_entry->pkg_version);
*/
						// replace original version with newer version
						(*current_fnd_ok_deps_item)->pkglist_entry =
							(*fndpkg_pkglist_item)->pkglist_entry;
					}
				}

//		#log actual pkg info as well as deps, make sure latest version logged...
				// search for an existing entry in fnd_ok_apps
				current_fnd_ok_apps_item = &root_fnd_ok_apps_item;
				while (*current_fnd_ok_apps_item != NULL)
				{
					if (comp_alias(
						(*current_pkglist_item)->pkglist_entry->pkg_name,
						(*current_fnd_ok_apps_item)->pkglist_entry->pkg_name
						) == 0)
					{
						break;
					}
					current_fnd_ok_apps_item =
						&(*current_fnd_ok_apps_item)->next;
				}

				// if an existing entry was not found, add one
				if (*current_fnd_ok_apps_item == NULL)
				{
					// allocate a new fnd_ok_apps_item
					*current_fnd_ok_apps_item = (struct list_item_struct*)
						malloc(sizeof(struct list_item_struct));
					(*current_fnd_ok_apps_item)->next = NULL;
					// add pkglist_entry
					(*current_fnd_ok_apps_item)->pkglist_entry =
						(*current_pkglist_item)->pkglist_entry;
				}
				else
				{
					// check if current entry is newer than existing entry
					if (vercmp_func(
						(*current_pkglist_item)->pkglist_entry->pkg_version,
						"gt",
						(*current_fnd_ok_apps_item)->pkglist_entry->pkg_version
						) == 0)
					{

/*						// test, print any upgraded versions to stdout
						printf("old_version=%s\nnew_version=%s\n\n",
							(*current_fnd_ok_apps_item)->pkglist_entry->pkg_version,
							(*current_pkglist_item)->pkglist_entry->pkg_version);
*/
						// replace original version with newer version
						(*current_fnd_ok_apps_item)->pkglist_entry =
							(*current_pkglist_item)->pkglist_entry;
					}
				}


				next_pkglist_entry:
				fndpkg_pkglist_item = &(*fndpkg_pkglist_item)->next;
			}	// equivalent to "for FNDPKG" in findpkgs

			current_alias_item = &(*current_alias_item)->next;
		}	// equivalent to "for namePTN in $aliasPTNS" in findpkgs


///////////////////////////////////////////////////////////////////////////////

		// free memory used by mem_buffer and reset pointers

		// I think it is ok to call free on a NULL pointer
		// just not on a pointer that has already been freed
		free(mem_buffer);
		mem_buffer = NULL;
		dep_conds = NULL;
		dep_name = NULL;

		// free memory used by depcond_item list
		temp1_depcond_item = root_depcond_item;
		while (temp1_depcond_item != NULL)
		{
			free(temp1_depcond_item->one_depcond);
			temp2_depcond_item = temp1_depcond_item->next;
			free(temp1_depcond_item);
			temp1_depcond_item = temp2_depcond_item;
		}
		// and reset pointers
		root_depcond_item = NULL;
		current_depcond_item = NULL;

		// move on to next pkglist_item
		current_pkglist_item = &(*current_pkglist_item)->next;

	}	// equivalent to "for ONESPEC" in findpkgs
}

int main(int argc, char **argv)
{
	int i;
	char *pkg_aliases_buffef = NULL;
	char *pkg_aliases_pointer = NULL;
	char *one_pkg_pointer = NULL;
	struct list_item_struct *temp1_list_item = NULL;
	struct list_item_struct *temp2_list_item = NULL;
	struct list_item_struct *temp3_list_item = NULL;
	struct list_item_struct *temp4_list_item = NULL;
	struct list_item_struct **current_pkg_item = NULL;
	struct list_item_struct **current_alias_item = NULL;

	root_pkglist_item = NULL;
	current_pkglist_item = &root_pkglist_item;

	root_pkg_aliases_item = NULL;

	// process command line args
	for (i = 1; i < argc; i++)
	{
		// the format of --pkg-name-aliases should be what is used in
		// PKGS_MANAGEMENT for PKG_NAME_ALIASES, not aliasesPTNS from findpkgs
		if (strncmp( "--pkg-name-aliases", argv[i], 18) == 0)
		{
			// NOTE: I tried to implement support for PKG_NAME_ALIASES the best
			// I could, but since it is broken in the original findpkgs script,
			// I can't test my implementation against the original.
			// Using it might cause unexpected problems.
			// 											--- woodenshoe-wi

			if (strncmp("--pkg-name-aliases=", argv[i], 19) == 0)
			{
				// if the argument is attached,
				// trim off the "--pkg-name-aliases=" part
				pkg_aliases_buffef = strdup(argv[i]);
				pkg_aliases_pointer = pkg_aliases_buffef;
				strsep(&pkg_aliases_pointer, "=");

				if (pkg_aliases_pointer == NULL || *pkg_aliases_pointer == '\0')
				{
					printf("Error: Missing argument to --pkg-name-aliases\n");
					return 1;
				}
			}
			else
			{
				// otherwise use the next argument
				i++;
				if (i < argc)
				{
					pkg_aliases_buffef = strdup(argv[i]);
					pkg_aliases_pointer = pkg_aliases_buffef;
				}
				else
				{
					printf("Error: Missing argument to --pkg-name-aliases\n");
					return 1;
				}
			}

			current_pkg_item = &root_pkg_aliases_item;

			while (pkg_aliases_pointer != NULL)
			{
				// allocate a new package item
				*current_pkg_item = (struct list_item_struct*)
					malloc(sizeof(struct list_item_struct));
				(*current_pkg_item)->next = NULL;

				current_alias_item = &(*current_pkg_item)->list_item;

				one_pkg_pointer = strsep(&pkg_aliases_pointer, " ");
				while (one_pkg_pointer != NULL)
				{
					// allocate a new aliases item
					*current_alias_item = (struct list_item_struct*)
						malloc(sizeof(struct list_item_struct));
					(*current_alias_item)->next = NULL;

					(*current_alias_item)->pkg_alias =
						strsep(&one_pkg_pointer, ",");

					current_alias_item = &(*current_alias_item)->next;
				}
				current_pkg_item = &(*current_pkg_item)->next;
			}

/*
			// test, print all pkg_aliases to stdout
			current_pkg_item = &root_pkg_aliases_item;
			while (*current_pkg_item != NULL)
			{
				current_alias_item = &(*current_pkg_item)->list_item;

				while (*current_alias_item != NULL)
				{
					printf("%s,", (*current_alias_item)->pkg_alias);
					current_alias_item = &(*current_alias_item)->next;
				}
				printf(" ");
				current_pkg_item = &(*current_pkg_item)->next;
			}
*/

		}
		else
		{
			if (read_one_file(argv[i]) != 0)
				return 1;
		}
	}


	if (root_pkglist_item == NULL)
	{
		printf("Usage: findpkgs-dep-helper \
[--pkg-name-aliases=\"$PKG_NAME_ALIASES\"] <package list> [<package list>]\n");
		return 1;
	}

	process_versioned_dependencies();

	write_file("/tmp/findpkgs_tmp/fnd_ok_deps", root_fnd_ok_deps_item);
	write_file("/tmp/findpkgs_tmp/fnd_ok_apps", root_fnd_ok_apps_item);


/*
	// test, print all pkglist entries to stdout
	current_pkglist_item = &root_pkglist_item;
	while (*current_pkglist_item != NULL)
	{
		printf("%s|", (*current_pkglist_item)->pkglist_entry->pkg_name);
		printf("%s|", (*current_pkglist_item)->pkglist_entry->pkg_version);
		printf("%s|", (*current_pkglist_item)->pkglist_entry->pkg_filename);
		printf("%s|", (*current_pkglist_item)
							->pkglist_entry->pkg_distro_binary_compat);
		printf("%s|", (*current_pkglist_item)
							->pkglist_entry->pkg_distro_compat_version);
		printf("%s|", (*current_pkglist_item)
							->pkglist_entry->pkg_from_package_list);
		printf("%s\n", (*current_pkglist_item)
							->pkglist_entry->pkg_dependency_field);
		current_pkglist_item = &(*current_pkglist_item)->next;
	}
*/

	free(pkg_aliases_buffef);

	// free pkglist_items
	temp1_list_item = root_pkglist_item;
	while (temp1_list_item != NULL)
	{
		free(temp1_list_item->pkglist_entry->mem_buffer);
		free(temp1_list_item->pkglist_entry);
		temp2_list_item = temp1_list_item->next;
		free(temp1_list_item);
		temp1_list_item = temp2_list_item;
	}

	// free pkg_aliases_items
	temp1_list_item = root_pkg_aliases_item;
	while (temp1_list_item != NULL)
	{
		temp3_list_item = temp1_list_item->list_item;
		while (temp3_list_item != NULL)
		{
			temp4_list_item = temp3_list_item->next;
			free(temp3_list_item);
			temp3_list_item = temp4_list_item;
		}
		temp2_list_item = temp1_list_item->next;
		free(temp1_list_item);
		temp1_list_item = temp2_list_item;
	}

	// free fnd_ok_deps_items
	temp1_list_item = root_fnd_ok_deps_item;
	while (temp1_list_item != NULL)
	{
		// pkglist_entry items have already been freed
		temp2_list_item = temp1_list_item->next;
		free(temp1_list_item);
		temp1_list_item = temp2_list_item;
	}


	// free fnd_ok_apps_items
	temp1_list_item = root_fnd_ok_apps_item;
	while (temp1_list_item != NULL)
	{
		// pkglist_entry items have already been freed
		temp2_list_item = temp1_list_item->next;
		free(temp1_list_item);
		temp1_list_item = temp2_list_item;
	}

return 0;
}
