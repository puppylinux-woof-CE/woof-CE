/* findpkgs-search-helper.c
 *
 * A compiled helper program to speed up the search function in
 * woof-CE/woof-code/support/findpkgs
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>


/* The entries from the packagelist files are stored in memory
 * as a linked list of pkglist_entry_struct structures.
 *
 * field descriptions based on findpkgs line 210:
 * #db fields: pkgname|nameonly|version|pkgrelease|category[;subcategory]|size|path|fullfilename|dependencies|description|compileddistro|compiledrelease|repo|
 */
struct pkglist_entry_struct
{
	char *mem_buffer;
	char *pkg_name;
	char *pkg_name_only;
	char *pkg_version;
	char *pkg_release;
	char *pkg_category;
	char *pkg_size;
	char *pkg_path;
	char *pkg_filename;
	char *pkg_dependency_field;
	char *pkg_description;
	char *pkg_compiled_distro;
	char *pkg_compiled_release;
	char *pkg_repo;
};

/* The entries in /tmp/findpkgs_tmp/FINAL_PKGS
 * have three more fields than the packagelist files.
 */
struct final_pkgs_extra_fields_struct
{
		char *generic_name_field;
		char *pkg_loc1;
		char *repo_db_file;
};

/* A structure with a union to implement linked lists.
 */
struct single_list_item_struct
{
	union
	{
		char *name;
		struct pkglist_entry_struct *pkglist_entry;
		struct single_list_item_struct *list_item;
	};
	struct single_list_item_struct *next;
};

/* A structure with two unions to implement named linked lists,
 * the entries in /tmp/findpkgs_tmp/FINAL_PKGS and
 * store the argument to --petcompiledPTNS
 */
struct double_list_item_struct
{
	union
	{
		char *distro;
		char *list_name;
		struct final_pkgs_extra_fields_struct *extra_fields;
	};
	union
	{
		char *release;
		struct single_list_item_struct *list_item;
		struct pkglist_entry_struct *pkglist_entry;
	};
	struct double_list_item_struct *next;
};

/* Stores the arguments to --packagelists-pet-order and
 * --pkglists-compat as linked lists.
 */
struct double_list_item_struct *root_item_packagelists_pet_order;
struct double_list_item_struct *root_item_pkglists_compat;

/* Stores the argument to --pkgs-specs-table
 */
char *pkgs_specs_table;

/* Stores the argument to --petcompiledPTNS as a linked list.
 */
struct double_list_item_struct *root_item_pet_compiled_ptns;

/* Stores the contents of /tmp/findpkgs_tmp/PREFERRED_PKGS
 * and the data to be written to /tmp/findpkgs_tmp/FINAL_PKGS
 */
struct single_list_item_struct *root_item_preferred_pkgs;
struct double_list_item_struct *root_item_final_pkgs;

char is_verbose;
char is_debug;


static
int read_one_file(char *filename, struct single_list_item_struct **current_list_item)
{
	int i;
	struct pkglist_entry_struct *one_pkglist_entry = NULL;

	int bytes_read;
	char *one_line = NULL;
	size_t line_length;

	const char delim[3] = "|\n";
	char *token = NULL;
	FILE *one_file;

	// open one file
	one_file = fopen(filename, "r");

	if (one_file == NULL)
	{
		printf("File %s could not be opened\n", filename);
		return 1;
	}

	i=0;
	while (1)
	{
		// read each line
		bytes_read = getline(&one_line, &line_length, one_file);
		if (bytes_read == -1)
		{
			free(one_line);
			break;
		}

		i++;

		// skip blank lines
		if (strspn(one_line, " \t\n") == strlen(one_line))
		{
			continue;
		}


		// allocate a new pkglist_entry
		one_pkglist_entry = (struct pkglist_entry_struct*)
			malloc(sizeof(struct pkglist_entry_struct));

		// store pointer to memory allocated by getline
		one_pkglist_entry->mem_buffer = one_line;


		// read pkg_name, not optional
		token = strsep(&one_line, delim);
		if (token == NULL || *token == '\0' || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_name = token;

		// read pkg_name_only, not optional
		token = strsep(&one_line, delim);
		if (token == NULL || *token == '\0' || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_name_only = token;

		// read pkg_version
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_version = token;

		// read pkg_release
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_release = token;

		// read pkg_category
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_category = token;

		// read pkg_size
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_size = token;

		// read pkg_path
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_path = token;

		// read pkg_filename
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_filename = token;

		// read pkg_dependency_field
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_dependency_field = token;

		// read pkg_description
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_description = token;

		// read pkg_compiled_distro
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_compiled_distro = token;

		// read pkg_compiled_release
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_compiled_release = token;

		// read pkg_repo
		token = strsep(&one_line, delim);
		if (token == NULL)
			goto read_one_file_error;
		one_pkglist_entry->pkg_repo = token;



		// allocate a new list item
		*current_list_item = (struct single_list_item_struct*)
			malloc(sizeof(struct single_list_item_struct));
		(*current_list_item)->next = NULL;

		// save one_pkglist_entry
		(*current_list_item)->pkglist_entry = one_pkglist_entry;

		// prepare for next new list item
		current_list_item = &(*current_list_item)->next;

		// prepare to read next line
		one_line = NULL;
		line_length = 0;


		continue;

		read_one_file_error:

		free(one_pkglist_entry->mem_buffer);
		free(one_pkglist_entry);
		one_line = NULL;
		line_length = 0;

		printf("Error processing file: %s line: %d \n", filename, i);

	}

	// close file
	fclose(one_file);
	return 0;
}


int read_preferred_pkgs_file()
{
	int i;
	struct pkglist_entry_struct *one_pkglist_entry = NULL;
	struct single_list_item_struct **current_list_item;

	int bytes_read;
	char *one_line = NULL;
	size_t line_length;

	const char delim[3] = "|\n";
	char *token = NULL;
	FILE *one_file;

	// open /tmp/findpkgs_tmp/PREFERRED_PKGS
	one_file = fopen("/tmp/findpkgs_tmp/PREFERRED_PKGS", "r");

	if (one_file == NULL)
	{
		printf("/tmp/findpkgs_tmp/PREFERRED_PKGS could not be opened\n");
		return 1;
	}

	current_list_item = &root_item_preferred_pkgs;

	i=0;
	while (1)
	{
		// read each line
		bytes_read = getline(&one_line, &line_length, one_file);
		if (bytes_read == -1)
		{
			free(one_line);
			break;
		}

		i++;

		// skip blank lines
		if (strspn(one_line, " \t\n") == strlen(one_line))
		{
			continue;
		}


		// allocate a new pkglist_entry
		one_pkglist_entry = (struct pkglist_entry_struct*)
			malloc(sizeof(struct pkglist_entry_struct));

		// store pointer to memory allocated by getline
		one_pkglist_entry->mem_buffer = one_line;


		// pkg_name field 1
		one_pkglist_entry->pkg_name = NULL;

		// read pkg_name_only field 2
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_preferred_pkgs_file_error;
		one_pkglist_entry->pkg_name_only = token;

		// read pkg_version field 3
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_preferred_pkgs_file_error;
		one_pkglist_entry->pkg_version = token;

		// pkg_release field 4
		one_pkglist_entry->pkg_release = NULL;

		// pkg_category field 5
		one_pkglist_entry->pkg_category = NULL;

		// pkg_size field 6
		one_pkglist_entry->pkg_size = NULL;

		// pkg_path field 7
		one_pkglist_entry->pkg_path = NULL;

		// read pkg_filename field 8
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_preferred_pkgs_file_error;
		one_pkglist_entry->pkg_filename = token;

		// read pkg_dependency_field field 9
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_preferred_pkgs_file_error;
		one_pkglist_entry->pkg_dependency_field = token;

		// pkg_description field 10
		one_pkglist_entry->pkg_description = NULL;

		// read pkg_compiled_distro field 11
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_preferred_pkgs_file_error;
		one_pkglist_entry->pkg_compiled_distro = token;

		// read pkg_compiled_release field 12
		token = strsep(&one_line, delim);
		if (token == NULL || one_line == NULL)
			goto read_preferred_pkgs_file_error;
		one_pkglist_entry->pkg_compiled_release = token;

		// pkg_repo field 13
		one_pkglist_entry->pkg_repo = NULL;



		// allocate a new list item
		*current_list_item = (struct single_list_item_struct*)
			malloc(sizeof(struct single_list_item_struct));
		(*current_list_item)->next = NULL;

		// save one_pkglist_entry
		(*current_list_item)->pkglist_entry = one_pkglist_entry;

		// prepare for next new list item
		current_list_item = &(*current_list_item)->next;

		// prepare to read next line
		one_line = NULL;
		line_length = 0;


		continue;

		read_preferred_pkgs_file_error:

		free(one_pkglist_entry->mem_buffer);
		free(one_pkglist_entry);
		one_line = NULL;
		line_length = 0;

		printf("Error processing /tmp/findpkgs_tmp/PREFERRED_PKGS line: %d \n", i);

	}

	// close file
	fclose(one_file);
	return 0;
}


int write_final_pkgs_file()
{
	struct double_list_item_struct *one_list_item = NULL;
	int close_error = 0;
	FILE *one_file;

	// open /tmp/findpkgs_tmp/FINAL_PKGS
	one_file = fopen("/tmp/findpkgs_tmp/FINAL_PKGS", "w");

	if (one_file == NULL)
	{
		printf("\n/tmp/findpkgs_tmp/FINAL_PKGS could not be opened\n");
		return 1;
	}

	one_list_item = root_item_final_pkgs;
	while (one_list_item != NULL)
	{
		if (one_list_item->extra_fields != NULL)
		{
			fprintf(one_file, "%s|",
				one_list_item->extra_fields->generic_name_field);
			fprintf(one_file, "%s|",
				one_list_item->extra_fields->pkg_loc1);
			fprintf(one_file, "%s|",
				one_list_item->extra_fields->repo_db_file);
		}
		if (one_list_item->pkglist_entry != NULL)
		{
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_name);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_name_only);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_version);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_release);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_category);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_size);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_path);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_filename);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_dependency_field);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_description);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_compiled_distro);
			fprintf(one_file, "%s|",
				one_list_item->pkglist_entry->pkg_compiled_release);
			fprintf(one_file, "%s|\n",
				one_list_item->pkglist_entry->pkg_repo);
		}
		one_list_item = one_list_item->next;
	}


	// close file
	close_error = fclose(one_file);
	if (close_error != 0)
	{
		printf("\nError writing /tmp/findpkgs_tmp/FINAL_PKGS\n");
		return 1;
	}
	return 0;
}


