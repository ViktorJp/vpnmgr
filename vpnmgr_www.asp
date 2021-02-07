<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>vpnmgr</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p {
font-weight: bolder;
}

thead.collapsible-jquery {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}

.SettingsTable {
  table-layout: fixed !important;
  width: 745px !important;
  text-align: left;
}

.SettingsTable input {
  text-align: left;
  margin-left: 3px !important;
}

.SettingsTable label {
  margin-right: 10px !important;
}

.SettingsTable th {
  background-color: #1F2D35 !important;
  background: #2F3A3E !important;
  border-bottom: none !important;
  border-top: none !important;
  font-size: 12px !important;
  color: white !important;
  padding: 4px !important;
  font-weight: bolder !important;
  padding: 0px !important;
}

.SettingsTable td {
  padding: 4px 4px 4px 10px !important;
  word-wrap: break-word !important;
  overflow-wrap: break-word !important;
  border-right: none;
  border-left: none;
}

.SettingsTable td.settingname {
  border-right: solid 1px black;
  background-color: #1F2D35 !important;
  background: #2F3A3E !important;
  font-weight: bolder !important;
}

.SettingsTable td.settingvalue {
  text-align: left !important;
  border-right: solid 1px black;
}

.SettingsTable th:first-child{
  border-left: none !important;
}

.SettingsTable th:last-child {
  border-right: none !important;
}

.SettingsTable .invalid {
  background-color: darkred !important;
}

.SettingsTable .disabled {
  background-color: #CCCCCC !important;
  color: #888888 !important;
}

input.settingvalue {
  margin-left: 3px !important;
}

