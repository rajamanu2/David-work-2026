from pathlib import Path
import re

root=Path(__file__).parent/'force-app/main/default'
p=root/'classes/EmailTableController.cls'
s=p.read_text()
old='ORDER BY SBQQ__Group__r.Allow_Product_Ramping__c ASC, SBQQ__Group__r.SBQQ__StartDate__c, SBQQ__Group__r.SBQQ__SubscriptionTerm__c DESC NULLS LAST, SBQQ__Group__r.Name ASC, SBQQ__RequiredBy__c ASC NULLS FIRST, SBQQ__ProductName__c ASC'
new='ORDER BY SBQQ__Group__r.SBQQ__StartDate__c ASC NULLS LAST, SBQQ__Group__r.SBQQ__SubscriptionTerm__c DESC NULLS LAST, SBQQ__Group__r.SBQQ__Number__c ASC NULLS LAST, SBQQ__Group__c ASC NULLS LAST, SBQQ__Number__c ASC NULLS LAST, Id ASC'
assert s.count(old)==1
s=s.replace(old,new)
p.write_text(s)
p=root/'permissionsets/CPQ_Sales_Permissions.permissionset-meta.xml'
s=p.read_text()
assert '<apexClass>EmailTableController</apexClass>' not in s
s=s.replace('<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">','<PermissionSet xmlns="http://soap.sforce.com/2006/04/metadata">\n    <classAccesses>\n        <apexClass>EmailTableController</apexClass>\n        <enabled>true</enabled>\n    </classAccesses>',1)
p.write_text(s)
p=root/'customMetadata/Email_Table.Quote_Approval_Field_5.md-meta.xml'
s=p.read_text()
s,n=re.subn(r'(<field>Column_Order__c</field>\s*<value[^>]*>)6(</value>)',r'\g<1>5\2',s)
assert n==1
p.write_text(s)
p=root/'classes/EmailTableControllerTest.cls'
s=p.read_text().replace('if (!groupedLines.isEmpty()) {',"System.assert(!groupedLines.isEmpty(), 'Expected quote lines must not be silently omitted.');\n        {")
extra=Path(__file__).with_name('additional_tests.txt').read_text()
assert s.rstrip().endswith('}')
p.write_text(s.rstrip()[:-1]+extra+'\n}\n')
print('Prepared four components from retrieved baseline.')
