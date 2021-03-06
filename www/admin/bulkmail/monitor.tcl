ns_share bulkmail_instances_mutex
ns_share bulkmail_instances
ns_share bulkmail_threads_spawned
ns_share bulkmail_threads_completed
ns_share bulkmail_db_flush_queue
ns_share bulkmail_db_flush_wait_event_mutex
ns_share bulkmail_db_flush_wait_event

ReturnHeaders

ns_write "[ad_header "Bulkmail Monitor"]

<h2>Bulkmail Monitor</h2>

[ad_context_bar [list "/pvtm/" "Your Workspace"] "Bulkmail Monitor"]

<hr>
"

if { [ad_parameter BulkmailActiveP bulkmail 0] == 0 } {
    ns_write "The bulkmail system has not been enabled/initialized. Please see /doc/bulkmail.html and 
check your .ini file"
    return
}


ns_share bulkmail_hosts
ns_share bulkmail_failed_hosts
ns_share bulkmail_current_host

ns_write "
<p>bulkmail_hosts = { $bulkmail_hosts }
<br>bulkmail_failed_hosts =  "

set form_size [ns_set size $bulkmail_failed_hosts]
set form_counter_i 0
while {$form_counter_i<$form_size} {
    ns_write "<b>[ns_set key $bulkmail_failed_hosts $form_counter_i]</b>: [ns_quotehtml [ns_set value $bulkmail_failed_hosts $form_counter_i]], "
    incr form_counter_i
}

ns_write "

<br>bulkmail_queue_threshold = [bulkmail_queue_threshold]

<br>bulkmail_acceptable_message_lossage = [bulkmail_acceptable_message_lossage]

<br>bulkmail_acceptable_host_failures = [bulkmail_acceptable_host_failures]

<br>bulkmail_bounce_threshold = [bulkmail_bounce_threshold]

<br>bulkmail_current_host = [lindex $bulkmail_hosts $bulkmail_current_host]
<p>



<h3>Currently active mailings</h3>
<ul>
"

ns_mutex lock $bulkmail_instances_mutex
catch {
    set instances [ns_set copy $bulkmail_instances]
}
ns_mutex unlock $bulkmail_instances_mutex

set db [ns_db gethandle]

set instances_size [ns_set size $instances] 
if { $instances_size == 0 } {
    ns_write "<li><em>There are no currently active mailings.</em>"
} else {
    for { set i 0 } { $i < $instances_size } { incr i } {
	set instance_stats [ns_set value $instances $i]
	set n_queued [lindex $instance_stats 0]
	set n_sent [lindex $instance_stats 1]
	set bulkmail_id [ns_set key $instances $i]

	# Go and grab the domain name and alert title from the db
	set selection [ns_db 1row $db "select description, to_char(creation_date, 'YYYY-MM-DD HH24:MI:SS') as creation_date, n_sent as db_n_sent from bulkmail_instances where bulkmail_id = $bulkmail_id"]
	set_variables_after_query

	ns_write "<li>$bulkmail_id<a/>: $description ($n_queued queued, $n_sent sent, $db_n_sent recorded)\n"
    }
}

ns_write "</ul>"


ns_write "
<h3>System status</h3>
<ul>
<li>Total mailer threads spawned: $bulkmail_threads_spawned
<li>Total mailer threads completed: $bulkmail_threads_completed
</ul>"




ns_write "<hr>
[ad_footer]"
