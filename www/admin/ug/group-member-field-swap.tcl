# $Id: group-member-field-swap.tcl,v 3.0.4.1 2000/04/28 15:09:28 carsten Exp $
# Swaps two sort keys for group_id, sort_key and sort_key + 1.

set_the_usual_form_variables
# group_id, sort_key

set db [ns_db gethandle]

set next_sort_key [expr $sort_key + 1]

with_catch errmsg {
    ns_db dml $db "update user_group_member_fields
set sort_key = decode(sort_key, $sort_key, $next_sort_key, $next_sort_key, $sort_key)
where group_id = $group_id
and sort_key in ($sort_key, $next_sort_key)"

    ad_returnredirect "group.tcl?group_id=$group_id"
} {
    ad_return_error "Database error" "A database error occured while trying
to swap your user group fields. Here's the error:
<pre>
$errmsg
</pre>
"
}