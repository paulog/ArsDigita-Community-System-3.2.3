# $Id: comment-edit-2.tcl,v 3.0 2000/02/06 03:49:41 ron Exp $
if {[ad_read_only_p]} {
    ad_return_read_only_maintenance_message
    return
}

set_form_variables

# comment_id

# check for bad input
if  {![info exists content] || [empty_string_p $content] } { 
    ad_return_complaint 1 "<li>the comment field was empty"
    return
}


set db [ns_db gethandle]
set user_id [ad_verify_and_get_user_id]

set selection [ns_db 1row $db "select about || ' : ' || title as title, neighbor_to_neighbor_id, general_comments.user_id as comment_user_id
from neighbor_to_neighbor n, general_comments
where comment_id = $comment_id
and n.neighbor_to_neighbor_id = general_comments.on_what_id"]
set_variables_after_query

# check to see if ther user was the orginal poster
if {$user_id != $comment_user_id} {
    ad_return_complaint 1 "<li>You can not edit this entry because you did not post it"
    return
}

ReturnHeaders

ns_write "[ad_header "Verify comment on <i>$title</i>" ]

<h2>Verify comment</h2>
on <A HREF=\"view-one.tcl?[export_url_vars neighbor_to_neighbor_id]\">$title</A>
<hr>

The following is your comment as it would appear on the story
<i>$title</i>.  If it looks incorrect, please use the back button on
your browser to return and correct it.  Otherwise, press \"Continue\".
<p>

<blockquote>"


if { [info exists html_p] && $html_p == "t" } {
    ns_write "$content
</blockquote>
Note: if the story has lost all of its paragraph breaks then you
probably should have selected \"Plain Text\" rather than HTML.  Use
your browser's Back button to return to the submission form.
"
} else {
    ns_write "[util_convert_plaintext_to_html $content]
</blockquote>

Note: if the story has a bunch of visible HTML tags then you probably
should have selected \"HTML\" rather than \"Plain Text\".  Use your
browser's Back button to return to the submission form.  " 
}

ns_write "<center>
<form action=comment-edit-3.tcl method=post>
<input type=submit name=submit value=\"Continue\">
[export_form_vars comment_id content html_p]
</center>
</form>
[ad_footer]
"
