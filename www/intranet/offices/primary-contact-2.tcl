# $Id: primary-contact-2.tcl,v 3.0.4.2 2000/04/28 15:11:08 carsten Exp $
# File: /www/intranet/offices/primary-contact-2.tcl
#
# Author: mbryzek@arsdigita.com, Jan 2000
#
# stores primary contact id for the office
#

set user_id [ad_verify_and_get_user_id]
ad_maybe_redirect_for_registration

set_form_variables
# group_id, user_id_from_search

set db [ns_db gethandle]

ns_db dml $db \
	"update im_offices 
            set contact_person_id=$user_id_from_search
          where group_id=$group_id"

ns_db releasehandle $db


ad_returnredirect view.tcl?[export_url_vars group_id]