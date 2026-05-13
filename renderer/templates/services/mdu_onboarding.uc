{%
'use strict';

let mdu = state.services["mdu_onboarding"];

if (!mdu)
	return;

let ppsk_url = mdu["ppsk_registration_url"];
let server_ip = mdu["server_ip"];

if (!ppsk_url) {
	warn("mdu-onboarding: missing ppsk-registration-url");
	return;
}

if (!server_ip) {
	warn("mdu-onboarding: missing server-ip");
	return;
}

let interfaces = services.lookup_interfaces("mdu-onboarding");
let enable = length(interfaces);

if (!enable)
	return;

if (enable > 1) {
	warn("mdu-onboarding can only run on a single interface");
	return;
}
system("touch /etc/config-shadow/mdu");
services.set_enabled("uhttpd", enable);
%}


add mdu mdu
rename mdu.@mdu[-1]=onboarding
set mdu.onboarding.ppsk_url='{{ ppsk_url }}'
set mdu.onboarding.server_ip='{{ server_ip }}'

{% for (let interface in uniq(interfaces)): %}
{%   let name = ethernet.calculate_name(interface) %}
{%   let upstream = ethernet.find_interface("upstream", 0) %}

set firewall.redirect_http_{{ name }}='redirect'
set firewall.redirect_http_{{ name }}.name='Redirect-HTTP-{{ name }}-to-uhttpd'
set firewall.redirect_http_{{ name }}.src='{{ name }}'
set firewall.redirect_http_{{ name }}.proto='tcp'
set firewall.redirect_http_{{ name }}.src_dport='80'
set firewall.redirect_http_{{ name }}.src_dip='!{{ server_ip }}'
set firewall.redirect_http_{{ name }}.dest_port='80'
set firewall.redirect_http_{{ name }}.target='DNAT'

set firewall.allow_http_to_uhttpd_{{ name }}='rule'
set firewall.allow_http_to_uhttpd_{{ name }}.name='Allow-HTTP-to-uhttpd-{{ name }}'
set firewall.allow_http_to_uhttpd_{{ name }}.src='{{ name }}'
set firewall.allow_http_to_uhttpd_{{ name }}.proto='tcp'
set firewall.allow_http_to_uhttpd_{{ name }}.dest_port='80'
set firewall.allow_http_to_uhttpd_{{ name }}.target='ACCEPT'
set firewall.allow_http_to_uhttpd_{{ name }}.enabled='1'

set firewall.allow_http_to_final_ip_{{ name }}='rule'
set firewall.allow_http_to_final_ip_{{ name }}.name='Allow-HTTP-to-final-ip-{{ name }}'
set firewall.allow_http_to_final_ip_{{ name }}.src='{{ name }}'
set firewall.allow_http_to_final_ip_{{ name }}.dest='{{ upstream }}'
set firewall.allow_http_to_final_ip_{{ name }}.dest_ip='{{ server_ip }}'
set firewall.allow_http_to_final_ip_{{ name }}.dest_port='80'
set firewall.allow_http_to_final_ip_{{ name }}.proto='tcp'
set firewall.allow_http_to_final_ip_{{ name }}.target='ACCEPT'
set firewall.allow_http_to_final_ip_{{ name }}.enabled='1'

set firewall.block_internet_{{ name }}='rule'
set firewall.block_internet_{{ name }}.name='Block-Internet-{{ name }}'
set firewall.block_internet_{{ name }}.src='{{ name }}'
set firewall.block_internet_{{ name }}.dest='{{ upstream }}'
set firewall.block_internet_{{ name }}.proto='any'
set firewall.block_internet_{{ name }}.target='REJECT'
set firewall.block_internet_{{ name }}.enabled='1'

{% endfor %}

set uhttpd.mdu_onboarding='uhttpd'
set uhttpd.mdu_onboarding.redirect_https='0'
set uhttpd.mdu_onboarding.rfc1918_filter='1'
set uhttpd.mdu_onboarding.max_requests='5'
set uhttpd.mdu_onboarding.max_connections='100'
set uhttpd.mdu_onboarding.cert='/etc/uhttpd.crt'
set uhttpd.mdu_onboarding.key='/etc/uhttpd.key'
set uhttpd.mdu_onboarding.script_timeout='60'
set uhttpd.mdu_onboarding.network_timeout='30'
set uhttpd.mdu_onboarding.http_keepalive='20'
set uhttpd.mdu_onboarding.tcp_keepalive='1'
set uhttpd.mdu_onboarding.no_dirlists='1'
add_list uhttpd.mdu_onboarding.listen_http='0.0.0.0:80'
add_list uhttpd.mdu_onboarding.listen_http='[::]:80'
add_list uhttpd.mdu_onboarding.ucode_prefix='/mdu=/usr/share/uspot/mdu-handler.uc'
set uhttpd.mdu_onboarding.error_page='/mdu'