label.settingvalue {
  margin-right: 10px !important;
  vertical-align: top !important;
}
</style>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/jquery.js"></script>
<script language="JavaScript" type="text/javascript" src="/state.js"></script>
<script language="JavaScript" type="text/javascript" src="/general.js"></script>
<script language="JavaScript" type="text/javascript" src="/popup.js"></script>
<script language="JavaScript" type="text/javascript" src="/help.js"></script>
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/detect.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmhist.js"></script>
<script language="JavaScript" type="text/javascript" src="/tmmenu.js"></script>
<script language="JavaScript" type="text/javascript" src="/client_function.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/base64.js"></script>
<script>
var custom_settings;
function LoadCustomSettings(){
	custom_settings = <% get_custom_settings(); %>;
	for (var prop in custom_settings){
		if (Object.prototype.hasOwnProperty.call(custom_settings, prop)){
			if(prop.indexOf("vpnmgr") != -1 && prop.indexOf("version") == -1){
				eval("delete custom_settings."+prop)
			}
		}
	}
}
var $j=jQuery.noConflict(),daysofweek=["Mon","Tues","Wed","Thurs","Fri","Sat","Sun"],nordvpncountries=[],piacountries=[],wevpncountries=[];function SettingHint(a){for(var b=document.getElementsByTagName("a"),c=0;c<b.length;c++)b[c].onmouseout=nd;return hinttext="My text goes here",1==a&&(hinttext="Manage VPN client using vpnmgr"),2==a&&(hinttext="Provider to use for VPN"),3==a&&(hinttext="Username for VPN"),4==a&&(hinttext="Password for VPN"),5==a&&(hinttext="Protocol to use for VPN server"),6==a&&(hinttext="Type of VPN server to use"),7==a&&(hinttext="Country of VPN server to use"),8==a&&(hinttext="City of VPN server to use"),9==a&&(hinttext="Automatically update VPN to new VPN server"),10==a&&(hinttext="Day(s) of week to check for new server/reload server config"),11==a&&(hinttext="Set schedule by every X hours/days or custom input"),12==a&&(hinttext="Set frequency of update"),13==a&&(hinttext="Hour(s) of day to check for new server/reload server config (* for all, 0-23. Comma separate for multiple hours.)"),14==a&&(hinttext="Minute(s) of hour to check for new server/reload server config (* for all, 0-59. Comma separate for multiple minutes.)"),overlib(hinttext,HAUTO,VAUTO)}function OptionsEnableDisable(a,b){var c=a.name,d=a.value,e=c.substring(0,c.lastIndexOf("_")),f=e.replace("vpnmgr_",""),g=["provider","usn","pwd","protocol","type","countryname","cityname","schenabled","schhours","schmins"],h=["schedulemode","everyxselect","everyxvalue"];if("false"==d){for(var j=0;j<g.length;j++)$j("[name="+e+"_"+g[j]+"]").prop("disabled",!0),$j("[name="+e+"_"+g[j]+"]").addClass("disabled");for(var j=0;j<daysofweek.length;j++)$j("#"+e+"_"+daysofweek[j].toLowerCase()).prop("disabled",!0);for(var j=0;j<h.length;j++)$j("[name="+f+"_"+h[j]+"]").addClass("disabled"),$j("[name="+f+"_"+h[j]+"]").prop("disabled",!0)}else if("true"==d){for(var j=0;j<g.length;j++)$j("[name="+e+"_"+g[j]+"]").prop("disabled",!1),$j("[name="+e+"_"+g[j]+"]").removeClass("disabled");for(var j=0;j<daysofweek.length;j++)$j("#"+e+"_"+daysofweek[j].toLowerCase()).prop("disabled",!1);for(var j=0;j<h.length;j++)$j("[name="+f+"_"+h[j]+"]").removeClass("disabled"),$j("[name="+f+"_"+h[j]+"]").prop("disabled",!1);b||(ScheduleOptionsEnableDisable($j("#"+e+"_sch_"+$j("[name="+e+"_schenabled]:checked").val().toLowerCase())[0]),VPNTypesToggle($j("#"+e+"_prov_"+$j("[name="+e+"_provider]:checked").val().toLowerCase())[0]))}}function VPNTypesToggle(a){var b=a.name,c=a.value,d=b.substring(0,b.lastIndexOf("_"));"NordVPN"===c?($j("label[for="+d+"_standard],#"+d+"_standard").show(),$j("label[for="+d+"_double],#"+d+"_double").show(),$j("label[for="+d+"_p2p],#"+d+"_p2p").show(),$j("label[for="+d+"_strong],#"+d+"_strong").hide()):"PIA"===c?($j("label[for="+d+"_standard],#"+d+"_standard").show(),$j("label[for="+d+"_double],#"+d+"_double").hide(),$j("label[for="+d+"_p2p],#"+d+"_p2p").hide(),$j("label[for="+d+"_strong],#"+d+"_strong").show()):"WeVPN"===c?($j("label[for="+d+"_standard],#"+d+"_standard").show(),$j("label[for="+d+"_double],#"+d+"_double").hide(),$j("label[for="+d+"_p2p],#"+d+"_p2p").hide(),$j("label[for="+d+"_strong],#"+d+"_strong").hide()):void 0;$j("#"+d+"_standard").prop("checked",!0),PopulateCountryDropdown(d.replace("vpnmgr_vpn","")),""==$j("select[name="+d+"_countryname]").val()?$j("select[name="+d+"_cityname]").prop("disabled",!0):""!=$j("select[name="+d+"_countryname]").val()&&$j("select[name="+d+"_cityname]").prop("disabled",!1),PopulateCityDropdown(d.replace("vpnmgr_vpn",""));let e=$j("select[name="+d+"_cityname]");0==e[0].length||0==e.find("option:first-child").val().length?e.prop("disabled",!0):0<e[0].length&&e.prop("disabled",!1)}function ScheduleOptionsEnableDisable(forminput){var inputname=forminput.name,inputvalue=forminput.value,prefix=inputname.substring(0,inputname.lastIndexOf("_")),prefix2=prefix.replace("vpnmgr_",""),fieldnames=["schhours","schmins"],fieldnames2=["schedulemode","everyxselect","everyxvalue"];if("true"==eval("document.form."+prefix+"_managed").value)if("false"==inputvalue){for(var i=0;i<fieldnames.length;i++)$j("input[name="+prefix+"_"+fieldnames[i]+"]").addClass("disabled"),$j("input[name="+prefix+"_"+fieldnames[i]+"]").prop("disabled",!0);for(var i=0;i<daysofweek.length;i++)$j("#"+prefix+"_"+daysofweek[i].toLowerCase()).prop("disabled",!0);for(var i=0;i<fieldnames2.length;i++)$j("[name="+prefix2+"_"+fieldnames2[i]+"]").addClass("disabled"),$j("[name="+prefix2+"_"+fieldnames2[i]+"]").prop("disabled",!0)}else if("true"==inputvalue){for(var i=0;i<fieldnames.length;i++)$j("input[name="+prefix+"_"+fieldnames[i]+"]").removeClass("disabled"),$j("input[name="+prefix+"_"+fieldnames[i]+"]").prop("disabled",!1);for(var i=0;i<daysofweek.length;i++)$j("#"+prefix+"_"+daysofweek[i].toLowerCase()).prop("disabled",!1);for(var i=0;i<fieldnames2.length;i++)$j("[name="+prefix2+"_"+fieldnames2[i]+"]").removeClass("disabled"),$j("[name="+prefix2+"_"+fieldnames2[i]+"]").prop("disabled",!1)}}function PopulateCountryDropdown(vpnclient){for(var vpnno=1;6>vpnno;vpnno++){if("all"!=vpnclient&&vpnno!=vpnclient)continue;let dropdown=$j("#vpnmgr_vpn"+vpnno+"_countryname");dropdown.empty();var countryarray=[];"NordVPN"==eval("document.form.vpnmgr_vpn"+vpnno+"_provider").value?(dropdown.append("<option selected=\"true\"></option>"),dropdown.prop("selectedIndex",0),countryarray=nordvpncountries):"PIA"==eval("document.form.vpnmgr_vpn"+vpnno+"_provider").value?countryarray=piacountries:"WeVPN"==eval("document.form.vpnmgr_vpn"+vpnno+"_provider").value&&(countryarray=wevpncountries),$j.each(countryarray,function(a,b){dropdown.append($j("<option></option>").attr("value",b.name).text(b.name))})}}function PopulateCityDropdown(vpnclient){for(var vpnno=1;6>vpnno;vpnno++){if("all"!=vpnclient&&vpnno!=vpnclient)continue;let dropdown=$j("#vpnmgr_vpn"+vpnno+"_cityname");dropdown.empty(),"NordVPN"==eval("document.form.vpnmgr_vpn"+vpnno+"_provider").value?(dropdown.append("<option selected=\"true\"></option>"),dropdown.prop("selectedIndex",0),cityarray=nordvpncountries):"PIA"==eval("document.form.vpnmgr_vpn"+vpnno+"_provider").value?cityarray=piacountries:"WeVPN"==eval("document.form.vpnmgr_vpn"+vpnno+"_provider").value&&(cityarray=wevpncountries),$j.each(cityarray,function(key,entry){return entry.name!=eval("document.form.vpnmgr_vpn"+vpnno+"_countryname").value||($j.each(entry.cities,function(a,b){dropdown.append($j("<option></option>").attr("value",b.name).text(b.name))}),!1)})}}function ScheduleModeToggle(a){var b=a.name,c=a.value,d=b.substring(0,b.lastIndexOf("_"));"EveryX"==c?(showhide(d+"_schedulefrequency",!0),showhide(d+"_customhours",!1),showhide(d+"_custommins",!1),"hours"==$j("#"+d+"_everyxselect").val()?(showhide(d+"_spanxhours",!0),showhide(d+"_spanxminutes",!1)):"minutes"==$j("#"+d+"_everyxselect").val()&&(showhide(d+"_spanxhours",!1),showhide(d+"_spanxminutes",!0))):"Custom"==c&&(showhide(d+"_schedulefrequency",!1),showhide(d+"_customhours",!0),showhide(d+"_custommins",!0))}function EveryXToggle(a){var b=a.name,c=a.value,d=b.substring(0,b.lastIndexOf("_"));"hours"==c?(showhide(d+"_spanxhours",!0),showhide(d+"_spanxminutes",!1)):"minutes"==c&&(showhide(d+"_spanxhours",!1),showhide(d+"_spanxminutes",!0)),Validate_ScheduleValue($j("[name="+d+"_everyxvalue]")[0])}function Validate_Schedule(a,b){var c=a.name,d=a.value.split(","),e=0;"hours"==b?e=23:"mins"==b&&(e=59);for(var f="false",g=0;g<d.length;g++)"*"==d[g]&&0==g?f="false":"*"==d[g]&&0!=g?f="true":"*"==d[0]&&0<g?f="true":""==d[g]?f="true":isNaN(1*d[g])?f="true":(1*d[g]>e||0>1*d[g])&&(f="true");return"true"==f?($j(a).addClass("invalid"),!1):($j(a).removeClass("invalid"),!0)}function Validate_ScheduleValue(a){var b=a.name,c=1*a.value,d=b.substring(0,b.lastIndexOf("_")),e=0,f=$j("#"+d+"_everyxselect").val();return"hours"==f?e=24:"minutes"==f&&(e=30),c>e||c<1||1>a.value.length?($j(a).addClass("invalid"),!1):($j(a).removeClass("invalid"),!0)}function Validate_All(){for(var validationfailed=!1,i=1;6>i;i++)"EveryX"==eval("document.form.vpn"+i+"_schedulemode").value?Validate_ScheduleValue(eval("document.form.vpn"+i+"_everyxvalue"))||(validationfailed=!0):"Custom"==eval("document.form.vpn"+i+"_schedulemode").value&&(Validate_Schedule(eval("document.form.vpnmgr_vpn"+i+"_schhours"),"hours")||(validationfailed=!0),Validate_Schedule(eval("document.form.vpnmgr_vpn"+i+"_schmins"),"mins")||(validationfailed=!0));return!validationfailed||(alert("Validation for some fields failed. Please correct invalid values and try again."),!1)}function get_conf_file(){$j.ajax({url:"/ext/vpnmgr/config.htm",dataType:"text",error:function(){setTimeout(get_conf_file,1e3)},success:function(data){var settings=data.split("\n");settings.reverse(),settings=settings.filter(Boolean);var settingcount=settings.length;window.vpnmgr_settings=[];for(var i=0;i<settingcount;i++)if(-1==settings[i].indexOf("#")){var setting=settings[i].split("=");window.vpnmgr_settings.unshift(setting)}for(var vpnno=5;1<=vpnno;vpnno--)$j("#table_scripttools").after(BuildConfigTable("vpn"+vpnno,"VPN Client "+vpnno));for(var i=0;i<window.vpnmgr_settings.length;i++){let settingname=window.vpnmgr_settings[i][0],settingvalue=window.vpnmgr_settings[i][1];if(-1==settingname.indexOf("cityid")&&-1==settingname.indexOf("countryid")&&-1==settingname.indexOf("countryname")&&-1==settingname.indexOf("cityname"))if(-1==settingname.indexOf("schdays"))eval("document.form.vpnmgr_"+settingname).value=settingvalue,-1!=settingname.indexOf("managed")&&OptionsEnableDisable($j("#vpnmgr_"+settingname.replace("_managed","")+"_man_"+settingvalue)[0],!0),-1!=settingname.indexOf("schenabled")&&ScheduleOptionsEnableDisable($j("#vpnmgr_"+settingname.replace("_schenabled","")+"_sch_"+settingvalue)[0]),-1!=settingname.indexOf("provider")&&VPNTypesToggle($j("#vpnmgr_"+settingname.replace("_provider","")+"_prov_"+settingvalue.toLowerCase())[0]);else if("*"==settingvalue)for(var i2=0;i2<daysofweek.length;i2++)$j("#vpnmgr_"+settingname.substring(0,vpnmgr_settings[i][0].indexOf("_"))+"_"+daysofweek[i2].toLowerCase()).prop("checked",!0);else for(var schdayarray=settingvalue.split(","),i2=0;i2<schdayarray.length;i2++)$j("#vpnmgr_"+settingname.substring(0,vpnmgr_settings[i][0].indexOf("_"))+"_"+schdayarray[i2].toLowerCase()).prop("checked",!0)}PopulateCountryDropdown("all");for(var i=1;6>i;i++)eval("document.form.vpnmgr_vpn"+i+"_countryname").value=window.vpnmgr_settings.filter(function(a){return a[0]=="vpn"+i+"_countryname"})[0][1],""==eval("document.form.vpnmgr_vpn"+i+"_countryname").value?$j("#vpnmgr_vpn"+i+"_cityname").prop("disabled",!0):""!=eval("document.form.vpnmgr_vpn"+i+"_countryname").value&&$j("#vpnmgr_vpn"+i+"_cityname").prop("disabled",!1),""==eval("document.form.vpnmgr_vpn"+i+"_countryname").value&&1==eval("document.form.vpnmgr_vpn"+i+"_countryname").length&&$j("#vpnmgr_vpn"+i+"_cityname").prop("disabled",!0);PopulateCityDropdown("all");for(var i=1;6>i;i++)eval("document.form.vpnmgr_vpn"+i+"_cityname").value=window.vpnmgr_settings.filter(function(a){return a[0]=="vpn"+i+"_cityname"})[0][1],0==eval("document.form.vpnmgr_vpn"+i+"_cityname").length||1==eval("document.form.vpnmgr_vpn"+i+"_cityname").length&&""==eval("document.form.vpnmgr_vpn"+i+"_cityname").value?$j("#vpnmgr_vpn"+i+"_cityname").prop("disabled",!0):0<eval("document.form.vpnmgr_vpn"+i+"_cityname").length&&$j("#vpnmgr_vpn"+i+"_cityname").prop("disabled",!1);for(var i=1;6>i;i++)eval("document.form.vpnmgr_vpn"+i+"_usn").value=eval("document.form.vpn"+i+"_usn").value,eval("document.form.vpnmgr_vpn"+i+"_pwd").value=eval("document.form.vpn"+i+"_pwd").value,-1==$j("[name=vpnmgr_vpn"+i+"_schhours]").val().indexOf("/")?-1==$j("[name=vpnmgr_vpn"+i+"_schmins]").val().indexOf("/")?eval("document.form.vpn"+i+"_schedulemode").value="Custom":(eval("document.form.vpn"+i+"_schedulemode").value="EveryX",eval("document.form.vpn"+i+"_everyxselect").value="minutes",eval("document.form.vpn"+i+"_everyxvalue").value=$j("[name=vpnmgr_vpn"+i+"_schmins]").val().split("/")[1]):(eval("document.form.vpn"+i+"_schedulemode").value="EveryX",eval("document.form.vpn"+i+"_everyxselect").value="hours",eval("document.form.vpn"+i+"_everyxvalue").value=$j("[name=vpnmgr_vpn"+i+"_schhours]").val().split("/")[1]),ScheduleModeToggle($j("#vpn"+i+"_schmode_"+$j("[name=vpn"+i+"_schedulemode]:checked").val().toLowerCase())[0]);showhide("imgRefreshCachedData",!1),showhide("refreshcacheddata_text",!1),showhide("btnRefreshCachedData",!0),AddEventHandlers()}})}function GetCookie(a,b){var c;if(null!=(c=cookie.get("vpnmgr_"+a)))return cookie.get("vpnmgr_"+a);return"string"==b?"":"number"==b?0:void 0}function SetCookie(a,b){cookie.set("vpnmgr_"+a,b,31)}function SetCurrentPage(){document.form.next_page.value=window.location.pathname.substring(1),document.form.current_page.value=window.location.pathname.substring(1)}function reload(){location.reload(!0)}function pass_checked(a,b){switchType(a,b.checked,!0)}function SaveConfig(){if(Validate_All()){for(var i=1;6>i;i++)if("EveryX"==eval("document.form.vpn"+i+"_schedulemode").value)if("hours"==eval("document.form.vpn"+i+"_everyxselect").value){var everyxvalue=1*eval("document.form.vpn"+i+"_everyxvalue").value;eval("document.form.vpnmgr_vpn"+i+"_schmins").value=0,eval("document.form.vpnmgr_vpn"+i+"_schhours").value=24==everyxvalue?0:"*/"+everyxvalue}else if("minutes"==eval("document.form.vpn"+i+"_everyxselect").value){eval("document.form.vpnmgr_vpn"+i+"_schhours").value=0;var everyxvalue=1*eval("document.form.vpn"+i+"_everyxvalue").value;eval("document.form.vpnmgr_vpn"+i+"_schmins").value="*/"+everyxvalue}$j("[name*=vpnmgr_]").prop("disabled",!1),document.getElementById("amng_custom").value=JSON.stringify($j("form").serializeObject());var action_script_tmp="start_vpnmgr";document.form.action_script.value="start_vpnmgr";var restart_time=15;document.form.action_wait.value=15,showLoading(),document.form.submit()}else return!1}function initial(){SetCurrentPage(),LoadCustomSettings(),show_menu(),getNordVPNCountryData(),ScriptUpdateLayout()}function BuildConfigTable(a,b){var c="<div style=\"line-height:10px;\">&nbsp;</div>";return c+="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"FormTable\" id=\"table_config_"+a+"\">",c+="<thead class=\"collapsible-jquery\" id=\""+a+"\">",c+="<tr>",c+="<td colspan=\"2\">"+b+" Configuration (click to expand/collapse)</td>",c+="</tr>",c+="</thead>",c+="<tr>",c+="<td colspan=\"2\" align=\"center\" style=\"padding: 0px;\">",c+="<table width=\"100%\" border=\"1\" align=\"center\" cellpadding=\"4\" cellspacing=\"0\" bordercolor=\"#6b8fa3\" class=\"FormTable SettingsTable\">",c+="<col style=\"width:35%;\">",c+="<col style=\"width:65%;\">",c+="<tr>",c+="<td class=\"settingname\">Description</a></td><td class=\"settingvalue\"><span id=\"vpnmgr_"+a+"_desc\" style=\"color:#ffffff;\">"+$j("input[name="+a+"_desc]").val()+"</span></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(1);\">Managed by vpnmgr?</a></td><td class=\"settingvalue\"><input type=\"radio\" onchange=\"OptionsEnableDisable(this,false)\" name=\"vpnmgr_"+a+"_managed\" id=\"vpnmgr_"+a+"_man_true\" class=\"input\" value=\"true\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_man_true\">Yes</label><input type=\"radio\" onchange=\"OptionsEnableDisable(this,false)\" name=\"vpnmgr_"+a+"_managed\" id=\"vpnmgr_"+a+"_man_false\" class=\"input\" value=\"false\" checked><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_man_false\">No</label></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(2);\">VPN Provider</a></td><td class=\"settingvalue\"><input type=\"radio\" onchange=\"VPNTypesToggle(this)\" name=\"vpnmgr_"+a+"_provider\" id=\"vpnmgr_"+a+"_prov_nordvpn\" class=\"input\" value=\"NordVPN\" checked><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_prov_nordvpn\">NordVPN</label><input type=\"radio\" onchange=\"VPNTypesToggle(this)\" name=\"vpnmgr_"+a+"_provider\" id=\"vpnmgr_"+a+"_prov_pia\" class=\"input\" value=\"PIA\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_prov_pia\">PIA</label><input type=\"radio\" onchange=\"VPNTypesToggle(this)\" name=\"vpnmgr_"+a+"_provider\" id=\"vpnmgr_"+a+"_prov_wevpn\" class=\"input\" value=\"WeVPN\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_prov_wevpn\">WeVPN</label></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(3);\">Username</a></td><td class=\"settingvalue\"><input autocomplete=\"off\" autocapitalize=\"off\" type=\"text\" class=\"input_30_table\" onchange=\"\" name=\"vpnmgr_"+a+"_usn\" id=\"vpnmgr_"+a+"_usn\"></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(4);\">Password</a></td><td class=\"settingvalue\"><input autocomplete=\"off\" autocapitalize=\"off\" type=\"password\" class=\"input_30_table\" onchange=\"\" name=\"vpnmgr_"+a+"_pwd\" id=\"vpnmgr_"+a+"_pwd\"><input type=\"checkbox\" name=\"show_pass_"+a+"\" onclick=\"pass_checked(document.form.vpnmgr_"+a+"_pwd,document.form.show_pass_"+a+")\">Show password</td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(5);\">Type</a></td><td class=\"settingvalue\"><input type=\"radio\" name=\"vpnmgr_"+a+"_type\" id=\"vpnmgr_"+a+"_standard\" class=\"input\" value=\"Standard\" checked><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_standard\">Standard</label><input type=\"radio\" name=\"vpnmgr_"+a+"_type\" id=\"vpnmgr_"+a+"_double\" class=\"input\" value=\"Double\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_double\">Double</label><input type=\"radio\" name=\"vpnmgr_"+a+"_type\" id=\"vpnmgr_"+a+"_p2p\" class=\"input\" value=\"P2P\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_p2p\">P2P</label><input type=\"radio\" name=\"vpnmgr_"+a+"_type\" id=\"vpnmgr_"+a+"_strong\" class=\"input\" value=\"Strong\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_strong\">Strong</label></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(6);\">Protocol</a></td><td class=\"settingvalue\"><input type=\"radio\" name=\"vpnmgr_"+a+"_protocol\" id=\"vpnmgr_"+a+"_tcp\" class=\"input\" value=\"TCP\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_tcp\">TCP</label><input type=\"radio\" name=\"vpnmgr_"+a+"_protocol\" id=\"vpnmgr_"+a+"_udp\" class=\"input\" value=\"UDP\" checked><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_udp\">UDP</label></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(7);\">Country</a></td><td class=\"settingvalue\"><select name=\"vpnmgr_"+a+"_countryname\" id=\"vpnmgr_"+a+"_countryname\" onChange=\"setCitiesforCountry(this)\" class=\"input_option\"></select></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(8);\">City</a></td><td class=\"settingvalue\"><select name=\"vpnmgr_"+a+"_cityname\" id=\"vpnmgr_"+a+"_cityname\" class=\"input_option\"></select></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(9);\">Scheduled update/reload?</a></td><td class=\"settingvalue\"><input type=\"radio\" onchange=\"ScheduleOptionsEnableDisable(this)\" name=\"vpnmgr_"+a+"_schenabled\" id=\"vpnmgr_"+a+"_sch_true\" class=\"input\" value=\"true\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_sch_true\">Yes</label><input type=\"radio\"  onchange=\"ScheduleOptionsEnableDisable(this)\" name=\"vpnmgr_"+a+"_schenabled\" id=\"vpnmgr_"+a+"_sch_false\" class=\"input\" value=\"false\" checked><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_sch_false\">No</label></td>",c+="</tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(10);\">Schedule Days</a></td><td class=\"settingvalue\">",c+="<input type=\"checkbox\" name=\"vpnmgr_"+a+"_schdays\" id=\"vpnmgr_"+a+"_mon\" class=\"input\" value=\"Mon\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_mon\">Mon</label>",c+="<input type=\"checkbox\" name=\"vpnmgr_"+a+"_schdays\" id=\"vpnmgr_"+a+"_tues\" class=\"input\" value=\"Tues\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_tues\">Tues</label>",c+="<input type=\"checkbox\" name=\"vpnmgr_"+a+"_schdays\" id=\"vpnmgr_"+a+"_wed\" class=\"input\" value=\"Wed\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_wed\">Wed</label>",c+="<input type=\"checkbox\" name=\"vpnmgr_"+a+"_schdays\" id=\"vpnmgr_"+a+"_thurs\" class=\"input\" value=\"Thurs\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_thurs\">Thurs</label>",c+="<input type=\"checkbox\" name=\"vpnmgr_"+a+"_schdays\" id=\"vpnmgr_"+a+"_fri\" class=\"input\" value=\"Fri\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_fri\">Fri</label>",c+="<input type=\"checkbox\" name=\"vpnmgr_"+a+"_schdays\" id=\"vpnmgr_"+a+"_sat\" class=\"input\" value=\"Sat\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_sat\">Sat</label>",c+="<input type=\"checkbox\" name=\"vpnmgr_"+a+"_schdays\" id=\"vpnmgr_"+a+"_sun\" class=\"input\" value=\"Sun\"><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_sun\">Sun</label>",c+="</td></tr>",c+="<tr>",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(11);\">Schedule Mode</a></td><td class=\"settingvalue\"><input type=\"radio\" onchange=\"ScheduleModeToggle(this)\" name=\""+a+"_schedulemode\" id=\""+a+"_schmode_everyx\" class=\"input\" value=\"EveryX\" checked><label class=\"settingvalue\" for=\"vpnmgr_"+a+"_schmode_everyx\">Every X hours/minutes</label><input type=\"radio\" onchange=\"ScheduleModeToggle(this)\" name=\""+a+"_schedulemode\" id=\""+a+"_schmode_custom\" class=\"input\" value=\"Custom\"><label class=\"settingvalue\" for=\""+a+"_schmode_custom\">Custom</label>",c+="</tr>",c+="<tr id=\""+a+"_schedulefrequency\">",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(12);\">Frequency</a></td>",c+="<td class=\"settingvalue\"><span style=\"color:#FFFFFF;margin-left:3px;\">Every </span>",c+="<input autocomplete=\"off\" style=\"text-align:center;padding-left:2px;\" type=\"text\" maxlength=\"2\" class=\"input_3_table removespacing\" name=\""+a+"_everyxvalue\" id=\""+a+"_everyxvalue\" value=\"1\" onkeypress=\"return validator.isNumber(this, event)\" onkeyup=\"Validate_ScheduleValue(this)\" onblur=\"Validate_ScheduleValue(this)\" />",c+="&nbsp;<select name=\""+a+"_everyxselect\" id=\""+a+"_everyxselect\" class=\"input_option\" onchange=\"EveryXToggle(this)\">",c+="<option value=\"hours\">hours</option><option value=\"minutes\">minutes</option></select>",c+="<span id=\""+a+"_spanxhours\" style=\"color:#FFCC00;\"> (between 1 and 24)</span>",c+="<span id=\""+a+"_spanxminutes\" style=\"color:#FFCC00;\"> (between 1 and 30)</span>",c+="</td></tr>",c+="<tr id=\""+a+"_customhours\">",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(13);\">Schedule Hours</a></td><td class=\"settingvalue\"><input data-lpignore=\"true\" autocomplete=\"off\" autocapitalize=\"off\" type=\"text\" class=\"input_32_table\" name=\"vpnmgr_"+a+"_schhours\" value=\"*\" onkeyup=\"Validate_Schedule(this,'hours')\" onblur=\"Validate_Schedule(this,'hours')\" /></td>",c+="</tr>",c+="<tr id=\""+a+"_custommins\">",c+="<td class=\"settingname\"><a class=\"hintstyle\" href=\"javascript:void(0);\" onclick=\"SettingHint(14);\">Schedule Minutes</a></td><td class=\"settingvalue\"><input data-lpignore=\"true\" autocomplete=\"off\" autocapitalize=\"off\" type=\"text\" class=\"input_32_table\" name=\"vpnmgr_"+a+"_schmins\" value=\"*\" onkeyup=\"Validate_Schedule(this,'mins')\" onblur=\"Validate_Schedule(this,'mins')\" /></td>",c+="</tr>",c+="</table>",c+="</td>",c+="</tr>",c+="</table>",c}function AddEventHandlers(){$j(".collapsible-jquery").click(function(){$j(this).siblings().toggle("fast",function(){"none"==$j(this).css("display")?SetCookie($j(this).siblings()[0].id,"collapsed"):SetCookie($j(this).siblings()[0].id,"expanded")})}),$j(".collapsible-jquery").each(function(){"collapsed"==GetCookie($j(this)[0].id,"string")?$j(this).siblings().toggle(!1):$j(this).siblings().toggle(!0)})}$j.fn.serializeObject=function(){var b=custom_settings,c=this.serializeArray();$j.each(c,function(){b[this.name]!==void 0&&-1!=this.name.indexOf("vpnmgr")&&-1==this.name.indexOf("version")&&-1==this.name.indexOf("schdays")&&-1==this.name.indexOf("countryid")&&-1==this.name.indexOf("cityid")?(!b[this.name].push&&(b[this.name]=[b[this.name]]),b[this.name].push(this.value||"")):-1!=this.name.indexOf("vpnmgr")&&-1==this.name.indexOf("version")&&-1==this.name.indexOf("schdays")&&-1==this.name.indexOf("countryid")&&-1==this.name.indexOf("cityid")&&(b[this.name]=this.value||"")});for(var a,d=1;6>d;d++){a=[],$j.each($j("input[name='vpnmgr_vpn"+d+"_schdays']:checked"),function(){a.push($j(this).val())});var e=a.join(",");"Mon,Tues,Wed,Thurs,Fri,Sat,Sun"==e&&(e="*"),b["vpnmgr_vpn"+d+"_schdays"]=e,""==$j("select[name='vpnmgr_vpn"+d+"_countryname']").val()||"PIA"==$j("input[name='vpnmgr_vpn"+d+"_provider']:checked").val()?(b["vpnmgr_vpn"+d+"_countryid"]=0,b["vpnmgr_vpn"+d+"_cityid"]=0):""==$j("select[name='vpnmgr_vpn"+d+"_countryname']").val()||"WeVPN"==$j("input[name='vpnmgr_vpn"+d+"_provider']:checked").val()?(b["vpnmgr_vpn"+d+"_countryid"]=0,b["vpnmgr_vpn"+d+"_cityid"]=0):(b["vpnmgr_vpn"+d+"_countryid"]=nordvpncountries.filter(function(a){return a.name==$j("select[name='vpnmgr_vpn"+d+"_countryname']").val()}).map(function(a){return a.id})[0],b["vpnmgr_vpn"+d+"_cityid"]=""==$j("select[name='vpnmgr_vpn"+d+"_cityname']").val()?0:nordvpncountries.filter(function(a){return a.name==$j("select[name='vpnmgr_vpn"+d+"_countryname']").val()})[0].cities.filter(function(a){return a.name==$j("select[name='vpnmgr_vpn"+d+"_cityname']").val()}).map(function(a){return a.id})[0])}return b};function ScriptUpdateLayout(){var a=GetVersionNumber("local"),b=GetVersionNumber("server");$j("#vpnmgr_version_local").text(a),a!=b&&"N/A"!=b&&($j("#vpnmgr_version_server").text("Updated version available: "+b),showhide("btnChkUpdate",!1),showhide("vpnmgr_version_server",!0),showhide("btnDoUpdate",!0))}function update_status(){$j.ajax({url:"/ext/vpnmgr/detect_update.js",dataType:"script",timeout:3e3,error:function(){setTimeout(update_status,1e3)},success:function(){"InProgress"==updatestatus?setTimeout(update_status,1e3):(document.getElementById("imgChkUpdate").style.display="none",showhide("vpnmgr_version_server",!0),"None"==updatestatus?($j("#vpnmgr_version_server").text("No update available"),showhide("btnChkUpdate",!0),showhide("btnDoUpdate",!1)):($j("#vpnmgr_version_server").text("Updated version available: "+updatestatus),showhide("btnChkUpdate",!1),showhide("btnDoUpdate",!0)))}})}function CheckUpdate(){showhide("btnChkUpdate",!1),document.formScriptActions.action_script.value="start_vpnmgrcheckupdate",document.formScriptActions.submit(),document.getElementById("imgChkUpdate").style.display="",setTimeout(update_status,2e3)}function DoUpdate(){document.form.action_script.value="start_vpnmgrdoupdate";document.form.action_wait.value=10,showLoading(),document.form.submit()}function RefreshCachedData(){showhide("btnRefreshCachedData",!1),document.formScriptActions.action_script.value="start_vpnmgrrefreshcacheddata",document.formScriptActions.submit(),showhide("imgRefreshCachedData",!0),showhide("refreshcacheddata_text",!1),setTimeout(StartRefreshCachedDataInterval,1e3)}var myinterval;function StartRefreshCachedDataInterval(){myinterval=setInterval(refreshcacheddata_status,1e3)}var refreshcount=1;function refreshcacheddata_status(){refreshcount++,$j.ajax({url:"/ext/vpnmgr/detect_vpnmgr.js",dataType:"script",timeout:1e3,error:function(){},success:function(){"InProgress"==refreshcacheddatastatus?(showhide("imgRefreshCachedData",!0),showhide("refreshcacheddata_text",!0),document.getElementById("refreshcacheddata_text").innerHTML="Cached data refresh in progress - "+refreshcount+"s elapsed"):"Done"==refreshcacheddatastatus?(document.getElementById("refreshcacheddata_text").innerHTML="Refreshing data...",refreshcount=1,clearInterval(myinterval),PostRefreshCachedData()):"LOCKED"==refreshcacheddatastatus&&(showhide("imgRefreshCachedData",!1),document.getElementById("refreshcacheddata_text").innerHTML="Cached data refresh already running!",showhide("refreshcacheddata_text",!0),showhide("btnRefreshCachedData",!0),clearInterval(myinterval))}})}function PostRefreshCachedData(){for(var a=1;6>a;a++)$j("#table_config_vpn"+a).prev("div").remove(),$j("#table_config_vpn"+a).remove();setTimeout(getNordVPNCountryData,3e3)}function GetVersionNumber(a){var b;return"local"==a?b=custom_settings.vpnmgr_version_local:"server"==a&&(b=custom_settings.vpnmgr_version_server),"undefined"==typeof b||null==b?"N/A":b}function getNordVPNCountryData(){$j.ajax({url:"/ext/vpnmgr/nordvpn_countrydata.htm",dataType:"json",error:function(){setTimeout(getNordVPNCountryData,1e3)},success:function(a){nordvpncountries=a,getPIACountryData()}})}function getPIACountryData(){$j.ajax({url:"/ext/vpnmgr/pia_countrydata.htm",dataType:"text",error:function(){setTimeout(getPIACountryData,1e3)},success:function(a){piacountries=parseCountryData(a),getWeVPNCountryData()}})}function getWeVPNCountryData(){$j.ajax({url:"/ext/vpnmgr/wevpn_countrydata.htm",dataType:"text",error:function(){setTimeout(getWeVPNCountryData,1e3)},success:function(a){wevpncountries=parseCountryData(a),get_conf_file()}})}function parseCountryData(a){var b=[],c=[];c=a.split("\n"),c=c.filter(Boolean);var d=[],e=[],f=[],g=[],h=[],i=[],j=[],k=[],l=[],m=[],n=[],o=[],p=[],q=[],r=[],s=[],t=[],u=[],v=[],w=[],x=[],y=[],z=[],A=[],B=[],C=[],D=[],E=[],F=[],G=[],H=[],I=[],J=[];$j.each(c,function(a,b){if("AU"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("AU ","")),e.push(c),b="Australia"}else if("CA"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("CA ","")),f.push(c),b="Canada"}else if("DE"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("DE ","")),g.push(c),b="Germany"}else if("US"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("US ","")),h.push(c),b="United States"}else if("AT"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("AT ","")),k.push(c),b="Austria"}else if("BE"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("BE ","")),l.push(c),b="Belgium"}else if("BG"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("BG ","")),m.push(c),b="Bulgaria"}else if("BR"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("BR ","")),n.push(c),b="Brazil"}else if("CH"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("CH ","")),o.push(c),b="Switzerland"}else if("CZ"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("CZ ","")),p.push(c),b="Czech Republic"}else if("DK"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("DK ","")),q.push(c),b="Denmark"}else if("ES"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("ES ","")),r.push(c),b="Spain"}else if("FR"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("FR ","")),s.push(c),b="France"}else if("HK"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("HK ","")),t.push(c),b="Hong Kong"}else if("HU"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("HU ","")),u.push(c),b="Hungary"}else if("IE"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("IE ","")),v.push(c),b="Ireland"}else if("IL"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("IL ","")),w.push(c),b="Israel"}else if("IN"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("IN ","")),x.push(c),b="India"}else if("IT"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("IT ","")),y.push(c),b="Italy"}else if("JP"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("JP ","")),z.push(c),b="Japan"}else if("MX"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("MX ","")),A.push(c),b="Mexico"}else if("NL"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("NL ","")),B.push(c),b="Netherlands"}else if("NO"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("NO ","")),C.push(c),b="Norway"}else if("NZ"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("NZ ","")),D.push(c),b="New Zealand"}else if("PL"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("PL ","")),E.push(c),b="Poland"}else if("RO"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("RO ","")),F.push(c),b="Romania"}else if("RS"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("RS ","")),G.push(c),b="Serbia"}else if("SE"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("SE ","")),H.push(c),b="Sweden"}else if("SG"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("SG ","")),I.push(c),b="Singapore"}else if("UAE"==getCountryCode(b)||"AE"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("UAE ","").replaceAll("AE ","")),i.push(c),b="United Arab Emirates"}else if("UK"==getCountryCode(b)||"GB"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("UK ","").replaceAll("GB ","")),j.push(c),b="United Kingdom"}else if("ZA"==getCountryCode(b)){var c={};c.name=capitalizeFirstLetter(b.replaceAll("_"," ").replaceAll("ZA ","")),J.push(c),b="South Africa"}else b=capitalizeFirstLetter(b.replaceAll("_"," "));d.push(b)}),d.sort();var K=[];for(let c=0;c<d.length;c++)if(!K[d[c]]){var L={};L.name=d[c],b.push(L),K[d[c]]=1}return $j.each(b,function(a,b){b.cities="Australia"==b.name?e:"Canada"==b.name?f:"Germany"==b.name?g:"United States"==b.name?h:"United Arab Emirates"==b.name?i:"United Kingdom"==b.name?j:"Austria"==b.name?k:"Belgium"==b.name?l:"Bulgaria"==b.name?m:"Brazil"==b.name?n:"Switzerland"==b.name?o:"Czech Republic"==b.name?p:"Denmark"==b.name?q:"Spain"==b.name?r:"France"==b.name?s:"Hong Kong"==b.name?t:"Hungary"==b.name?u:"Ireland"==b.name?v:"Israel"==b.name?w:"India"==b.name?x:"Italy"==b.name?y:"Japan"==b.name?z:"Mexico"==b.name?A:"Netherlands"==b.name?B:"Norway"==b.name?C:"New Zealand"==b.name?D:"Poland"==b.name?E:"Romania"==b.name?F:"Serbia"==b.name?G:"Sweden"==b.name?H:"Singapore"==b.name?I:"South Africa"==b.name?J:[]}),b}function setCitiesforCountry(forminput){var inputname=forminput.name,inputvalue=forminput.value,prefix=inputname.substring(0,inputname.lastIndexOf("_"));let dropdown=$j("select[name="+prefix+"_cityname]");dropdown.empty(),"NordVPN"==eval("document.form."+prefix+"_provider").value?(dropdown.append("<option selected=\"true\"></option>"),cityarray=nordvpncountries):"PIA"==eval("document.form."+prefix+"_provider").value?cityarray=piacountries:"WeVPN"==eval("document.form."+prefix+"_provider").value&&(cityarray=wevpncountries),$j.each(cityarray,function(a,b){return b.name!=$j("select[name="+prefix+"_countryname]").val()||($j.each(b.cities,function(a,b){dropdown.append($j("<option></option>").attr("value",b.name).text(b.name))}),2==dropdown[0].length&&0==dropdown.find("option:first-child").val().length?dropdown.prop("selectedIndex",0):dropdown.prop("selectedIndex",0),!1)}),""==inputvalue?dropdown.prop("disabled",!0):""!=inputvalue&&dropdown.prop("disabled",!1),0==dropdown[0].length?dropdown.prop("disabled",!0):dropdown.prop("disabled",!1)}function capitalizeFirstLetter(a){return a.replace(/(^\w{1})|(\s{1}\w{1})/g,a=>a.toUpperCase())}function getCountryCode(a){return a=a.replaceAll(" ","_"),-1==a.indexOf("_")?a.toUpperCase():a.substring(0,a.indexOf("_")).toUpperCase()}String.prototype.replaceAll=function(a,b){var c=a.replace(/[-\/\\^$*+?.()|[\]{}]/g,"\\$&"),d=new RegExp(c,"ig");return this.replace(d,b)};
</script>
</head>
<body onload="initial();" onunload="return unload_body();">
<div id="TopBanner"></div>
<div id="Loading" class="popup_bg"></div>
<iframe name="hidden_frame" id="hidden_frame" src="about:blank" width="0" height="0" frameborder="0"></iframe>
<form method="post" name="form" id="ruleForm" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="modified" value="0">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_wait" value="15">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="action_script" value="start_vpnmgr">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="vpn1_desc" value="<% nvram_get("vpn_client1_desc"); %>">
<input type="hidden" name="vpn2_desc" value="<% nvram_get("vpn_client2_desc"); %>">
<input type="hidden" name="vpn3_desc" value="<% nvram_get("vpn_client3_desc"); %>">
<input type="hidden" name="vpn4_desc" value="<% nvram_get("vpn_client4_desc"); %>">
<input type="hidden" name="vpn5_desc" value="<% nvram_get("vpn_client5_desc"); %>">
<input type="hidden" name="vpn1_usn" value="<% nvram_clean_get("vpn_client1_username"); %>">
<input type="hidden" name="vpn2_usn" value="<% nvram_clean_get("vpn_client2_username"); %>">
<input type="hidden" name="vpn3_usn" value="<% nvram_clean_get("vpn_client3_username"); %>">
<input type="hidden" name="vpn4_usn" value="<% nvram_clean_get("vpn_client4_username"); %>">
<input type="hidden" name="vpn5_usn" value="<% nvram_clean_get("vpn_client5_username"); %>">
<input type="hidden" name="vpn1_pwd" value="<% nvram_clean_get("vpn_client1_password"); %>">
<input type="hidden" name="vpn2_pwd" value="<% nvram_clean_get("vpn_client2_password"); %>">
<input type="hidden" name="vpn3_pwd" value="<% nvram_clean_get("vpn_client3_password"); %>">
<input type="hidden" name="vpn4_pwd" value="<% nvram_clean_get("vpn_client4_password"); %>">
<input type="hidden" name="vpn5_pwd" value="<% nvram_clean_get("vpn_client5_password"); %>">
<input type="hidden" name="amng_custom" id="amng_custom" value="">
<table class="content" align="center" cellpadding="0" cellspacing="0">
<tr>
<td width="17">&nbsp;</td>
<td valign="top" width="202">
<div id="mainMenu"></div>
<div id="subMenu"></div></td>
<td valign="top">
<div id="tabMenu" class="submenuBlock"></div>
<table width="98%" border="0" align="left" cellpadding="0" cellspacing="0">
<tr>
<td align="left" valign="top">
<table width="760px" border="0" cellpadding="5" cellspacing="0" bordercolor="#6b8fa3" class="FormTitle" id="FormTitle">
<tr>
<td bgcolor="#4D595D" colspan="3" valign="top">
<div>&nbsp;</div>
<div class="formfonttitle" id="scripttitle" style="text-align:center;">vpnmgr</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">Management of your VPN Client connections for various VPN providers</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_scripttools">
<thead class="collapsible-jquery" id="scripttools">
<tr><td colspan="2">Utilities (click to expand/collapse)</td></tr>
</thead>
<tr>
<th width="20%">Version information</th>
<td>
<span id="vpnmgr_version_local" style="color:#FFFFFF;"></span>
&nbsp;&nbsp;&nbsp;
<span id="vpnmgr_version_server" style="display:none;">Update version</span>
&nbsp;&nbsp;&nbsp;
<input type="button" class="button_gen" onclick="CheckUpdate();" value="Check" id="btnChkUpdate">
<img id="imgChkUpdate" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
<input type="button" class="button_gen" onclick="DoUpdate();" value="Update" id="btnDoUpdate" style="display:none;">
&nbsp;&nbsp;&nbsp;
</td>
</tr>
<tr>
<th width="20%">Cached data</th>
<td>
<input type="button" class="button_gen" onclick="RefreshCachedData();" value="Refresh" id="btnRefreshCachedData">
<img id="imgRefreshCachedData" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
&nbsp;&nbsp;&nbsp;
<span id="refreshcacheddata_text" style="display:none;">Cached data updated</span>
</td>
</tr>

<tr>
<th width="20%">Show VPN server load in client description
<span style="color:#FFCC00;">(NordVPN servers only)</span>
</th>
<td>
<input type="button" class="button_gen" onclick="GetServerLoad();" value="Load" id="btnGetServerLoad">
<img id="imgGetServerLoad" style="display:none;vertical-align:middle;" src="images/InternetScan.gif"/>
<span id="getserverload_text" style="display:none;">Server loads retrieved, see client descriptions</span>
</td>
</tr>


</table>
<div style="line-height:10px;">&nbsp;</div>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons">
<tr class="apply_gen" valign="top" height="35px">
<td style="background-color:rgb(77, 89, 93);border:0px;">
<input name="button" type="button" class="button_gen" onclick="SaveConfig();" value="Save"/>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</form>
<form method="post" name="formScriptActions" action="/start_apply.htm" target="hidden_frame">
<input type="hidden" name="productid" value="<% nvram_get("productid"); %>">
<input type="hidden" name="current_page" value="">
<input type="hidden" name="next_page" value="">
<input type="hidden" name="action_mode" value="apply">
<input type="hidden" name="action_script" value="">
<input type="hidden" name="action_wait" value="">
</form>
<div id="footer"></div>
</body>
</html>
