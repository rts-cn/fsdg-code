freeswitch.consoleLog("NOTICE", "SECTION " .. XML_REQUEST["section"] .. "\n")

xml = [[

<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<document type="freeswitch/xml">
<section name="dialplan" description="RE Dial Plan For FreeSwitch">
  <context name="default">
    <extension name="9196">
      <condition field="destination_number" expression="^9196$">
        <action application="log" data="ERR I'm from Lua XML dialplan"/>
        <action application="answer"/>
        <action application="echo"/>
      </condition>
    </extension>
  </context>
</section>
</document>

]]

XML_STRING=xml
