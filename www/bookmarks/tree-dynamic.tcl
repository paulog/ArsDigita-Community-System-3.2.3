# $Id: tree-dynamic.tcl,v 3.0 2000/02/06 03:35:43 ron Exp $
# tree-dynamic.tcl
#
# Javascript tree data builder
#
# by aure@arsdigita.com


set user_id [ad_verify_and_get_user_id]

# time
# we get this time variable only so that certain browser (internet explorer, for instance)
# will not try to cache this page

# get generic display parameters from the .ini file
set folder_decoration [ad_parameter FolderDecoration bm]
set hidden_decoration [ad_parameter HiddenDecoration bm]
set dead_decoration [ad_parameter DeadDecoration bm]

set db [ns_db gethandle]

set name_query "select first_names||' '||last_name as name 
               from   users 
               where  user_id=$user_id"
set name [database_to_tcl_string $db $name_query]

append js "
USETEXTLINKS = 1
aux0 = gFld(\"Bookmarks for $name\",\"<b>\")
"


set sql_query "
        select   bookmark_id, bm_list.url_id, 
                 local_title, hidden_p, 
                 last_live_date, last_checked_date,
                 parent_id, complete_url, folder_p
        from     bm_list, bm_urls
        where    owner_id=$user_id
        and      bm_list.url_id=bm_urls.url_id(+)
        order by parent_sort_key || local_sort_key
        "

set selection [ns_db select $db $sql_query]
set bookmark_count 0
set bookmark_html ""
set folder_list 0

while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr bookmark_count

    # decoration refers to color and font of the associated text
    set decoration ""

    # make private links appear as definied in the .ini file
    if {$hidden_p=="t"} {
	append decoration $hidden_decoration
    }

    # make dead links appear  as definied in the .ini file
    if {$last_checked_date!=$last_live_date} {
	append decoration $dead_decoration
    }
    
    # make folder titles appear  as definied in the .ini file
    if {$folder_p=="t"} {
	append decoration $folder_decoration
    }

    # javascript version requires the top folder to have id "0"
    if [empty_string_p $parent_id] {
	set parent_id 0
    }

    if {$folder_p=="t"} {
	append js "aux$bookmark_id = insFld(aux$parent_id, gFld(\"[philg_quote_double_quotes [string trim $local_title]]\", \"$decoration\", $bookmark_id))\n"
    } else {
	append js "aux$bookmark_id = insDoc(aux$parent_id, gLnk(1, \"[philg_quote_double_quotes [string trim $local_title]]\",\"[string trim [philg_quote_double_quotes $complete_url]]\",\"$decoration\", $bookmark_id))\n"
    }
}


ns_return 200 text/html "$js"




