<?php
  $user =  $_POST['user'];
  $domain = $_POST['domain'];
  $password = "1234";
?>

<document type="freeswitch/xml">
<section name="directory">
  <domain name="<?php echo $domain;?>">
    <params>
      <param name="dial-string" value="{presence_id=${dialed_user}@${dialed_domain}}${sofia_contact(${dialed_user}@${dialed_domain})}"/>
    </params>
    <groups>
    <group name="default">
      <users>
        <user id="<?php echo $user; ?>">
          <params>
            <param name="password" value="<?php echo $password; ?>"/>
            <param name="vm-password" value="<?php echo $password; ?>"/>
            </params>
          <variables>
            <variable name="toll_allow" value="domestic,international,local"/>
            <variable name="accountcode" value="<?php echo $user; ?>"/>
            <variable name="user_context" value="default"/>
            <variable name="effective_caller_id_name" value="FreeSWITCH-CN"/>
            <variable name="effective_caller_id_number" value="<?php echo $user;?>"/>
            <variable name="outbound_caller_id_name" value="$${outbound_caller_name}"/>
            <variable name="outbound_caller_id_number" value="$${outbound_caller_id}"/>
            <variable name="callgroup" value="default"/>
            <variable name="x-powered-by" value="http://www.freeswitch.org.cn"/>
          </variables>
        </user>
      </users>
    </group>
    </groups>
  </domain>
</section>
</document>
