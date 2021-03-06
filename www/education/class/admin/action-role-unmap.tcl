#
# /www/education/class/admin/action-role-unmap.tcl
#
# this page unmaps a role from an action
# 
# by randyg@arsdigita.com, aileen@mit.edu, January 2000
#


ad_page_variables {
    role
    action
    group_id
}

set db [ns_db gethandle]

set id_list [edu_group_security_check $db edu_class "Edit Permissions"]
set user_id [lindex $id_list 0]
set class_id [lindex $id_list 1]

# make sure the group_id = class_id

if {[string compare $group_id $class_id] != 0} {
    ad_return_complaint 1 "<li>You can only change the action role mappings for the class you are currently logged in as."
    return
}

ns_db dml $db "delete from 
user_group_action_role_map
where group_id = $group_id 
and role = '$QQrole' and action = '$QQaction'"

ns_db releasehandle $db

ad_returnredirect permissions.tcl