/* A "*" character in 'alias' will be treated as a wildcard expression,
 * comp_alias does not implement regular expressions.
 * A "*" character in 'name' is not expected.
 */
static
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


int search_func(int search_nr)
{
	char *pkgs_specs_table_pointer = pkgs_specs_table;
	char *one_pkg_spec = NULL;
	char *one_pkg_spec_pointer = NULL;

	char *yes_no = NULL;
	char *generic_name = NULL;

	char *binary_part_names = NULL;
	char *binary_part_names_pointer = NULL;
	char *bpart = NULL;

	char *pkg_location_field = NULL;
	char *pkg_location_field_buffer = NULL;
	char *pkg_location_field_pointer = NULL;

	char *pkg_loc1_pointer = NULL;
	char *pkg_loc2_pointer = NULL;
	char *pkg_loc2_search_string = NULL;

	char *dep_buffer = NULL;
	char *dep_pointer = NULL;
	char *one_dep = NULL;

	char pkg_exists = 0;
	char look_in_filename = 0;
	int close_error = 0;

	char *one_name_ptn = NULL;
	char *name_dev = NULL;
	char *name_doc = NULL;
	char *name_nls = NULL;

	struct single_list_item_struct *root_item_x_binary_part_names = NULL;
	char *one_x_binary_part_name = NULL;
	struct single_list_item_struct **current_item_x_binary_part_names = NULL;
	char *dev_name = NULL;

	struct single_list_item_struct *root_item_binary_excluded = NULL;
	struct single_list_item_struct *one_binary_excluded = NULL;
	struct single_list_item_struct **current_item_binary_excluded = NULL;

	struct single_list_item_struct *one_pkglist_item = NULL;
	struct pkglist_entry_struct *one_pkglist_entry = NULL;

	struct single_list_item_struct *one_preferred_pkg = NULL;

	struct double_list_item_struct **current_item_final_pkgs = NULL;
	char *new_generic_name_field = NULL;
	char *generic_name_pattern = NULL;

	struct double_list_item_struct *root_item_package_lists_order = NULL;
	struct double_list_item_struct *one_package_list = NULL;

	struct double_list_item_struct *root_item_x_package_lists_order = NULL;
	struct double_list_item_struct *one_x_package_list = NULL;
	struct double_list_item_struct **current_item_x_package_lists_order = NULL;

	struct double_list_item_struct *root_item_x_found_specs = NULL;
	struct double_list_item_struct *one_x_found_spec = NULL;
	struct pkglist_entry_struct *x_found_specs_pkglist = NULL;
	struct double_list_item_struct **current_item_x_found_specs = NULL;

	struct single_list_item_struct *temp1_single_list_item = NULL;
	struct single_list_item_struct *temp2_single_list_item = NULL;
	struct double_list_item_struct *temp1_double_list_item = NULL;
	struct double_list_item_struct *temp2_double_list_item = NULL;

	struct double_list_item_struct *root_item_compiled_ptns = NULL;
	struct double_list_item_struct *one_compiled_ptn = NULL;
	struct double_list_item_struct compat;
	compat.distro = "*";
	compat.release = "*";
	compat.next = NULL;
	struct double_list_item_struct *compat_pointer = &compat;

	FILE *not_found_log;
	FILE *pet_log1;
	FILE *compat_log1;
	FILE *output_log1;
	FILE *final_pkgs;

	if (search_nr == 1)
	{
		pet_log1 = fopen("/tmp/findpkgs_tmp/pet_log1", "w");
		if (pet_log1 == NULL)
		{
			printf("\n/tmp/findpkgs_tmp/pet_log1 could not be opened\n");
			return 1;
		}
		compat_log1 = fopen("/tmp/findpkgs_tmp/compat_log1", "w");
		if (compat_log1 == NULL)
		{
			printf("\n/tmp/findpkgs_tmp/compat_log1 could not be opened\n");
			return 1;
		}
	}
	else if (search_nr == 2)
	{
		final_pkgs = fopen("/tmp/findpkgs_tmp/FINAL_PKGS", "w");
		if (final_pkgs == NULL)
		{
			printf("\n/tmp/findpkgs_tmp/FINAL_PKGS could not be opened\n");
			return 1;
		}

		root_item_final_pkgs = NULL;
		current_item_final_pkgs = &root_item_final_pkgs;

		root_item_preferred_pkgs = NULL;
		read_preferred_pkgs_file();
	}

	one_pkg_spec = strsep(&pkgs_specs_table_pointer, "\n");
	// for ONEPKGSPEC in $PKGS_SPECS_TABLE
	while (one_pkg_spec != NULL)
	{
		// skip empty lines
		if (*one_pkg_spec == '\0')
			goto next_pkg_spec;

		one_pkg_spec_pointer = one_pkg_spec;

		// read YESNO field
		yes_no = strsep(&one_pkg_spec_pointer, "|");
		if (strcasecmp("yes", yes_no) != 0)
			goto next_pkg_spec;

		// read GENERICNAME, not optional
		if (one_pkg_spec_pointer != NULL)
		{
			generic_name = strsep(&one_pkg_spec_pointer, "|");
			if (*generic_name == '\0')
				goto next_pkg_spec;
		}
		else
		{
			goto next_pkg_spec;
		}

		// read BINARYPARTNAMES
		if (one_pkg_spec_pointer != NULL)
		{
			binary_part_names = strsep(&one_pkg_spec_pointer, "|");
		}
		else
		{
			binary_part_names = "\0";
		}

		// skip field FOUR
		if (one_pkg_spec_pointer != NULL)
		{
			strsep(&one_pkg_spec_pointer, "|");
		}

		// read PKGLOCFLD
		if (one_pkg_spec_pointer != NULL)
		{
			pkg_location_field = strsep(&one_pkg_spec_pointer, "|");
			if (*pkg_location_field != '\0')
			{
				pkg_location_field_buffer = strdup(pkg_location_field);
			}
			else
			{
				pkg_location_field_buffer = "\0";
			}
		}
		else
		{
			pkg_location_field = "\0";
			pkg_location_field_buffer = "\0";
		}


		// process binary_part_names (BINARYPARTNAMES)
		current_item_x_binary_part_names = &root_item_x_binary_part_names;
		current_item_binary_excluded = &root_item_binary_excluded;
		pkg_loc1_pointer = "pet";
		pkg_loc2_pointer = NULL;
		if (*binary_part_names == '\0')
		{ // empty BINARYPARTNAMES means pet
			*current_item_x_binary_part_names =
				(struct single_list_item_struct*)
					malloc(sizeof(struct single_list_item_struct));
			(*current_item_x_binary_part_names)->next = NULL;

			(*current_item_x_binary_part_names)->name = generic_name;
		}
		else
		{
			pkg_loc1_pointer = "compat";

			binary_part_names_pointer = binary_part_names;
			while (binary_part_names_pointer != NULL)
			{
				bpart = strsep(&binary_part_names_pointer, ",");

				if (*bpart == '\0')
				{
					; // skip empty binary_part_names
				}
				else if (*bpart == '-')
				{ // process binary_excluded items (BINARYEXCLUDED0)
					*current_item_binary_excluded =
						(struct single_list_item_struct*)
							malloc(sizeof(struct single_list_item_struct));
					(*current_item_binary_excluded)->next = NULL;

					(*current_item_binary_excluded)->name = bpart + 1;

					current_item_binary_excluded =
						&(*current_item_binary_excluded)->next;
				}
				else
				{ // process x_binary_part_names (xBINARYPARTNAMES)
					*current_item_x_binary_part_names =
						(struct single_list_item_struct*)
							malloc(sizeof(struct single_list_item_struct));
					(*current_item_x_binary_part_names)->next = NULL;

					(*current_item_x_binary_part_names)->name = bpart;

					current_item_x_binary_part_names =
						&(*current_item_x_binary_part_names)->next;
				}
			}
		}

		// process pkg_location_field (PKGLOCFLD)
		if (*pkg_location_field_buffer != '\0')
		{
			pkg_location_field_pointer = pkg_location_field_buffer;
			pkg_loc1_pointer = strsep(&pkg_location_field_pointer, ":");
			if (pkg_location_field_pointer != NULL)
			{ // PKGLOC2 was specified
				pkg_loc2_pointer = pkg_location_field_pointer;
			}
			else
			{ // PKGLOC2 was not specified
				pkg_loc2_pointer = NULL;
			}
		}

		// if [ "$PKGLOC1" = "pet" ];then
		if (strcmp("pet", pkg_loc1_pointer) == 0)
		{
			root_item_package_lists_order = root_item_packagelists_pet_order;
			root_item_x_package_lists_order = root_item_packagelists_pet_order;
			root_item_compiled_ptns = root_item_pet_compiled_ptns;
		}
		else
		{
			root_item_package_lists_order = root_item_pkglists_compat;
			root_item_x_package_lists_order = root_item_pkglists_compat;
			root_item_compiled_ptns = compat_pointer;
		} // end if [ "$PKGLOC1" = "pet" ];then


		// if [ "$PKGLOC2" ];then
		if (pkg_loc2_pointer != NULL)
		{
			// use the repo specified by PKGLOC2
			root_item_x_package_lists_order = NULL;
			current_item_x_package_lists_order =
				&root_item_x_package_lists_order;

			// #exs: tahr (3rd field in Packages-puppy-tahr-official)
			pkg_loc2_search_string = malloc(strlen(pkg_loc2_pointer) + 3);
			strcpy(pkg_loc2_search_string, "-");
			strcat(pkg_loc2_search_string, pkg_loc2_pointer);
			strcat(pkg_loc2_search_string, "-");

			// search for specified repo in third field
			one_package_list = root_item_package_lists_order;
			while (one_package_list != NULL)
			{
				if (strstr(one_package_list->list_name,
					pkg_loc2_search_string) != NULL)
				{
					*current_item_x_package_lists_order =
						(struct double_list_item_struct*)
							malloc(sizeof(struct double_list_item_struct));
					one_x_package_list = *current_item_x_package_lists_order;
					one_x_package_list->next = NULL;

					one_x_package_list->list_name =	one_package_list->list_name;

					//printf("\n3rd field %s\n", one_x_package_list->list_name);

					one_x_package_list->list_item = one_package_list->list_item;

					current_item_x_package_lists_order =
						&one_x_package_list->next;
				}

				one_package_list = one_package_list->next;
			}
			free(pkg_loc2_search_string);

			if (root_item_x_package_lists_order == NULL)
			{ // try again, looking for specified repo in fourth field

				// #exs: core, nonfree, contrib, official (4th field in Packages-puppy-wary5-official)
				pkg_loc2_search_string = malloc(strlen(pkg_loc2_pointer) + 2);
				strcpy(pkg_loc2_search_string, "-");
				strcat(pkg_loc2_search_string, pkg_loc2_pointer);

				// search for specified repo in fourth field
				one_package_list = root_item_package_lists_order;
				while (one_package_list != NULL)
				{
					if (strstr(one_package_list->list_name,
						pkg_loc2_search_string) != NULL)
					{
						*current_item_x_package_lists_order =
							(struct double_list_item_struct*)
								malloc(sizeof(struct double_list_item_struct));
						one_x_package_list =
							*current_item_x_package_lists_order;
						one_x_package_list->next = NULL;

						one_x_package_list->list_name =
							one_package_list->list_name;

						//printf("\n4th field %s\n",
						//	one_x_package_list->list_name);

						one_x_package_list->list_item =
							one_package_list->list_item;

						current_item_x_package_lists_order =
							&one_x_package_list->next;
					}

					one_package_list = one_package_list->next;
				}
				free(pkg_loc2_search_string);
			}

		} // end if [ "$PKGLOC2" ];then

///////////////////////////////////////////////////////////////////////////////
		if (is_verbose != 0)
		{
			printf("%s ", generic_name);
			fflush(stdout);
		}
///////////////////////////////////////////////////////////////////////////////

		// for APARTNAME in $xBINARYPARTNAMES
		current_item_x_binary_part_names = &root_item_x_binary_part_names;
		while (*current_item_x_binary_part_names != NULL)
		{
			one_x_binary_part_name = (*current_item_x_binary_part_names)->name;

			look_in_filename = 0;
			// if there is a "*" at the end of
			// one_x_binary_part_name
			if (strcspn(one_x_binary_part_name, "*")
				== strlen(one_x_binary_part_name) - 1)
			{
				look_in_filename = 1;
			}

			// set dev_name (devnamePTN)
			dev_name = malloc(strlen(one_x_binary_part_name) + 5);
			strcpy(dev_name, one_x_binary_part_name);
			strcat(dev_name, "_DEV");

			// if [ "$DEBUG" ] ; then
			if (is_debug == 1)
			{
				printf("\nlook_in_filename=%d\n", look_in_filename);
				printf("namePTN=%s\ndevnamePTN=%s\ncompiledPTNS=",
					one_x_binary_part_name, dev_name);

				one_compiled_ptn = root_item_compiled_ptns;
				while (one_compiled_ptn != NULL)
				{
					printf("|%s|%s| ", one_compiled_ptn->distro,
						one_compiled_ptn->release);

					one_compiled_ptn = one_compiled_ptn->next;
				}

				printf("\nexcludePTNS=");

				one_binary_excluded = root_item_binary_excluded;
				while (one_binary_excluded != NULL)
				{
					printf("%s ", one_binary_excluded->name);

					one_binary_excluded = one_binary_excluded->next;
				}

				printf("\nxPACKAGELISTS_ORDER=");

				one_x_package_list = root_item_x_package_lists_order;
				while (one_x_package_list != NULL)
				{
					printf("%s ", one_x_package_list->list_name);

					one_x_package_list = one_x_package_list->next;
				}
				printf("\n");
			} // end if [ "$DEBUG" ] ; then

			root_item_x_found_specs = NULL;
			current_item_x_found_specs = &root_item_x_found_specs;

			one_compiled_ptn = root_item_compiled_ptns;
			// for acompiledPTN in $compiledPTNS
			while (one_compiled_ptn != NULL)
			{
				// for PKGLIST in $xPACKAGELISTS_ORDER
				one_x_package_list = root_item_x_package_lists_order;
				while (one_x_package_list != NULL)
				{
					//printf("%s ", one_x_package_list->list_name);

					pkg_exists = 0;

					// search for (namePTN)
					one_pkglist_item = one_x_package_list->list_item;
					while (one_pkglist_item != NULL)
					{
						one_pkglist_entry = one_pkglist_item->pkglist_entry;

						// if there is a "*" at the end of
						// one_x_binary_part_name
						if (look_in_filename == 1)
						{
							// compare against pkg_filename
							if (comp_alias(one_x_binary_part_name,
								one_pkglist_entry->pkg_filename) != 0)
									goto next_entry;

							//printf("\n%s\n", one_pkglist_entry->pkg_filename);
						}
						else // there it no "*" at the end of
						{	// one_x_binary_part_name

							// compare against pkg_name_only
							if (comp_alias(one_x_binary_part_name,
								one_pkglist_entry->pkg_name_only) != 0)
									goto next_entry;
						}

						pkg_exists = 1;

						// check pkg_compiled_distro
						if (comp_alias(one_compiled_ptn->distro,
							one_pkglist_entry->pkg_compiled_distro) != 0)
								goto next_entry;

						// check pkg_compiled_release
						if (comp_alias(one_compiled_ptn->release,
							one_pkglist_entry->pkg_compiled_release) != 0)
								goto next_entry;

						// check against excluded_items
						one_binary_excluded = root_item_binary_excluded;
						while (one_binary_excluded != NULL)
						{
							// handle any exclude items based on package name
							if (comp_alias(one_binary_excluded->name,
								one_pkglist_entry->pkg_name_only) == 0)
									goto next_entry;

							// handle any exclude items based on pkg_filename
							if (comp_alias(one_binary_excluded->name,
								one_pkglist_entry->pkg_filename) == 0)
									goto next_entry;

							one_binary_excluded = one_binary_excluded->next;
						}

						// allocate a new x_found_specs_item
						*current_item_x_found_specs =
							(struct double_list_item_struct*)
								malloc(sizeof(struct double_list_item_struct));
						one_x_found_spec = *current_item_x_found_specs;
						one_x_found_spec->next = NULL;

						// save pkglist_entry
						one_x_found_spec->pkglist_entry = one_pkglist_entry;

						// save name of current packagelist
						one_x_found_spec->list_name =
							one_x_package_list->list_name;

						// prepare for next new x_found_specs_item
						current_item_x_found_specs = &one_x_found_spec->next;


						next_entry:
						one_pkglist_item = one_pkglist_item->next;
					}

					if (root_item_x_found_specs == NULL && pkg_exists == 0)
					{
						// if no pkglist_entry was found and
						// no pkglist_entry exists for namePTN regardless of
						// pkg_compiled_distro and pkg_compiled_release
						one_pkglist_item = one_x_package_list->list_item;
						while (one_pkglist_item != NULL)
						{
							one_pkglist_entry = one_pkglist_item->pkglist_entry;

							// try looking for dev_name (devnamePTN) instead
							if (comp_alias(dev_name,
								one_pkglist_entry->pkg_name_only) != 0)
									goto next_entry_dev_search;

							// check pkg_compiled_distro
							if (comp_alias(one_compiled_ptn->distro,
								one_pkglist_entry->pkg_compiled_distro) != 0)
									goto next_entry_dev_search;

							// check pkg_compiled_release
							if (comp_alias(one_compiled_ptn->release,
								one_pkglist_entry->pkg_compiled_release) != 0)
									goto next_entry_dev_search;

							// check against excluded_items
							one_binary_excluded = root_item_binary_excluded;
							while (one_binary_excluded != NULL)
							{
							// handle any exclude items based on package name
								if (comp_alias(one_binary_excluded->name,
									one_pkglist_entry->pkg_name_only) == 0)
										goto next_entry_dev_search;

							// handle any exclude items based on pkg_filename
								if (comp_alias(one_binary_excluded->name,
									one_pkglist_entry->pkg_filename) == 0)
										goto next_entry_dev_search;

								one_binary_excluded = one_binary_excluded->next;
							}

							// allocate a new x_found_specs_item
							*current_item_x_found_specs =
								(struct double_list_item_struct*)
								malloc(sizeof(struct double_list_item_struct));
							one_x_found_spec = *current_item_x_found_specs;
							one_x_found_spec->next = NULL;

							// save pkglist_entry
							one_x_found_spec->pkglist_entry = one_pkglist_entry;

							// save name of current packagelist
							one_x_found_spec->list_name =
								one_x_package_list->list_name;

							// prepare for next new x_found_specs_item
							current_item_x_found_specs =
								&one_x_found_spec->next;


							next_entry_dev_search:
							one_pkglist_item = one_pkglist_item->next;
						}

					} // end if root_item_x_found_specs == NULL

					// #pkg(s) found.
					if (root_item_x_found_specs != NULL)
						goto pkgs_found;


					one_x_package_list = one_x_package_list->next;
				} // end for PKGLIST in $xPACKAGELISTS_ORDER

				one_compiled_ptn = one_compiled_ptn->next;
			} // end for acompiledPTN in $compiledPTNS

			printf("\nWARNING: %s pkg was not found!\n", one_x_binary_part_name);

			not_found_log = fopen("FINDPKGS-NOT-FOUND.log", "a");

			if (not_found_log == NULL)
			{
				printf("\nFINDPKGS-NOT-FOUND.log could not be opened\n");
			}
			else
			{
				fprintf(not_found_log, "WARNING: %s pkg was not found!\n",
					one_x_binary_part_name);
				close_error = fclose(not_found_log);

				if (close_error != 0)
				{
					printf("\nError writing to FINDPKGS-NOT-FOUND.log\n");
				}
			}

			pkgs_found:

			// while read ONESPEC
			one_x_found_spec = root_item_x_found_specs;
			while (one_x_found_spec != NULL)
			{
				x_found_specs_pkglist = one_x_found_spec->pkglist_entry;


				if (search_nr == 1)
				{
					// write output to either /tmp/findpkgs_tmp/pet_log1
					// or /tmp/findpkgs_tmp/compat_log1
					output_log1 = NULL;
					if (strcmp("pet", pkg_loc1_pointer) == 0)
					{
						output_log1 = pet_log1;
					}
					else if (strcmp("compat", pkg_loc1_pointer) == 0)
					{
						output_log1 = compat_log1;
					}

					// copy pkg_dependency_field, do not modify the original...
					dep_buffer =
						strdup(x_found_specs_pkglist->pkg_dependency_field);
					dep_pointer = dep_buffer;
					while (dep_pointer != NULL)
					{ // write one line for each dependency
						one_dep = strsep(&dep_pointer, ", ");

						// remove any leading "+"
						if (*one_dep == '+')
						{
							one_dep++;
						}

						fprintf(output_log1, "%s|%s|%s|%s|%s|%s|%s\n",
							x_found_specs_pkglist->pkg_name_only,
							x_found_specs_pkglist->pkg_version,
							x_found_specs_pkglist->pkg_filename,
							x_found_specs_pkglist->pkg_compiled_distro,
							x_found_specs_pkglist->pkg_compiled_release,
							one_x_found_spec->list_name,
							one_dep);
					}
					free(dep_buffer);
				}
				else if (search_nr == 2)
				{
					if (*pkg_location_field == '\0')
					{ // if no repo has been specified, search preferred_pkgs
						one_preferred_pkg = root_item_preferred_pkgs;
						while (one_preferred_pkg != NULL)
						{ // if a preferred_pkg is found
							if (strcmp(x_found_specs_pkglist->pkg_name_only,
								one_preferred_pkg->pkglist_entry->pkg_name_only)
								== 0)
							{
								// replace x_found_specs_pkglist with it
								x_found_specs_pkglist =
									one_preferred_pkg->pkglist_entry;

								break;
							}

							one_preferred_pkg = one_preferred_pkg->next;
						}
					} // end if (*pkg_location_field == '\0')


					// set name_dev (devnamePTN)
					name_dev = malloc(strlen(
									x_found_specs_pkglist->pkg_name_only) + 5);
					strcpy(name_dev, x_found_specs_pkglist->pkg_name_only);
					strcat(name_dev, "_DEV");

					// set name_doc (docnamePTN)
					name_doc = malloc(strlen(
									x_found_specs_pkglist->pkg_name_only) + 5);
					strcpy(name_doc, x_found_specs_pkglist->pkg_name_only);
					strcat(name_doc, "_DOC");

					// set name_nls (nlsnamePTN)
					name_nls = malloc(strlen(
									x_found_specs_pkglist->pkg_name_only) + 5);
					strcpy(name_nls, x_found_specs_pkglist->pkg_name_only);
					strcat(name_nls, "_NLS");


					// find REPODBFILE

					// search packagelists_pet_order
					one_x_package_list = root_item_packagelists_pet_order;
					while (one_x_package_list != NULL)
					{
						if (strcmp(one_x_found_spec->list_name,
							one_x_package_list->list_name) == 0)
						{
							break;
						}
						one_x_package_list = one_x_package_list->next;
					}
					// if not found search pkglists_compat
					if (one_x_package_list == NULL)
					{
						one_x_package_list = root_item_pkglists_compat;
						while (one_x_package_list != NULL)
						{
							if (strcmp(one_x_found_spec->list_name,
								one_x_package_list->list_name) == 0)
							{
								break;
							}
							one_x_package_list = one_x_package_list->next;
						}
					}
					if (one_x_package_list == NULL)
					{
						printf("\nError: unable to find %s\n",
							one_x_found_spec->list_name);
						return 1;
					}

					// search REPODBFILE
					one_pkglist_item = one_x_package_list->list_item;
					while (one_pkglist_item != NULL)
					{
						one_pkglist_entry = one_pkglist_item->pkglist_entry;

						// check pkg_version
						if (strcmp(x_found_specs_pkglist->pkg_version,
							one_pkglist_entry->pkg_version) != 0)
								goto next_pkglist_item;

						// check pkg_name_only
						if (strcmp(x_found_specs_pkglist->pkg_name_only,
							one_pkglist_entry->pkg_name_only) == 0)
						{
							one_name_ptn = x_found_specs_pkglist->pkg_name_only;
						}
						else if (strcmp(name_dev,
								one_pkglist_entry->pkg_name_only) == 0)
						{
							one_name_ptn = name_dev;
						}
						else if (strcmp(name_doc,
								one_pkglist_entry->pkg_name_only) == 0)
						{
							one_name_ptn = name_doc;
						}
						else if (strcmp(name_nls,
								one_pkglist_entry->pkg_name_only) == 0)
						{
							one_name_ptn = name_nls;
						}
						else
						{
							goto next_pkglist_item;
						}


						// search for existing entry
						current_item_final_pkgs = &root_item_final_pkgs;
						while (*current_item_final_pkgs != NULL)
						{	// check pkg_name_only
							if (strcmp(one_name_ptn, (*current_item_final_pkgs)
								->pkglist_entry->pkg_name_only) != 0)
									goto next_final_pkgs_item;

							if (*pkg_location_field != '\0')
							{
								if (strcmp(one_x_found_spec->list_name,
									(*current_item_final_pkgs)->extra_fields
									->repo_db_file) != 0)
										goto next_final_pkgs_item;
							}
							// found existing entry
							break;

							next_final_pkgs_item:
							current_item_final_pkgs =
								&(*current_item_final_pkgs)->next;
						}


						if (*current_item_final_pkgs == NULL)
						{
							// allocate a new current_item_final_pkgs
							*current_item_final_pkgs =
								(struct double_list_item_struct*)
								malloc(sizeof(struct double_list_item_struct));
							(*current_item_final_pkgs)->next = NULL;

							// allocate a new extra_fields item
							(*current_item_final_pkgs)->extra_fields =
								(struct final_pkgs_extra_fields_struct*)
								malloc(sizeof(
								struct final_pkgs_extra_fields_struct));

							// save GENERICNAME
							new_generic_name_field =
								malloc(strlen(generic_name) + 3);

							strcpy(new_generic_name_field, ":");
							strcat(new_generic_name_field, generic_name);
							strcat(new_generic_name_field, ":");
							(*current_item_final_pkgs)->extra_fields
								->generic_name_field = new_generic_name_field;

							// save PKGLOC1
							(*current_item_final_pkgs)->extra_fields->pkg_loc1
								= malloc(strlen(pkg_loc1_pointer) + 1);
							strcpy((*current_item_final_pkgs)->extra_fields
								->pkg_loc1, pkg_loc1_pointer);

							// save REPODBFILE
							(*current_item_final_pkgs)->extra_fields
								->repo_db_file = malloc(strlen(
								one_x_found_spec->list_name) + 1);
							strcpy((*current_item_final_pkgs)
								->extra_fields->repo_db_file,
								one_x_found_spec->list_name);

							// save FULLDBENTRY
							(*current_item_final_pkgs)->pkglist_entry =
								one_pkglist_entry;
						}
						else
						{
							generic_name_pattern =
								malloc(strlen(generic_name) + 3);

							strcpy(generic_name_pattern, ":");
							strcat(generic_name_pattern, generic_name);
							strcat(generic_name_pattern, ":");


							// look for ":GENERICNAME:" in generic_name_field
							if (strstr((*current_item_final_pkgs)->extra_fields
								->generic_name_field, generic_name_pattern)
								== NULL)
							{
								new_generic_name_field = malloc(
									strlen((*current_item_final_pkgs)
									->extra_fields->generic_name_field) +
									strlen(generic_name) + 3);

								strcpy(new_generic_name_field, ":");
								strcat(new_generic_name_field, generic_name);
								strcat(new_generic_name_field, ":");
								strcat(new_generic_name_field,
									(*current_item_final_pkgs)
									->extra_fields->generic_name_field);

								free((*current_item_final_pkgs)->extra_fields
									->generic_name_field);

								(*current_item_final_pkgs)->extra_fields
									->generic_name_field =
									new_generic_name_field;
							}
							free(generic_name_pattern);
						}

						next_pkglist_item:
						one_pkglist_item = one_pkglist_item->next;
					} // end while (one_pkglist_item != NULL)

					free(name_dev);
					free(name_doc);
					free(name_nls);
				} // end else if (search_nr == 2)

				one_x_found_spec = one_x_found_spec->next;
			} // end while read ONESPEC

			// free x_found_specs
			temp1_double_list_item = root_item_x_found_specs;
			while (temp1_double_list_item != NULL)
			{
				temp2_double_list_item = temp1_double_list_item->next;
				free(temp1_double_list_item);
				temp1_double_list_item = temp2_double_list_item;
			}
			root_item_x_found_specs = NULL;

			free(dev_name);

			current_item_x_binary_part_names =
				&(*current_item_x_binary_part_names)->next;
		} // end for APARTNAME in $xBINARYPARTNAMES

///////////////////////////////////////////////////////////////////////////////

		if (root_item_x_package_lists_order != root_item_pkglists_compat &&
			root_item_x_package_lists_order != root_item_packagelists_pet_order)
		{
			temp1_double_list_item = root_item_x_package_lists_order;
			while (temp1_double_list_item != NULL)
			{
				//printf("%s ", temp1_double_list_item->list_name);
				temp2_double_list_item = temp1_double_list_item->next;
				free(temp1_double_list_item);
				temp1_double_list_item = temp2_double_list_item;
			}
			root_item_x_package_lists_order = NULL;
		}

		//printf("\nbinary_part_names ");
		temp1_single_list_item = root_item_x_binary_part_names;
		while (temp1_single_list_item != NULL)
		{
			//printf("%s ", temp1_single_list_item->name);
			temp2_single_list_item = temp1_single_list_item->next;
			free(temp1_single_list_item);
			temp1_single_list_item = temp2_single_list_item;
		}
		root_item_x_binary_part_names = NULL;

		//printf("\nbinary_excluded ");
		temp1_single_list_item = root_item_binary_excluded;
		while (temp1_single_list_item != NULL)
		{
			//printf("%s ", temp1_single_list_item->name);
			temp2_single_list_item = temp1_single_list_item->next;
			free(temp1_single_list_item);
			temp1_single_list_item = temp2_single_list_item;
		}
		root_item_binary_excluded = NULL;
/*
		printf("\npkg_loc1_pointer=%s ", pkg_loc1_pointer);
		if (pkg_loc2_pointer != NULL)
		{
			printf("\npkg_loc2_pointer=%s ", pkg_loc2_pointer);
		}
*/
		if (*pkg_location_field_buffer != '\0')
		{
			free(pkg_location_field_buffer);
		}

		next_pkg_spec:
		one_pkg_spec = strsep(&pkgs_specs_table_pointer, "\n");
	} // end for ONEPKGSPEC in $PKGS_SPECS_TABLE

	if (search_nr == 1)
	{
		close_error = fclose(pet_log1);
		if (close_error != 0)
		{
			printf("\nError writing /tmp/findpkgs_tmp/pet_log1\n");
		}
		close_error = fclose(compat_log1);
		if (close_error != 0)
		{
			printf("\nError writing /tmp/findpkgs_tmp/compat_log1\n");
		}
	}
	else if (search_nr == 2)
	{
		close_error = fclose(final_pkgs);
		if (close_error != 0)
		{
			printf("\nError writing /tmp/findpkgs_tmp/FINAL_PKGS\n");
		}
	}

return 0;
}

