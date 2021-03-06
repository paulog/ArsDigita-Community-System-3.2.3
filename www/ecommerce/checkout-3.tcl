# $Id: checkout-3.tcl,v 3.1.2.1 2000/04/28 15:09:59 carsten Exp $
set_form_variables 0
# possibly usca_p

# they should get here from process-order-quantity-payment-shipping.tcl
# this page just summarizes their order before they submit it

ec_redirect_to_https_if_possible_and_necessary

# Make sure we have all their necessary info, otherwise they probably got
# here via url surgery or by pushing Back

# 1. There should be an in_basket order for their user_session_id.
# 2. The order should have the correct user_id associated with it.
# 3. The order should contain items.
# 4. The order should have an address associated with it.
# 5. The order should have credit card and shipping method associated with it.

# we need them to be logged in
set user_id [ad_verify_and_get_user_id]

if {$user_id == 0} {
    
    set return_url "[ns_conn url]"

    ad_returnredirect "/register.tcl?[export_url_vars return_url]"
    return
}

# make sure they have an in_basket order, otherwise they've probably
# gotten here by pushing Back, so return them to index.tcl

set user_session_id [ec_get_user_session_id]

set db [ns_db gethandle]
ec_create_new_session_if_necessary
# type1

set order_id [database_to_tcl_string_or_null $db "select order_id from ec_orders where user_session_id=$user_session_id and order_state='in_basket'"]

if { [empty_string_p $order_id] } {
    # then they probably got here by pushing "Back", so just redirect them
    # to index.tcl
    ad_returnredirect index.tcl
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

# make sure there is an address for this order, otherwise they've probably
# gotten here via url surgery, so redirect them to checkout.tcl

set address_id [database_to_tcl_string_or_null $db "select shipping_address from ec_orders where order_id=$order_id"]
if { [empty_string_p $address_id] } {
    ad_returnredirect checkout.tcl
    return
}

# make sure there is a credit card (or that the gift_certificate_balance covers the cost) and 
# a shipping method for this order, otherwise
# they've probably gotten here via url surgery, so redirect them to checkout-2.tcl

set creditcard_id [database_to_tcl_string_or_null $db "select creditcard_id from ec_orders where order_id=$order_id"]

if { [empty_string_p $creditcard_id] } {

    # ec_order_cost returns price + shipping + tax - gift_certificate BUT no gift certificates have been applied to
    # in_basket orders, so this just returns price + shipping + tax
    set order_total_price_pre_gift_certificate [database_to_tcl_string $db "select ec_order_cost($order_id) from dual"]

    set gift_certificate_balance [database_to_tcl_string $db "select ec_gift_certificate_balance($user_id) from dual"]
    
    if { $gift_certificate_balance < $order_total_price_pre_gift_certificate } {
	set gift_certificate_covers_cost_p "f"
    } else {
	set gift_certificate_covers_cost_p "t"
    }
}

set shipping_method [database_to_tcl_string_or_null $db "select shipping_method from ec_orders where order_id=$order_id"]


if { [empty_string_p $shipping_method] || ([empty_string_p $creditcard_id] && (![info exists gift_certificate_covers_cost_p] || $gift_certificate_covers_cost_p == "f")) } {
    ad_returnredirect checkout-2.tcl
    return
}

## done with all the checks
## their order is ready to go!
## now show them a summary before they submit their order

set order_summary [ec_order_summary_for_customer $db $order_id $user_id]

ad_return_template