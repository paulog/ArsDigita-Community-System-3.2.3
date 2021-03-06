# $Id: category-new.tcl,v 3.0.4.1 2000/04/28 15:09:49 carsten Exp $
# File:     /calendar/admin/category-new.tcl
# Date:     1998-11-18
# Contact:  philg@mit.edu, ahmeds@arsdigita.com
# Purpose:  creates new caegory
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)

set_the_usual_form_variables 0
# category_new , category_id
# maybe scope, maybe scope related variables (user_id, group_id, on_which_group, on_what_id)

ad_scope_error_check
set db [ns_db gethandle]
ad_scope_authorize $db $scope admin group_admin none

set exception_count 0
set exception_text ""

if { ![info exists category_new] || [empty_string_p $category_new] } {
    incr exception_count
    append exception_text "<li>Please enter a category."
}


set category_exists_p [database_to_tcl_string $db "
select count(*)
from calendar_categories
where category = '$QQcategory_new'
and [ad_scope_sql] "]

if { $category_exists_p } {
    incr exception_count
    append exception_text "<li>Category $QQcategory_new already exists. Please enter a new category."
}

if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

if [catch {
    # add the new category
    ns_db dml $db "
    insert into calendar_categories 
    (category_id, category, [ad_scope_cols_sql]) 
    values
    ($category_id,'$QQcategory_new', [ad_scope_vals_sql])" 

} errmsg] {

    # there was some other error with the category
    ad_scope_return_error "Error inserting category" "We couldn't insert your category. Here is what the database returned:
<p>
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
" $db
return
}


ad_returnredirect "category-one.tcl?[export_url_scope_vars]&category_id=[ns_urlencode $category_id]"