int main(int argc, char **argv)
{
	int i;
	int search_nr = 1;

	char *packagelists_pet_order_buffef = NULL;
	char *packagelists_pet_order_pointer = NULL;
	struct double_list_item_struct **current_item_packagelists_pet_order = NULL;

	char *pkglists_compat_buffef = NULL;
	char *pkglists_compat_pointer = NULL;
	struct double_list_item_struct **current_item_pkglists_compat = NULL;

	char *pkgs_specs_table_buffer = NULL;

	char *petcompiled_ptns_buffef = NULL;
	char *petcompiled_ptns_pointer = NULL;
	char *ptn_pointer = NULL;
	struct double_list_item_struct **current_item_petcompiled_ptns = NULL;

	char *debug_buffer = NULL;
	char *debug_pointer = NULL;

	struct single_list_item_struct *temp1_single_list_item = NULL;
	struct single_list_item_struct *temp2_single_list_item = NULL;
	struct double_list_item_struct *temp1_double_list_item = NULL;
	struct double_list_item_struct *temp2_double_list_item = NULL;

	is_verbose = 0;

	root_item_packagelists_pet_order = NULL;
	root_item_pkglists_compat = NULL;
	root_item_pet_compiled_ptns = NULL;
	pkgs_specs_table = NULL;

	current_item_packagelists_pet_order = &root_item_packagelists_pet_order;
	current_item_pkglists_compat = &root_item_pkglists_compat;
	current_item_petcompiled_ptns = &root_item_pet_compiled_ptns;

	// process command line args
	for (i = 1; i < argc; i++)
	{
		if (strncmp("--packagelists-pet-order", argv[i], 24) == 0)
		{
			if (strncmp("--packagelists-pet-order=", argv[i], 25) == 0)
			{
				// if the argument is attached,
				// trim off the "--packagelists-pet-order=" part
				packagelists_pet_order_buffef = strdup(argv[i]);
				packagelists_pet_order_pointer = packagelists_pet_order_buffef;
				strsep(&packagelists_pet_order_pointer, "=");

				if (packagelists_pet_order_pointer == NULL
					|| *packagelists_pet_order_pointer == '\0')
				{
					printf("Error: Missing argument to --packagelists-pet-order\n");
					return 1;
				}
			}
			else
			{
				// otherwise use the next argument
				i++;
				if (i < argc)
				{
					packagelists_pet_order_buffef = strdup(argv[i]);
					packagelists_pet_order_pointer =
						packagelists_pet_order_buffef;
				}
				else
				{
					printf("Error: Missing argument to --packagelists-pet-order\n");
					return 1;
				}
			}


			while (packagelists_pet_order_pointer != NULL
					&& *packagelists_pet_order_pointer != '\0')
			{
				// allocate a new packagelists_pet_order item
				*current_item_packagelists_pet_order =
					(struct double_list_item_struct*)
					malloc(sizeof(struct double_list_item_struct));
				(*current_item_packagelists_pet_order)->next = NULL;
				(*current_item_packagelists_pet_order)->list_item = NULL;

				// save the packagelist name
				(*current_item_packagelists_pet_order)->list_name =
					strsep(&packagelists_pet_order_pointer, " ");

				current_item_packagelists_pet_order =
					&(*current_item_packagelists_pet_order)->next;
			}


			current_item_packagelists_pet_order =
				&root_item_packagelists_pet_order;
			while (*current_item_packagelists_pet_order != NULL)
			{
				read_one_file((*current_item_packagelists_pet_order)->list_name,
					&(*current_item_packagelists_pet_order)->list_item);

				current_item_packagelists_pet_order =
					&(*current_item_packagelists_pet_order)->next;
			}


		}
		else if (strncmp("--pkglists-compat", argv[i], 17) == 0)
		{
			if (strncmp("--pkglists-compat=", argv[i], 18) == 0)
			{
				// if the argument is attached,
				// trim off the "--pkglists-compat=" part
				pkglists_compat_buffef = strdup(argv[i]);
				pkglists_compat_pointer = pkglists_compat_buffef;
				strsep(&pkglists_compat_pointer, "=");

				if (pkglists_compat_pointer == NULL
					|| *pkglists_compat_pointer == '\0')
				{
					printf("Error: Missing argument to --pkglists-compat\n");
					return 1;
				}
			}
			else
			{
				// otherwise use the next argument
				i++;
				if (i < argc)
				{
					pkglists_compat_buffef = strdup(argv[i]);
					pkglists_compat_pointer = pkglists_compat_buffef;
				}
				else
				{
					printf("Error: Missing argument to --pkglists-compat\n");
					return 1;
				}
			}


			while (pkglists_compat_pointer != NULL
					&& *pkglists_compat_pointer != '\0')
			{
				// allocate a new pkglists_compat item
				*current_item_pkglists_compat =
					(struct double_list_item_struct*)
					malloc(sizeof(struct double_list_item_struct));
				(*current_item_pkglists_compat)->next = NULL;
				(*current_item_pkglists_compat)->list_item = NULL;

				// save the packagelist name
				(*current_item_pkglists_compat)->list_name =
					strsep(&pkglists_compat_pointer, " ");

				current_item_pkglists_compat =
					&(*current_item_pkglists_compat)->next;
			}


			current_item_pkglists_compat = &root_item_pkglists_compat;
			while (*current_item_pkglists_compat != NULL)
			{
				read_one_file((*current_item_pkglists_compat)->list_name,
					&(*current_item_pkglists_compat)->list_item);

				current_item_pkglists_compat =
					&(*current_item_pkglists_compat)->next;
			}


		}
		else if (strncmp("--pkgs-specs-table", argv[i], 18) == 0)
		{
			if (strncmp("--pkgs-specs-table=", argv[i], 19) == 0)
			{
				// if the argument is attached,
				// trim off the "--pkgs-specs-table=" part
				pkgs_specs_table_buffer = strdup(argv[i]);
				pkgs_specs_table = pkgs_specs_table_buffer;
				strsep(&pkgs_specs_table, "=");

				if (pkgs_specs_table == NULL || *pkgs_specs_table == '\0')
				{
					printf("Error: Missing argument to --pkgs-specs-table\n");
					return 1;
				}
			}
			else
			{
				// otherwise use the next argument
				i++;
				if (i < argc)
				{
					pkgs_specs_table_buffer = strdup(argv[i]);
					pkgs_specs_table = pkgs_specs_table_buffer;
				}
				else
				{
					printf("Error: Missing argument to --pkgs-specs-table\n");
					return 1;
				}
			}
		}
		else if (strncmp("--petcompiledPTNS", argv[i], 17) == 0)
		{
			if (strncmp("--petcompiledPTNS=", argv[i], 18) == 0)
			{
				// if the argument is attached,
				// trim off the "--petcompiledPTNS=" part
				petcompiled_ptns_buffef = strdup(argv[i]);
				petcompiled_ptns_pointer = petcompiled_ptns_buffef;
				strsep(&petcompiled_ptns_pointer, "=");

				if (petcompiled_ptns_pointer == NULL
					|| *petcompiled_ptns_pointer == '\0')
				{
					printf("Error: Missing argument to --petcompiledPTNS\n");
					return 1;
				}
			}
			else
			{
				// otherwise use the next argument
				i++;
				if (i < argc)
				{
					petcompiled_ptns_buffef = strdup(argv[i]);
					petcompiled_ptns_pointer = petcompiled_ptns_buffef;
				}
				else
				{
					printf("Error: Missing argument to --petcompiledPTNS\n");
					return 1;
				}
			}


			while (petcompiled_ptns_pointer != NULL
					&& *petcompiled_ptns_pointer != '\0')
			{
				// allocate a new petcompiled_ptns item
				*current_item_petcompiled_ptns =
					(struct double_list_item_struct*)
					malloc(sizeof(struct double_list_item_struct));
				(*current_item_petcompiled_ptns)->next = NULL;

				ptn_pointer = strsep(&petcompiled_ptns_pointer, " ");
				// patterns start with "|", get rid of it
				strsep(&ptn_pointer, "|");

				// save the distro name
				if (ptn_pointer != NULL && *ptn_pointer != '\0')
				{
					(*current_item_petcompiled_ptns)->distro =
						strsep(&ptn_pointer, "|");
				}
				else
				{
					(*current_item_petcompiled_ptns)->distro = "*";
				}

				// save the release name
				if (ptn_pointer != NULL && *ptn_pointer != '\0')
				{
					(*current_item_petcompiled_ptns)->release =
						strsep(&ptn_pointer, "|");
				}
				else
				{
					(*current_item_petcompiled_ptns)->release = "*";
				}

				current_item_petcompiled_ptns =
					&(*current_item_petcompiled_ptns)->next;
			}
		}
		else if (strcmp("--verbose", argv[i]) == 0
				|| strcmp("-v", argv[i]) == 0)
		{
			is_verbose = 1;
		}
		else if (strncmp("--debug", argv[i], 7) == 0)
		{
			if (strncmp("--debug=", argv[i], 8) == 0)
			{
				// if there is an argument attached,
				// trim off the "--debug=" part
				debug_buffer = strdup(argv[i]);
				debug_pointer = debug_buffer;
				strsep(&debug_pointer, "=");

				// a missing argument means no debug
				if (debug_pointer != NULL
					&& *debug_pointer != '\0'
					&& *debug_pointer != '0'
					&& strcasecmp("no", debug_pointer) != 0)
				{
					is_debug = 1;
				}
			}
			else
			{
				// --debug with no "="
				is_debug = 1;
			}
		}
		else
		{
			if (strcmp("2", argv[i]) == 0)
			{
				search_nr = 2;
			}

			if (strcmp("1", argv[i]) != 0 && strcmp("2", argv[i]) != 0)
			{
				printf("Error: Unrecognized argument %s\n", argv[i]);
				return 1;
			}
		}
	}


	if (root_item_packagelists_pet_order == NULL
		|| root_item_pkglists_compat == NULL
		|| pkgs_specs_table == NULL
		|| root_item_pet_compiled_ptns == NULL)
	{
		printf("Usage: findpkgs-search-helper \
--packagelists-pet-order=\"$PACKAGELISTS_PET_ORDER\" \
--pkglists-compat=\"$PKGLISTS_COMPAT\" \
--pkgs-specs-table=\"$PKGS_SPECS_TABLE\" \
--petcompiledPTNS=\"$petcompiledPTNS\" \
[-v | --verbose] [ --debug | --debug=<yes,1|no,0>] [<search num>]\n");
		return 1;
	}

	search_func(search_nr);
	write_final_pkgs_file();


	free(pkgs_specs_table_buffer);

	// free pet_compiled_ptns
	temp1_double_list_item = root_item_pet_compiled_ptns;
	while (temp1_double_list_item != NULL)
	{
		//printf("|%s|%s| ", temp1_double_list_item->distro,
		//					temp1_double_list_item->release);

		temp2_double_list_item = temp1_double_list_item->next;
		free(temp1_double_list_item);
		temp1_double_list_item = temp2_double_list_item;
	}
	free(petcompiled_ptns_buffef);

	// free preferred_pkgs
	temp1_single_list_item = root_item_preferred_pkgs;
	while (temp1_single_list_item != NULL)
	{
		free(temp1_single_list_item->pkglist_entry->mem_buffer);
		free(temp1_single_list_item->pkglist_entry);

		temp2_single_list_item = temp1_single_list_item->next;
		free(temp1_single_list_item);
		temp1_single_list_item = temp2_single_list_item;
	}

	// free pkglists_compat
	temp1_double_list_item = root_item_pkglists_compat;
	while (temp1_double_list_item != NULL)
	{
		temp1_single_list_item = temp1_double_list_item->list_item;
		while (temp1_single_list_item != NULL)
		{
			free(temp1_single_list_item->pkglist_entry->mem_buffer);
			free(temp1_single_list_item->pkglist_entry);
			temp2_single_list_item = temp1_single_list_item->next;
			free(temp1_single_list_item);
			temp1_single_list_item = temp2_single_list_item;
		}
		temp2_double_list_item = temp1_double_list_item->next;
		free(temp1_double_list_item);
		temp1_double_list_item = temp2_double_list_item;
	}
	free(pkglists_compat_buffef);

	// free packagelists_pet_order
	temp1_double_list_item = root_item_packagelists_pet_order;
	while (temp1_double_list_item != NULL)
	{
		temp1_single_list_item = temp1_double_list_item->list_item;
		while (temp1_single_list_item != NULL)
		{
			free(temp1_single_list_item->pkglist_entry->mem_buffer);
			free(temp1_single_list_item->pkglist_entry);
			temp2_single_list_item = temp1_single_list_item->next;
			free(temp1_single_list_item);
			temp1_single_list_item = temp2_single_list_item;
		}
		temp2_double_list_item = temp1_double_list_item->next;
		free(temp1_double_list_item);
		temp1_double_list_item = temp2_double_list_item;
	}
	free(packagelists_pet_order_buffef);

	// free final_pkgs
	temp1_double_list_item = root_item_final_pkgs;
	while (temp1_double_list_item != NULL)
	{
		free(temp1_double_list_item->extra_fields->generic_name_field);
		free(temp1_double_list_item->extra_fields->pkg_loc1);
		free(temp1_double_list_item->extra_fields->repo_db_file);
		free(temp1_double_list_item->extra_fields);

		// pkglist_entry already freed

		temp2_double_list_item = temp1_double_list_item->next;
		free(temp1_double_list_item);
		temp1_double_list_item = temp2_double_list_item;
	}


return 0;
}
