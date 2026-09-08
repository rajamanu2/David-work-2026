"""GET-only evidence capture. Authentication remains in process memory."""
import json, os, subprocess, sys
from pathlib import Path
import urllib.request, urllib.parse

ROOT = Path(__file__).resolve().parent
env = os.environ.copy()
for key in ('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY'):
    env.pop(key, None)
env.update(SF_DISABLE_LOG_FILE='true', SF_AUTOUPDATE_DISABLE='true', SF_DISABLE_TELEMETRY='true')
proc = subprocess.run([r'C:\Program Files (x86)\sf\bin\sf.cmd','org','display','--target-org','FlywirePartial','--json'], capture_output=True, text=True, env=env, timeout=90)
auth = json.loads(proc.stdout)['result']
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))
base = auth['instanceUrl'] + '/services/data/v68.0'
def get(path, **params):
    url = (path if path.startswith('https://') else base + path)
    if params: url += '?' + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={'Authorization':'Bearer '+auth['accessToken']})
    with opener.open(req, timeout=60) as r: return r.read()
def query(name, soql):
    data = json.loads(get('/query', q=soql))
    while not data.get('done',True):
        page = json.loads(get(auth['instanceUrl']+data['nextRecordsUrl']))
        data['records'].extend(page['records']); data.update(done=page['done'])
        if 'nextRecordsUrl' in page: data['nextRecordsUrl']=page['nextRecordsUrl']
    (ROOT/'evidence'/f'{name}.json').write_text(json.dumps(data,indent=2),encoding='utf-8')
    print(name, len(data['records']), 'records')
    return data
org = query('organization', 'SELECT Id, Name, IsSandbox, InstanceName FROM Organization')['records'][0]
assert org['Id']=='00DhG0000000jOXUAY' and org['IsSandbox'] is True
if '--sort-only' in sys.argv:
    query('group-order-query', "SELECT Id, Name, SBQQ__Number__c, SBQQ__StartDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__r.Name = 'Q-37912' ORDER BY SBQQ__StartDate__c ASC NULLS LAST, SBQQ__SubscriptionTerm__c DESC NULLS LAST, SBQQ__Number__c ASC")
    sys.exit(0)
if '--extra' in sys.argv:
    query('lines-extra', "SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Group__c, SBQQ__Number__c, SBQQ__RequiredBy__c, SBQQ__ProductName__c, Quote_Line_Type__c, Rate_Details__c, External_Description__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.Name IN ('Q-38009','Q-38023','Q-38021','Q-38029') ORDER BY SBQQ__Quote__c, SBQQ__Number__c")
    query('mapper-items-readback', "SELECT FIELDS(ALL) FROM OmniDataTransformItem WHERE OmniDataTransformationId IN ('0jIhG0000000GsnUAE','0jIhG0000000HX7UAM') LIMIT 200")
    query('template-readback', "SELECT Id, LastModifiedDate, IsActive, ExtractOmniDataTransformName, MapperOmniDataTransformName FROM DocumentTemplate WHERE Id = '2dtPb0000000BwLIAU'")
    query('omniscript-readback', "SELECT Id, LastModifiedDate, IsActive, VersionNumber FROM OmniProcess WHERE Id = '0jNhG0000000umzUAA'")
    sys.exit(0)
query('mapper-config', "SELECT FIELDS(ALL) FROM OmniDataTransform WHERE Id IN ('0jIhG0000000GsnUAE','0jIhG0000000HX7UAM') LIMIT 10")
query('groups', "SELECT Id, Name, SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Number__c, SBQQ__StartDate__c, SBQQ__EndDate__c, SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__r.Name IN ('Q-37723','Q-37780','Q-37640','Q-37912') ORDER BY SBQQ__Quote__c, SBQQ__Number__c")
query('lines', "SELECT Id, SBQQ__Quote__c, SBQQ__Quote__r.Name, SBQQ__Group__c, SBQQ__Number__c, SBQQ__RequiredBy__c, SBQQ__RequiredBy__r.SBQQ__Number__c, SBQQ__ProductName__c, Quote_Line_Type__c, Rate_Details__c, External_Description__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.Name IN ('Q-37723','Q-37780','Q-37640','Q-37912') ORDER BY SBQQ__Quote__c, SBQQ__Number__c")
query('ungrouped-candidates', "SELECT Id, Name, SBQQ__Type__c, Multiple_Ship_to_Accounts__c, QuoteLineGroupsPresent__c FROM SBQQ__Quote__c WHERE QuoteLineGroupsPresent__c = false AND Multiple_Ship_to_Accounts__c IN ('Yes','No') ORDER BY LastModifiedDate DESC LIMIT 20")
query('template-content-version', "SELECT Id, Title, ContentSize, LastModifiedDate FROM ContentVersion WHERE Id = '068hG0000033ObzQAE'")
content = get('/sobjects/ContentVersion/068hG0000033ObzQAE/VersionData')
assert content[:2] == b'PK'
(ROOT/'evidence'/'current-template.docx').write_bytes(content)
print('Downloaded current template', len(content), 'bytes')
