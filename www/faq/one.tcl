# /faq/one.tcl
# 
# dh@arsdigita.com, December 1999
# 
# displays the FAQ
#
# Note: if page is accessed through /groups pages then group_id and group_vars_set are already set up in 
#       the environment by the ug_serve_section. group_vars_set contains group related variables (group_id, 
#       group_name, group_short_name, group_admin_email, group_public_url, group_admin_url, group_public_root_url,
#       group_admin_root_url, group_type_url_p, group_context_bar_list and group_navbar_list)
#
# $Id: one.tcl,v 3.1.2.1 2000/03/15 20:16:23 aure Exp $

set_the_usual_form_variables
# faq_id
# maybe scope, maybe scope related variables (group_id)

ad_scope_error_check

set db [ns_db gethandle]

# check that this user can see the faq --------------
faq_authorize $db $faq_id

# check if the user can maintain this faq and generate appropriate maintainers url --------
if { [faq_maintaner_p $db $faq_id] } {

    if { $scope == "public" } {
	set admin_url "/faq/admin"
    } else {
	set short_name [database_to_tcl_string $db "select short_name
                                                    from user_groups
                                                     where group_id = $group_id"] 
	set admin_url "/[ad_parameter GroupsDirectory ug]/[ad_parameter GroupsAdminDirectory ug]/[ad_urlencode $short_name]/faq"
    }
   
    append helper_args [list "$admin_url/one?[export_url_vars faq_id]" "Maintain this FAQ"]
} else {
    # user is not authorized to mantain this faq
    set helper_args ""
}

# get the faq_name ----------------------------------
set faq_name [database_to_tcl_string $db "
select faq_name
from faqs 
where faq_id = $faq_id"]

# get the faq from the database
set selection [ns_db select $db "
select question, 
       answer,
       entry_id,
       sort_key
from   faq_q_and_a 
where  faq_id = $faq_id
order by sort_key"]

set q_and_a_list ""
set q_list ""
set question_number 0
while {[ns_db getrow $db $selection]} {
    set_variables_after_query
    incr question_number
    append q_list "<li><a href=#$question_number>$question</a>\n"
    append q_and_a_list "
   <li><a name=$question_number></a>
       <b>Q: </b><i>$question</i><p>
       <b>A: </b>$answer<p><br><p>"
}


# --serve the page ----------
append html "
[ad_scope_header $faq_name $db]
[ad_scope_page_title $faq_name $db]
[ad_scope_context_bar_ws_or_index [list "index?[export_url_scope_vars]" "FAQs"] "One FAQ"]

<hr>
[help_upper_right_menu $helper_args]
[ad_scope_navbar]
<p>
"

if {![empty_string_p $q_list] } {
    append html "
    Frequently Asked Questions:
    <ol>
    $q_list
    </ol>
    <hr>
    "
    if {![empty_string_p $q_and_a_list] } {
	append html "
	Questions and Answers:
	<ol>
	$q_and_a_list
	</ol>
	<p>
	"    }
} else {
    append html "
    <p>
    No Questions/Answers available
    <p>" 
}

append html "

[ad_scope_footer]"

ns_db releasehandle $db

ns_return 200 text/html $html

