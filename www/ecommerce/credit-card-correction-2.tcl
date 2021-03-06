# $Id: credit-card-correction-2.tcl,v 3.1.2.1 2000/04/28 15:10:00 carsten Exp $
set_the_usual_form_variables
# creditcard_number, creditcard_type, creditcard_expire_1, creditcard_expire_2, billing_zip_code

# 1. do the normal url/cookie surgery checks
# 2. insert credit card data into ec_creditcards
# 3. update orders to use this credit card
# 4. redirect to finalize-order.tcl to process this info

# Doubleclick problem:
# There is a small but finite amount of time between the time that the user runs
# this script and the time that their order goes into the 'confirmed' state.
# During this time, it is possible for the user to submit their credit card info
# twice, thereby adding rows to ec_creditcards.
# However, no order will be updated after it's confirmed, so this credit card info
# will be unreferenced by any order and we can delete it with a cron job.

ec_redirect_to_https_if_possible_and_necessary

# first do the basic error checking
# also get rid of spaces and dashes in the credit card number
if { [info exists creditcard_number] } {
    # get rid of spaces and dashes
    regsub -all -- "-" $creditcard_number "" creditcard_number
    regsub -all " " $creditcard_number "" creditcard_number
}

set exception_count 0
set exception_text ""

if { [regexp {[^0-9]} $creditcard_number] } {
    # I've already removed spaces and dashes, so only numbers should remain
    incr exception_count
    append exception_text "<li> Your credit card number contains invalid characters."
}

if { ![info exists billing_zip_code] || [empty_string_p $billing_zip_code] } {
    incr exception_count
    append exception_text "<li> You forgot to enter your billing zip code."
}

if { ![info exists creditcard_type] || [empty_string_p $creditcard_type] } {
    incr exception_count
    append exception_text "<li> You forgot to enter your credit card type."
}

# make sure the credit card type is right & that it has the right number
# of digits
set additional_count_and_text [ec_creditcard_precheck $creditcard_number $creditcard_type]

set exception_count [expr $exception_count + [lindex $additional_count_and_text 0]]
append exception_text [lindex $additional_count_and_text 1]

if { ![info exists creditcard_expire_1] || [empty_string_p $creditcard_expire_1] || ![info exists creditcard_expire_2] || [empty_string_p $creditcard_expire_2] } {
    incr exception_count
    append exception_text "<li> Please enter your full credit card expiration date (month and year)"
}

if { $exception_count > 0 } {
    ad_return_complaint $exception_count $exception_text
    return
}

# then do all the normal checks to make sure nobody is doing url
# or cookie surgery to get here

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]?[export_url_vars creditcard_number creditcard_type creditcard_expire_1 creditcard_expire_2 billing_zip_code]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# make sure they have an in_basket order
# unlike previous pages, if they don't have an in_basket order
# it may be because they tried to execute this code twice and
# the order is already in the confirmed state
# In this case, they should be redirected to the thank you
# page for the most recently confirmed order, if one exists,
# otherwise redirect them to index.tcl

set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]

if { [empty_string_p $order_id] } {

    # find their most recently confirmed order
    set most_recently_confirmed_order [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_id=$user_id and confirmed_date is not null and order_id=(select max(o2.order_id) from ec_orders o2 where o2.user_id=$user_id and o2.confirmed_date is not null)"]
    if { [empty_string_p $most_recently_confirmed_order] } {
	ad_returnredirect index.tcl
    } else {
	ad_returnredirect thank-you.tcl
    }
    return
}

# make sure there's something in their shopping cart, otherwise
# redirect them to their shopping cart which will tell them
# that it's empty.

if { [database_to_tcl_string $db "select count(*) from ec_items where order_id=$order_id"] == 0 } {
    ad_returnredirect shopping-cart.tcl
    return
}

# make sure the order belongs to this user_id, otherwise they managed to skip past checkout.tcl, or
# they messed w/their user_session_id cookie
set order_owner [database_to_tcl_string $db "select user_id from ec_orders where order_id=$order_id"]

if { $order_owner != $user_id } {
    ad_returnredirect checkout.tcl
    return
}

# done with all the checks!

# do some inserts
set creditcard_id [database_to_tcl_string $db "select ec_creditcard_id_sequence.nextval from dual"]

ns_db dml $db "begin transaction"

ns_db dml $db "insert into ec_creditcards
(creditcard_id, user_id, creditcard_number, creditcard_last_four, creditcard_type, creditcard_expire, billing_zip_code)
values
($creditcard_id, $user_id, '$creditcard_number', '[string range $creditcard_number [expr [string length $creditcard_number] -4] [expr [string length $creditcard_number] -1]]', '$QQcreditcard_type','$creditcard_expire_1/$creditcard_expire_2','$QQbilling_zip_code')
"

# make sure order is still in the 'in_basket' state while doing the
# insert because it could have been confirmed in the (small) time
# it took to get from "set order_id ..." to here
# if not, no harm done; no rows will be updated

ns_db dml $db "update ec_orders set creditcard_id=$creditcard_id where order_id=$order_id and order_state='in_basket'"

ns_db dml $db "end transaction"

ad_returnredirect finalize-order.tcl