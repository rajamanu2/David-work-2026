"""Read-only current-state capture and Extract/Transform execution. No deployment."""
from pathlib import Path
import json,subprocess,os,urllib.request,urllib.parse,hashlib,datetime
R=Path(__file__).resolve().parent
O=R/('recheck-'+datetime.datetime.now().strftime('%H%M%S'));O.mkdir();(O/'evidence').mkdir();(O/'deployment').mkdir()
env=os.environ.copy()
for k in ('HTTP_PROXY','HTTPS_PROXY','ALL_PROXY'):env.pop(k,None)
env.update(SF_DISABLE_LOG_FILE='true',SF_AUTOUPDATE_DISABLE='true',SF_DISABLE_TELEMETRY='true')
sf=r'C:\Program Files (x86)\sf\bin\sf.cmd'
proc=subprocess.run([sf,'org','display','-o','FlywirePartial','--json'],capture_output=True,text=True,env=env,timeout=90)
a=json.loads(proc.stdout).get('result',{})
assert a.get('accessToken'),'Partial authentication unavailable'
assert 'flywire--partial.sandbox.my.salesforce.com' in a['instanceUrl']
opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
def get(path):
 req=urllib.request.Request(a['instanceUrl']+'/services/data/v68.0'+path,headers={'Authorization':'Bearer '+a['accessToken']})
 with opener.open(req,timeout=60) as res:return res.read()
def q(soql):return json.loads(get('/query?'+urllib.parse.urlencode({'q':soql})))
def save(path,value):path.write_text(json.dumps(value,indent=2),encoding='utf-8')
org=q('SELECT Id,Name,IsSandbox FROM Organization')['records'][0]
assert org['Id']=='00DhG0000000jOXUAY' and org['IsSandbox']
save(O/'organization.json',org);print('PASS verified FlywirePartial sandbox',flush=True)
queries={
'after-mapper-items':"SELECT FIELDS(ALL) FROM OmniDataTransformItem WHERE OmniDataTransformationId IN ('0jIhG0000000GsnUAE','0jIhG0000000HX7UAM') LIMIT 200",
'after-template':"SELECT FIELDS(ALL) FROM DocumentTemplate WHERE Id='2dtPb0000000BwLIAU' LIMIT 1",
'after-template-links':"SELECT FIELDS(ALL) FROM DocumentTemplateContentDoc WHERE DocumentTemplateId='2dtPb0000000BwLIAU' LIMIT 20"}
def stable(rows):return sorted([{k:v for k,v in r.items() if k not in ('attributes','LastViewedDate','LastReferencedDate')} for r in rows],key=lambda r:r['Id'])
before={}
for name,sql in queries.items():
 rows=q(sql)['records'];save(O/'deployment'/f'{name}.json',rows);before[name]=rows
 assert stable(rows)==stable(json.loads((R/'deployment'/f'{name}.json').read_text())),name+' changed since previous verification'
print('PASS scoped configuration matches previous verified state',flush=True)
version=before['after-template-links'][0]['LatestContentVersionId']
blob=get('/sobjects/ContentVersion/'+version+'/VersionData')
assert blob==(R/'candidate/CPQ Quote Proposal - SALDEV-1403 - dry-run.docx').read_bytes()
save(O/'template-check.json',{'version':version,'sha256':hashlib.sha256(blob).hexdigest(),'matches':True})
names="('Q-37723','Q-37780','Q-37640','Q-37912','Q-38009','Q-38023','Q-38021','Q-38029')"
save(O/'evidence/groups.json',q('SELECT Id,Name,SBQQ__Quote__c,SBQQ__Quote__r.Name,SBQQ__Number__c,SBQQ__StartDate__c,SBQQ__SubscriptionTerm__c FROM SBQQ__QuoteLineGroup__c WHERE SBQQ__Quote__r.Name IN '+names))
save(O/'evidence/lines.json',q('SELECT Id,SBQQ__Quote__c,SBQQ__Quote__r.Name,SBQQ__Group__c,SBQQ__Number__c,SBQQ__RequiredBy__c,SBQQ__ProductName__c,Quote_Line_Type__c,Rate_Details__c,External_Description__c FROM SBQQ__QuoteLine__c WHERE SBQQ__Quote__r.Name IN '+names))
save(O/'evidence/lines-extra.json',{'records':[]})
for name in ['baseline','baseline-extra']:
 proc=subprocess.run([sf,'apex','run','-o','FlywirePartial','-f',str(R/(name+'.apex')),'--json'],capture_output=True,text=True,encoding='utf-8',env=env,timeout=180)
 result=json.loads(proc.stdout);save(O/'deployment'/('post-'+name+'.json'),result)
 assert result.get('status')==0 and result.get('result',{}).get('success'),name+' failed; see saved result'
 print('PASS native '+name,flush=True)
for name,sql in queries.items():assert stable(before[name])==stable(q(sql)['records']),name+' changed during checks'
for name in ['before-mapper-items.json','template-upload-receipt.json']:
 (O/'deployment'/name).write_bytes((R/'deployment'/name).read_bytes())
(O/'candidate').mkdir();(O/'candidate/mapper-change-spec.json').write_bytes((R/'candidate/mapper-change-spec.json').read_bytes())
code=(R/'verify_deployment.py').read_text().replace('R=Path(__file__).resolve().parent;',f'R=Path({str(O)!r});')
exec(compile(code,str(R/'verify_deployment.py'),'exec'),{'__file__':str(R/'verify_deployment.py')})
print('EVIDENCE',O,flush=True)
