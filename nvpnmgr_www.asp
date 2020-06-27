<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="X-UA-Compatible" content="IE=Edge"/>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="Pragma" content="no-cache">
<meta http-equiv="Expires" content="-1">
<link rel="shortcut icon" href="images/favicon.png">
<link rel="icon" href="images/favicon.png">
<title>NordVPN Manager</title>
<link rel="stylesheet" type="text/css" href="index_style.css">
<link rel="stylesheet" type="text/css" href="form_style.css">
<style>
p {
font-weight: bolder;
}

thead.collapsible {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
}

thead.collapsibleparent {
  color: white;
  padding: 0px;
  width: 100%;
  border: none;
  text-align: left;
  outline: none;
  cursor: pointer;
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

.collapsiblecontent {
  padding: 0px;
  max-height: 0;
  overflow: hidden;
  border: none;
  transition: max-height 0.2s ease-out;
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
<script language="JavaScript" type="text/javascript" src="/ext/shared-jy/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/validator.js"></script>
<script language="JavaScript" type="text/javascript" src="/base64.js"></script>
<script>
var $j = jQuery.noConflict();
var custom_settings;
var daysofweek = ["Mon","Tues","Wed","Thurs","Fri","Sat","Sun"];

function LoadCustomSettings(){
	custom_settings = <% get_custom_settings(); %>;
	for (var prop in custom_settings) {
		if (Object.prototype.hasOwnProperty.call(custom_settings, prop)) {
			if(prop.indexOf("nvpnmgr") != -1 && prop.indexOf("version") == -1){
				eval("delete custom_settings."+prop)
			}
		}
	}
}

function SettingHint(hintid) {
	var tag_name = document.getElementsByTagName('a');
	for (var i=0;i<tag_name.length;i++){
		tag_name[i].onmouseout=nd;
	}
	hinttext="My text goes here";
	if(hintid == 1) hinttext="Manage VPN client using nvpnmgr";
	if(hintid == 2) hinttext="Protocol to use for VPN server";
	if(hintid == 3) hinttext="Type of NordVPN server to use";
	if(hintid == 4) hinttext="Country of NordVPN server to use";
	if(hintid == 5) hinttext="City of NordVPN server to use";
	if(hintid == 6) hinttext="Automatically update VPN to new NordVPN recommended server";
	if(hintid == 7) hinttext="Day(s) of week to check for new recommended server";
	if(hintid == 8) hinttext="Hour(s) of day to check for new recommended server (* for all, 0-23. Comma separate for multiple hours.)";
	if(hintid == 9) hinttext="Minute(s) of hour to check for new recommended server (* for all, 0-59. Comma separate for multiple minutes.)";
	return overlib(hinttext, HAUTO, VAUTO);
}

function OptionsEnableDisable(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value;
	var prefix = inputname.substring(0,inputname.lastIndexOf('_'));
	
	if(inputvalue == "false"){
		$j('input[name='+prefix+'_protocol]').prop("disabled",true);
		$j('input[name='+prefix+'_type]').prop("disabled",true);
		$j('select[name='+prefix+'_countryname]').prop("disabled",true);
		$j('select[name='+prefix+'_cityname]').prop("disabled",true);
		$j('input[name='+prefix+'_schenabled]').prop("disabled",true);
		$j('input[name='+prefix+'_schhours]').addClass("disabled");
		$j('input[name='+prefix+'_schhours]').prop("disabled",true);
		$j('input[name='+prefix+'_schmins]').addClass("disabled");
		$j('input[name='+prefix+'_schmins]').prop("disabled",true);
		for (var i = 0; i < daysofweek.length; i++) {
			$j('#'+prefix+'_'+daysofweek[i].toLowerCase()).prop("disabled",true);
		}
	}
	else if(inputvalue == "true"){
		$j('input[name='+prefix+'_protocol]').prop("disabled",false);
		$j('input[name='+prefix+'_type]').prop("disabled",false);
		$j('select[name='+prefix+'_countryname]').prop("disabled",false);
		$j('select[name='+prefix+'_cityname]').prop("disabled",false);
		$j('input[name='+prefix+'_schenabled]').prop("disabled",false);
		$j('input[name='+prefix+'_schhours]').removeClass("disabled");
		$j('input[name='+prefix+'_schhours]').prop("disabled",false);
		$j('input[name='+prefix+'_schmins]').removeClass("disabled");
		$j('input[name='+prefix+'_schmins]').prop("disabled",false);
		for (var i = 0; i < daysofweek.length; i++) {
			$j('#'+prefix+'_'+daysofweek[i].toLowerCase()).prop("disabled",false);
		}
	}
}

function ScheduleOptionsEnableDisable(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value;
	var prefix = inputname.substring(0,inputname.lastIndexOf('_'));
	
	if(inputvalue == "false"){
		$j('input[name='+prefix+'_schhours]').addClass("disabled");
		$j('input[name='+prefix+'_schhours]').prop("disabled",true);
		$j('input[name='+prefix+'_schmins]').addClass("disabled");
		$j('input[name='+prefix+'_schmins]').prop("disabled",true);
		for (var i = 0; i < daysofweek.length; i++) {
			$j('#'+prefix+'_'+daysofweek[i].toLowerCase()).prop("disabled",true);
		}
	}
	else if(inputvalue == "true"){
		$j('input[name='+prefix+'_schhours]').removeClass("disabled");
		$j('input[name='+prefix+'_schhours]').prop("disabled",false);
		$j('input[name='+prefix+'_schmins]').removeClass("disabled");
		$j('input[name='+prefix+'_schmins]').prop("disabled",false);
		for (var i = 0; i < daysofweek.length; i++) {
			$j('#'+prefix+'_'+daysofweek[i].toLowerCase()).prop("disabled",false);
		}
	}
}

function Validate_Schedule(forminput,hoursmins){
	var inputname = forminput.name;
	var inputvalues = forminput.value.split(',');
	var upperlimit = 0;
	
	if(hoursmins == "hours"){
		upperlimit = 23;
	}
	else if (hoursmins == "mins"){
		upperlimit = 59;
	}
	
	var validationfailed = "false";
	for(var i=0; i < inputvalues.length; i++){
		if(inputvalues[i] == "*" && i == 0){
			validationfailed = "false";
		}
		else if(inputvalues[i] == "*" && i != 0){
			validationfailed = "true";
		}
		else if(inputvalues[0] == "*" && i > 0){
			validationfailed = "true";
		}
		else if(inputvalues[i] == ""){
			validationfailed = "true";
		}
		else if(! isNaN(inputvalues[i]*1)){
			if((inputvalues[i]*1) > upperlimit || (inputvalues[i]*1) < 0){
				validationfailed = "true";
			}
		}
		else{
			validationfailed = "true";
		}
	}
	
	if(validationfailed == "true"){
		$j(forminput).addClass("invalid");
		return false;
	}
	else{
		$j(forminput).removeClass("invalid");
		return true;
	}
}

function Validate_All(){
	var validationfailed = false;
	for(var i=1; i < 6; i++){
		if(! Validate_Schedule(eval("document.form.nvpnmgr_vpn"+i+"_schhours"),"hours")) validationfailed=true;
		if(! Validate_Schedule(eval("document.form.nvpnmgr_vpn"+i+"_schmins"),"mins")) validationfailed=true;
	}
	if(validationfailed){
		alert("Validation for some fields failed. Please correct invalid values and try again.");
		return false;
	}
	else{
		return true;
	}
}

function get_conf_file(){
	$j.ajax({
		url: '/ext/nvpnmgr/config.htm',
		dataType: 'text',
		error: function(xhr){
			setTimeout("get_conf_file();", 1000);
		},
		success: function(data){
			var settings = data.split("\n");
			settings.reverse();
			settings = settings.filter(Boolean);
			var settingcount = settings.length;
			window["nvpnmgr_settings"] = new Array();
			for (var i = 0; i < settingcount; i++) {
				var commentstart=settings[i].indexOf("#");
				if (commentstart != -1){
					continue
				}
				var setting = settings[i].split("=");
				window["nvpnmgr_settings"].unshift(setting);
				}
				for (var vpnno = 1; vpnno < 6; vpnno++){
					$j("#table_buttons").before(BuildConfigTable("vpn"+vpnno,"VPN Client "+vpnno));
				
					let dropdown = $j('#nvpnmgr_vpn'+vpnno+'_countryname');
					dropdown.empty();
					dropdown.append('<option selected="true"></option>');
					dropdown.prop('selectedIndex', 0);
					$j.each(countryjson, function (key, entry) {
						dropdown.append($j('<option></option>').attr('value', entry.name).text(entry.name));
					});
				}
				
				for (var i = 0; i < 55; i++) {
					let settingname = window["nvpnmgr_settings"][i][0];
					let settingvalue = window["nvpnmgr_settings"][i][1];
					if(settingname.indexOf("cityid") != -1 || settingname.indexOf("countryid") != -1) continue;
					if(settingname.indexOf("schdays") == -1){
						eval("document.form.nvpnmgr_"+settingname).value = settingvalue;
						if(settingname.indexOf("managed") != -1) OptionsEnableDisable($j("#nvpnmgr_"+settingname.replace("_managed","")+"_man_"+settingvalue)[0]);
						if(settingname.indexOf("schenabled") != -1) ScheduleOptionsEnableDisable($j("#nvpnmgr_"+settingname.replace("_schenabled","")+"_sch_"+settingvalue)[0]);
						if(settingname.indexOf("cityname") != -1){
							let dropdown = $j('#nvpnmgr_'+settingname);
							dropdown.empty();
							dropdown.append('<option selected="true"></option>');
							dropdown.prop('selectedIndex', 0);
							$j.each(countryjson, function (key, entry) {
								if(entry.name != window["nvpnmgr_settings"][i-1][1]){
									return true;
								}
								else {
									$j.each(entry.cities, function (key2, entry2) {
										dropdown.append($j('<option></option>').attr('value', entry2.name).text(entry2.name));
									});
									eval("document.form.nvpnmgr_"+settingname).value = settingvalue;
									return false;
								}
							});
						}
						if(settingname.indexOf("countryname") != -1){
							if(settingvalue == ""){
								$j('#nvpnmgr_'+window["nvpnmgr_settings"][i+1][0]).prop("disabled",true);
							}
							else if(settingvalue != ""){
								$j('#nvpnmgr_'+window["nvpnmgr_settings"][i+1][0]).prop("disabled",false);
							}
						}
					}
					else {
						if(settingvalue == "*"){
							for (var i2 = 0; i2 < daysofweek.length; i2++) {
								$j("#nvpnmgr_"+settingname.substring(0,nvpnmgr_settings[i][0].indexOf('_'))+"_"+daysofweek[i2].toLowerCase()).prop("checked",true);
							}
						}
						else {
							var schdayarray = settingvalue.split(',');
							for (var i2 = 0; i2 < schdayarray.length; i2++) {
								$j("#nvpnmgr_"+settingname.substring(0,nvpnmgr_settings[i][0].indexOf('_'))+"_"+schdayarray[i2].toLowerCase()).prop("checked",true);
							}
						}
					}
				}
				AddEventHandlers();
			}
	});
}

function GetCookie(cookiename) {
	var s;
	if ((s = cookie.get("nvpnmgr_"+cookiename)) != null) {
		return cookie.get("nvpnmgr_"+cookiename);
	}
	else {
		return "";
	}
}

function SetCookie(cookiename,cookievalue) {
	cookie.set("nvpnmgr_"+cookiename, cookievalue, 31);
}

function SetCurrentPage(){
	document.form.next_page.value = window.location.pathname.substring(1);
	document.form.current_page.value = window.location.pathname.substring(1);
}

function reload() {
	location.reload(true);
}

function applyRule() {
	if(Validate_All()){
		$j('[name*=nvpnmgr_]').prop("disabled",false);
		document.getElementById('amng_custom').value = JSON.stringify($j('form').serializeObject());
		var action_script_tmp = "start_nvpnmgr";
		document.form.action_script.value = action_script_tmp;
		var restart_time = 30;
		document.form.action_wait.value = restart_time;
		showLoading();
		document.form.submit();
	}
	else {
		return false;
	}
}

function initial(){
	SetCurrentPage();
	LoadCustomSettings();
	show_menu();
	getCountryData();
	get_conf_file();
	ScriptUpdateLayout();
}

function BuildConfigTable(prefix,title){
	var charthtml = '<div style="line-height:10px;">&nbsp;</div>';
	charthtml+='<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" id="table_config_'+prefix+'">';
	charthtml+='<thead class="collapsible-jquery" id="'+prefix+'">';
	charthtml+='<tr>';
	charthtml+='<td colspan="2">'+title+' Configuration (click to expand/collapse)</td>';
	charthtml+='</tr>';
	charthtml+='</thead>';
	charthtml+='<div class="collapsiblecontent">';
	charthtml+='<tr>';
	charthtml+='<td colspan="2" align="center" style="padding: 0px;">';
	
	charthtml+='<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable SettingsTable">';
	charthtml+='<col style="width:35%;">';
	charthtml+='<col style="width:65%;">';
	
	/* DESCRIPTION */
	charthtml+='<tr>';
	charthtml+='<td class="settingname">Description</a></td><td class="settingvalue"><span id="nvpnmgr_'+prefix+'_desc" style="color:#ffffff;">'+$j('input[name='+prefix+'_desc]').val()+'</span></td>';
	charthtml+='</tr>';
	
	/* MANAGEMENT ENABLED */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(1);">Managed by nvpnmgr?</a></td><td class="settingvalue"><input autocomplete="off" autocapitalize="off" type="radio" onchange="OptionsEnableDisable(this)" name="nvpnmgr_'+prefix+'_managed" id="nvpnmgr_'+prefix+'_man_true" class="input" value="true"><label for="nvpnmgr_'+prefix+'_man_true">Yes</label><input autocomplete="off" autocapitalize="off" type="radio"  onchange="OptionsEnableDisable(this)" name="nvpnmgr_'+prefix+'_managed" id="nvpnmgr_'+prefix+'_man_false" class="input" value="false" checked><label for="nvpnmgr_'+prefix+'_man_false">No</label></td>';
	charthtml+='</tr>';
	
	/* PROTOCOL */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(2);">Protocol</a></td><td class="settingvalue"><input autocomplete="off" autocapitalize="off" type="radio" name="nvpnmgr_'+prefix+'_protocol" id="nvpnmgr_'+prefix+'_tcp" class="input" value="TCP"><label for="nvpnmgr_'+prefix+'_tcp">TCP</label><input autocomplete="off" autocapitalize="off" type="radio" name="nvpnmgr_'+prefix+'_protocol" id="nvpnmgr_'+prefix+'_udp" class="input" value="UDP" checked><label for="nvpnmgr_'+prefix+'_udp">UDP</label></td>';
	charthtml+='</tr>';
	
	/* TYPE */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(3);">Type</a></td><td class="settingvalue"><input autocomplete="off" autocapitalize="off" type="radio" name="nvpnmgr_'+prefix+'_type" id="nvpnmgr_'+prefix+'_standard" class="input" value="Standard" checked><label for="nvpnmgr_'+prefix+'_standard">Standard</label><input autocomplete="off" autocapitalize="off" type="radio" name="nvpnmgr_'+prefix+'_type" for="nvpnmgr_'+prefix+'_double" class="input" value="Double"><label for="nvpnmgr_'+prefix+'_double">Double</label><input autocomplete="off" autocapitalize="off" type="radio" name="nvpnmgr_'+prefix+'_type" id="nvpnmgr_'+prefix+'_p2p" class="input" value="P2P"><label for="nvpnmgr_'+prefix+'_p2p">P2P</label></td>';
	charthtml+='</tr>';
	
	/* COUNTRY */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(4);">Country</a></td><td class="settingvalue"><select name="nvpnmgr_'+prefix+'_countryname" id="nvpnmgr_'+prefix+'_countryname" onChange="setCitiesforCountry(this)"></select></td>';
	charthtml+='</tr>';
	
	/* CITY */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(5);">City</a></td><td class="settingvalue"><select name="nvpnmgr_'+prefix+'_cityname" id="nvpnmgr_'+prefix+'_cityname"></select></td>';
	charthtml+='</tr>';
	
	/* SCHEDULE ENABLED */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(6);">Scheduled update?</a></td><td class="settingvalue"><input autocomplete="off" autocapitalize="off" type="radio" onchange="ScheduleOptionsEnableDisable(this)" name="nvpnmgr_'+prefix+'_schenabled" id="nvpnmgr_'+prefix+'_sch_true" class="input" value="true"><label for="nvpnmgr_'+prefix+'_sch_true">Yes</label><input autocomplete="off" autocapitalize="off" type="radio"  onchange="ScheduleOptionsEnableDisable(this)" name="nvpnmgr_'+prefix+'_schenabled" id="nvpnmgr_'+prefix+'_sch_false" class="input" value="false" checked><label for="nvpnmgr_'+prefix+'_sch_false">No</label></td>';
	charthtml+='</tr>';
	
	/* SCHEDULE DAYS */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(7);">Schedule Days</a></td><td class="settingvalue">';
	charthtml+='<input autocomplete="off" autocapitalize="off" type="checkbox" name="nvpnmgr_'+prefix+'_schdays" id="nvpnmgr_'+prefix+'_mon" class="input" value="Mon"><label for="nvpnmgr_'+prefix+'_mon">Mon</label>';
	charthtml+='<input autocomplete="off" autocapitalize="off" type="checkbox" name="nvpnmgr_'+prefix+'_schdays" id="nvpnmgr_'+prefix+'_tues" class="input" value="Tues"><label for="nvpnmgr_'+prefix+'_tues">Tues</label>';
	charthtml+='<input autocomplete="off" autocapitalize="off" type="checkbox" name="nvpnmgr_'+prefix+'_schdays" id="nvpnmgr_'+prefix+'_wed" class="input" value="Wed"><label for="nvpnmgr_'+prefix+'_wed">Wed</label>';
	charthtml+='<input autocomplete="off" autocapitalize="off" type="checkbox" name="nvpnmgr_'+prefix+'_schdays" id="nvpnmgr_'+prefix+'_thurs" class="input" value="Thurs"><label for="nvpnmgr_'+prefix+'_thurs">Thurs</label>';
	charthtml+='<input autocomplete="off" autocapitalize="off" type="checkbox" name="nvpnmgr_'+prefix+'_schdays" id="nvpnmgr_'+prefix+'_fri" class="input" value="Fri"><label for="nvpnmgr_'+prefix+'_fri">Fri</label>';
	charthtml+='<input autocomplete="off" autocapitalize="off" type="checkbox" name="nvpnmgr_'+prefix+'_schdays" id="nvpnmgr_'+prefix+'_sat" class="input" value="Sat"><label for="nvpnmgr_'+prefix+'_sat">Sat</label>';
	charthtml+='<input autocomplete="off" autocapitalize="off" type="checkbox" name="nvpnmgr_'+prefix+'_schdays" id="nvpnmgr_'+prefix+'_sun" class="input" value="Sun"><label for="nvpnmgr_'+prefix+'_sun">Sun</label>';
	charthtml+='</td></tr>';
	
	/* SCHEDULE HOURS */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(8);">Schedule Hours</a></td><td class="settingvalue"><input data-lpignore="true" autocomplete="off" autocapitalize="off" type="text" class="input_32_table" name="nvpnmgr_'+prefix+'_schhours" value="*" onblur="Validate_Schedule(this,\'hours\')" /></td>';
	charthtml+='</tr>';
	
	/* SCHEDULE MINS */
	charthtml+='<tr>';
	charthtml+='<td class="settingname"><a class="hintstyle" href="javascript:void(0);" onclick="SettingHint(9);">Schedule Minutes</a></td><td class="settingvalue"><input data-lpignore="true" autocomplete="off" autocapitalize="off" type="text" class="input_32_table" name="nvpnmgr_'+prefix+'_schmins" value="*" onblur="Validate_Schedule(this,\'mins\')" /></td>';
	charthtml+='</tr>';
	
	charthtml+='</table>';
	charthtml+='</td>';
	charthtml+='</tr>';
	charthtml+='</div>';
	charthtml+='</table>';
	charthtml+='<div style="line-height:10px;">&nbsp;</div>';
	return charthtml;
}

function AddEventHandlers(){
	$j(".collapsible-jquery").click(function(){
		$j(this).siblings().toggle("fast",function(){
			if($j(this).css("display") == "none"){
				SetCookie($j(this).siblings()[0].id,"collapsed");
			}
			else {
				SetCookie($j(this).siblings()[0].id,"expanded");
			}
		})
	});
	
	$j(".collapsible-jquery").each(function(index,element){
		if(GetCookie($j(this)[0].id,"string") == "collapsed"){
			$j(this).siblings().toggle(false);
		}
		else {
			$j(this).siblings().toggle(true);
		}
	});
}

$j.fn.serializeObject = function(){
	var o = custom_settings;
	var a = this.serializeArray();
	$j.each(a, function() {
		if (o[this.name] !== undefined && this.name.indexOf("nvpnmgr") != -1 && this.name.indexOf("version") == -1 && this.name.indexOf("schdays") == -1) {
			if (!o[this.name].push) {
				o[this.name] = [o[this.name]];
			}
			o[this.name].push(this.value || '');
		} else if (this.name.indexOf("nvpnmgr") != -1 && this.name.indexOf("version") == -1 && this.name.indexOf("schdays") == -1){
			o[this.name] = this.value || '';
		}
	});
	for(var i=1; i < 6; i++){
		var schdays = [];
		$j.each($j("input[name='nvpnmgr_vpn"+i+"_schdays']:checked"), function(){
			schdays.push($j(this).val());
		});
		var schdaysstring = schdays.join(",");
		if(schdaysstring == "Mon,Tues,Wed,Thurs,Fri,Sat,Sun"){
			schdaysstring = "*";
		}
		o["nvpnmgr_vpn"+i+"_schdays"] = schdaysstring;
	}
	return o;
};

function ScriptUpdateLayout(){
	var localver = GetVersionNumber("local");
	var serverver = GetVersionNumber("server");
	$j("#scripttitle").text($j("#scripttitle").text()+" - "+localver);
	$j("#nvpnmgr_version_local").text(localver);
	
	if (localver != serverver && serverver != "N/A"){
		$j("#nvpnmgr_version_server").text("Updated version available: "+serverver);
		showhide("btnChkUpdate", false);
		showhide("nvpnmgr_version_server", true);
		showhide("btnDoUpdate", true);
	}
}

function CheckUpdate(){
	var action_script_tmp = "start_nvpnmgrcheckupdate";
	document.form.action_script.value = action_script_tmp;
	var restart_time = 10;
	document.form.action_wait.value = restart_time;
	showLoading();
	document.form.submit();
}

function DoUpdate(){
	var action_script_tmp = "start_nvpnmgrdoupdate";
	document.form.action_script.value = action_script_tmp;
	var restart_time = 20;
	document.form.action_wait.value = restart_time;
	showLoading();
	document.form.submit();
}

function GetVersionNumber(versiontype)
{
	var versionprop;
	if(versiontype == "local"){
		versionprop = custom_settings.nvpnmgr_version_local;
	}
	else if(versiontype == "server"){
		versionprop = custom_settings.nvpnmgr_version_server;
	}
	
	if(typeof versionprop == 'undefined' || versionprop == null){
		return "N/A";
	}
	else {
		return versionprop;
	}
}

var countryjson;
function getCountryData(){
	var request = async () => {
		var response = await fetch("/ext/nvpnmgr/nvpncountrydata.json");
		countryjson = await response.json();
	}
	request();
}

function setCitiesforCountry(forminput){
	var inputname = forminput.name;
	var inputvalue = forminput.value;
	var prefix = inputname.substring(0,inputname.lastIndexOf('_'));
	
	let dropdown = $j('select[name='+prefix+'_cityname]');
	dropdown.empty();
	dropdown.append('<option selected="true"></option>');
	dropdown.prop('selectedIndex', 0);
	$j.each(countryjson, function (key, entry) {
		if(entry.name != $j('select[name='+prefix+'_countryname]').val()){
			return true;
		}
		else {
			$j.each(entry.cities, function (key2, entry2) {
				dropdown.append($j('<option></option>').attr('value', entry2.name).text(entry2.name));
			});
			return false;
		}
	});
	if(inputvalue == ""){
		dropdown.prop("disabled",true);
	}
	else if(inputvalue != ""){
		dropdown.prop("disabled",false);
	}
}

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
<input type="hidden" name="action_wait" value="30">
<input type="hidden" name="first_time" value="">
<input type="hidden" name="SystemCmd" value="">
<input type="hidden" name="action_script" value="start_nvpnmgr">
<input type="hidden" name="preferred_lang" id="preferred_lang" value="<% nvram_get("preferred_lang"); %>">
<input type="hidden" name="firmver" value="<% nvram_get("firmver"); %>">
<input type="hidden" name="vpn1_desc" value="<% nvram_get("vpn_client1_desc"); %>">
<input type="hidden" name="vpn2_desc" value="<% nvram_get("vpn_client2_desc"); %>">
<input type="hidden" name="vpn3_desc" value="<% nvram_get("vpn_client3_desc"); %>">
<input type="hidden" name="vpn4_desc" value="<% nvram_get("vpn_client4_desc"); %>">
<input type="hidden" name="vpn5_desc" value="<% nvram_get("vpn_client5_desc"); %>">
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
<div class="formfonttitle" id="scripttitle" style="text-align:center;">nvpnmgr</div>
<div style="margin:10px 0 10px 5px;" class="splitLine"></div>
<div class="formfontdesc">Automatically update VPN Client configuration to recommended NordVPN server on AsusWRT-Merlin</div>
<table width="100%" border="1" align="center" cellpadding="2" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_scripttools">
<thead class="collapsible-jquery" id="scripttools">
<tr><td colspan="2">Script Utilities (click to expand/collapse)</td></tr>
</thead>
<div class="collapsiblecontent">
<tr>
<th width="20%">Version information</th>
<td>
<span id="nvpnmgr_version_local" style="color:#FFFFFF;"></span>
&nbsp;&nbsp;&nbsp;
<span id="nvpnmgr_version_server" style="display:none;">Update version</span>
&nbsp;&nbsp;&nbsp;
<input type="button" class="button_gen" onclick="CheckUpdate();" value="Check" id="btnChkUpdate">
<input type="button" class="button_gen" onclick="DoUpdate();" value="Update" id="btnDoUpdate" style="display:none;">
&nbsp;&nbsp;&nbsp;
</td>
</tr>
</div>
</table>
<table width="100%" border="1" align="center" cellpadding="4" cellspacing="0" bordercolor="#6b8fa3" class="FormTable" style="border:0px;" id="table_buttons">
<tr class="apply_gen" valign="top" height="35px">
<td style="background-color:rgb(77, 89, 93);border:0px;">
<input name="button" type="button" class="button_gen" onclick="applyRule();" value="Apply"/>
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
<div id="footer"></div>
</body>
</html>
