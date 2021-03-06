# $Id: ad-pics.tcl,v 3.1 2000/02/26 12:55:27 jsalz Exp $
# ad-pics.tcl
# created by philg on 11/20/98
# 
# writes PICS headers on naughty site content
# (as spec'd in /web/yourdomain/parameters/ad.ini file,
#  /acs/pics section)

ns_share -init {set ad_pics_filters_installed_p 0} ad_pics_filters_installed_p

if { !$ad_pics_filters_installed_p && [ad_parameter EnabledP pics 0]} {
    # we haven't registered the filters and PICS is enabled
    set ad_pics_filters_installed_p 1
    set pics_config_section [ad_parameter_section pics]
    for {set i 0} {$i<[ns_set size $pics_config_section]} {incr i} {
	if { [ns_set key $pics_config_section $i] == "NaughtyPattern" } {
	    set path_pattern [ns_set value $pics_config_section $i]
	    ns_log Notice "Adding the PICS header filter for \"$path_pattern\"" 
	    ad_register_filter postauth GET $path_pattern ad_pics_filter
	}
    }
}


proc ad_pics_filter {conn args why} {
    set headers [ns_conn outputheaders $conn]
    ns_set update $headers Protocol [ad_parameter Protocol pics]
    ns_set update $headers PICS-Label [ad_parameter Label pics]
    return filter_ok
}
