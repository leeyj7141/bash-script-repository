#!/bin/bash


CLUSTER=Default
NAME=$1
TEMPLATE=$2
DOMAIN=$3
ADMINPASSWORD=$4
ENGINEPASSWORD=$5
ENGINEADDR=$6

if [ $# -ne 6 ]
then
echo "사용법: sh `basename $0` <vmlist.txt> <템플릿이름> <도메인명> <administrator암호> <엔진암호> <엔진주소> 
예) : sh `basename $0` vmlist test_template test.dom 1 fnxmfnxm 192.168.21.20"
exit 
fi

for i in `cat $NAME`
do
ovirt-shell -E "add vm --name $i --template-name $TEMPLATE --cluster-name $CLUSTER"

VM_ID=`ovirt-shell -E "list vms --query name=${i}" |grep -i id |awk '{print $3}'`

sleep 3 

while  [ `ovirt-shell -E "show vm $i" |grep -i status |awk '{print $3}'` != "down" ]
do echo "VM $i is image_locked"
sleep 2 
done


cat - <<EOF > sysprep.inf
<vm>
  <payloads>
    <payload type="floppy">
    <files>
      <file>
        <name>sysprep.inf</name>
        <content><![CDATA[
<?xml version="1.0" encoding="UTF-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="windowsPE">
        <component name="Microsoft-Windows-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <UserData>
                <ProductKey>
                    <Key></Key>
                </ProductKey>
                <AcceptEula>true</AcceptEula>
                <FullName>"user"</FullName>
                <Organization>test.dom</Organization>
            </UserData>
            <ImageInstall>
                <OSImage>
                    <InstallToAvailablePartition>true</InstallToAvailablePartition>
                </OSImage>
            </ImageInstall>
        </component>
        <component name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <SetupUILanguage>
                <UILanguage>en_US</UILanguage>
            </SetupUILanguage>
            <InputLocale>en_US</InputLocale>
            <UILanguage>en_US</UILanguage>
            <SystemLocale>en_US</SystemLocale>
            <UserLocale>en_US</UserLocale>
        </component>
    </settings>
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Display>
                <ColorDepth>32</ColorDepth>
                <DPI>96</DPI>
                <HorizontalResolution>1024</HorizontalResolution>
                <RefreshRate>75</RefreshRate>
                <VerticalResolution>768</VerticalResolution>
            </Display>
            <ComputerName>test4</ComputerName>
            <TimeZone>Korea Standard Time</TimeZone>
        </component>
        <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en_US</InputLocale>
            <UserLocale>en_US</UserLocale>
            <SystemLocale>en_US</SystemLocale>
            <UILanguage>en_US</UILanguage>
        </component>
        <component name="Microsoft-Windows-UnattendedJoin" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Identification>
                <Credentials>
                    <Domain>test.dom</Domain>
                    <Password>1</Password>
                    <Username>administrator</Username>
                </Credentials>
                <JoinDomain>test.dom</JoinDomain>
                <MachineObjectOU></MachineObjectOU>
            </Identification>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-International-Core" processorArchitecture="x86" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <InputLocale>en_US</InputLocale>
            <UserLocale>en_US</UserLocale>
            <SystemLocale>en_US</SystemLocale>
            <UILanguage>en_US</UILanguage>
        </component>
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <OOBE>
                <ProtectYourPC>2</ProtectYourPC>
                <NetworkLocation>Work</NetworkLocation>
                <HideEULAPage>true</HideEULAPage>
            </OOBE>
            <UserAccounts>
                <AdministratorPassword>
                    <Value>1</Value>
                    <PlainText>true</PlainText>
                </AdministratorPassword>
                <LocalAccounts>
                    <LocalAccount wcm:action="add">
                        <Password>
                            <Value>1</Value>
                            <PlainText>true</PlainText>
                        </Password>
                        <Group>administrators</Group>
                        <Name>user</Name>
                        <DisplayName>user</DisplayName>
                    </LocalAccount>
                </LocalAccounts>
            </UserAccounts>
        </component>
    </settings>
    <cpi:offlineImage cpi:source="wim:d:/sources/install.wim#Windows 7 ENTERPRISE" xmlns:cpi="urn:schemas-microsoft-com:cpi"/>
</unattend>
]]>
        </content>
<type>BASE64</type>
      </file>
      </files>
    </payload>
  </payloads>
</vm>
EOF

sed -i "45s:<ComputerName>test4</ComputerName>:<ComputerName>${i}</ComputerName>:g" sysprep.inf
sed -i "57s:<Domain>test.dom</Domain>:<Domain>${DOMAIN}</Domain>:g" sysprep.inf
sed -i "61s:<JoinDomain>test.dom</JoinDomain>:<JoinDomain>${DOMAIN}</JoinDomain>:g" sysprep.inf
sed -i "81s:<Value>1</Value>:<Value>${PASSWORD}</Value>:g" sysprep.inf
sed -i "87s:<Value>1</Value>:<Value>${PASSWORD}</Value>:g" sysprep.inf

curl -X PUT -H "Accept: application/xml" -H "Content-Type: application/xml" -k -u admin@internal:${ENGINEPASSWORD} -d  @sysprep.inf  https://${ENGINEADDR}/api/vms/${VM_ID}

sleep 2 

ovirt-shell -E "action vm ${VM_ID} start"

if [ -f "sysprep.inf" ] 
then
rm -rf sysprep.inf
fi

done
