#
# /www/news/admin/post-edit-2.tcl
#
# process the edit form for the news item
#
# Author: jkoontz@arsdigita.com March 8, 2000
#
# $Id: post-edit-2.tcl,v 3.1.2.2 2000/04/28 15:11:15 carsten Exp $

# Note: if page is accessed through /groups pages then group_id and 
# group_vars_set are already set up in the environment by the 
# ug_serve_section. group_vars_set contains group related variables
# (group_id, group_name, group_short_name, group_admin_email, 
# group_public_url, group_admin_url, group_public_root_url,
# group_admin_root_url, group_type_url_p, group_context_bar_list and
# group_navbar_list)

set_the_usual_form_variables
# maybe scope, maybe scope related variables (public, group_id)
# maybe return_url, name
# news_item_id, title, body, html_p, AOLserver ns_db magic vars that can be 
# kludged together to form release_date and expiration_date

ad_scope_error_check
set db [ns_db gethandle]
set user_id [news_admin_authorize $db $news_item_id]

set exception_count 0
set exception_text ""

if [catch  {
    ns_dbformvalue [ns_conn form] release_date date release_date
    ns_dbformvalue [ns_conn form] expiration_date date expiration_date} errmsg] {
    incr exception_count
    append exception_text "<li>Please make sure your dates are valid."
} else {

    set expire_laterthan_future_p [database_to_tcl_string $db "select to_date('$expiration_date', 'yyyy-mm-dd')  - to_date('$release_date', 'yyyy-mm-dd')  from dual"]
    if {$expire_laterthan_future_p <= 0} {
	incr exception_count
	append exception_text "<li>Please make sure the expiration date is later than the release date."
    }
}

# now release_date and expiration_date are set

if { ![info exists title] || [empty_string_p $title] } {
    incr exception_count
    append exception_text "<li>Please enter a title."
}

if { ![info exists body] || [empty_string_p $body] } {
    incr exception_count
    append exception_text "<li>Please enter the full story."
}

if {$exception_count > 0} { 
    ad_scope_return_complaint $exception_count $exception_text $db
    return
}

set update_sql "update news_items
set title='$QQtitle', body = empty_clob(), 
html_p='$html_p', release_date='$release_date',
approval_state = 'approved', approval_date = sysdate,
approval_user = $user_id, approval_ip_address = '[DoubleApos [ns_conn peeraddr]]',
expiration_date='$expiration_date' 
where news_item_id = $news_item_id 
returning body into :one"

if [catch { ns_ora clob_dml $db $update_sql $body } errmsg] {
    #  update failed
    ns_log Error "/news/admin/post-edit-2.tcl choked:  $errmsg"
    ad_scope_return_error "Insert Failed" "The Database did not like what you typed.  This is probably a bug in our code.  Here's what the database said:
<blockquote>
<pre>
$errmsg
</pre>
</blockquote>
" $db
   return
}

ad_returnredirect item.tcl?[export_url_scope_vars news_item_id]
