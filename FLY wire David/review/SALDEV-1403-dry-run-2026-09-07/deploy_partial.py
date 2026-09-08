"""Explicitly authorized SALDEV-1403 Partial deployment. Credentials stay in memory."""
import base64, hashlib, json, os, subprocess, sys
from pathlib import Path
import urllib.request, urllib.parse, urllib.error
ROOT=Path(__file__).resolve().parent
OUT=ROOT/'deployment'; OUT.mkdir(exist_ok=True)
env=os.environ.copy()
for k in ['HTTP_PROXY','HTTPS_PROXY','ALL_PROXY']:env.pop(k,None)
env.update(SF_DISABLE_LOG_FILE='true',SF_AUTOUPDATE_DISABLE='true',SF_DISABLE_TELEMETRY='true')
p=subprocess.run([r'C:\Program Files (x86)\sf\bin\sf.cmd','org','display','--target-org','FlywirePartial','--json'],capture_output=True,text=True,env=env,timeout=90)
a=json.loads(p.stdout)['result']
assert 'flywire--partial.sandbox.my.salesforce.com' in a['instanceUrl']
opener=urllib.request.build_opener(urllib.request.ProxyHandler({}))
base=a['instanceUrl']+'/services/data/v68.0'
def request(path,method='GET',data=None):
    req=urllib.request.Request(base+path,data=None if data is None else json.dumps(data).encode(),method=method,
        headers={'Authorization':'Bearer '+a['accessToken'],'Content-Type':'application/json'})
    try:
        with opener.open(req,timeout=90) as r: return r.read()
    except urllib.error.HTTPError as e: raise RuntimeError(f'HTTP {e.code}: {e.read().decode()[:1200]}') from None
def query(q):return json.loads(request('/query?'+urllib.parse.urlencode({'q':q})))['records']
def save(name,data): (OUT/name).write_text(json.dumps(data,indent=2),encoding='utf-8')
org=query('SELECT Id,Name,IsSandbox FROM Organization')[0]
assert org['Id']=='00DhG0000000jOXUAY' and org['IsSandbox'] is True
save('organization.json',org)
mode=sys.argv[1]
if mode=='preflight':
    items=query("SELECT FIELDS(ALL) FROM OmniDataTransformItem WHERE OmniDataTransformationId IN ('0jIhG0000000GsnUAE','0jIhG0000000HX7UAM') LIMIT 200")
    old=json.loads((ROOT/'evidence'/'mapper-items.json').read_text(encoding='utf-8-sig'))['result']['records']
    def stable(rows):return sorted([{k:v for k,v in x.items() if k not in ['attributes','LastViewedDate','LastReferencedDate']} for x in rows],key=lambda x:x['Id'])
    assert stable(old)==stable(items),'Mapper drift; stop before writes'
    save('before-mapper-items.json',items)
    save('before-template.json',query("SELECT FIELDS(ALL) FROM DocumentTemplate WHERE Id='2dtPb0000000BwLIAU' LIMIT 1"))
    links=query("SELECT FIELDS(ALL) FROM DocumentTemplateContentDoc WHERE DocumentTemplateId='2dtPb0000000BwLIAU' LIMIT 20")
    assert len(links)==1 and links[0]['LatestContentVersionId']=='068hG0000033ObzQAE','Template link drift'
    save('before-template-links.json',links)
    blob=request('/sobjects/ContentVersion/'+links[0]['LatestContentVersionId']+'/VersionData')
    assert hashlib.sha256(blob).digest()==hashlib.sha256((ROOT/'evidence'/'current-template.docx').read_bytes()).digest(),'Source content drift'
    (OUT/'before-template.docx').write_bytes(blob)
    for obj in ['ContentVersion','DocumentTemplateContentDoc']:
        schema=json.loads(request('/sobjects/'+obj+'/describe'))
        save(obj+'-schema.json',schema)
    save('before-omniscript.json',query("SELECT Id,IsActive,VersionNumber,LastModifiedDate FROM OmniProcess WHERE Id='0jNhG0000000umzUAA'"))
    print('PASS: Partial identity, 164 mapper items unchanged, template source unchanged; backups captured.')
elif mode=='publish-template':
    result=json.loads((OUT/'mapper-deployment-result.json').read_text(encoding='utf-8-sig'))
    assert result['status']==0 and result['result']['success'],'Mapper deployment did not pass'
    candidate=ROOT/'candidate/CPQ Quote Proposal - SALDEV-1403 - dry-run.docx'
    hashes=json.loads((ROOT/'candidate/sha256.json').read_text(encoding='utf-8-sig'))
    expected=next(x['Hash'] for x in hashes if x['Path'].endswith('.docx'))
    assert hashlib.sha256(candidate.read_bytes()).hexdigest().upper()==expected
    references=query("SELECT Id,DocumentTemplateId,ContentDocumentId,LatestContentVersionId FROM DocumentTemplateContentDoc WHERE ContentDocumentId='069hG000003DZfnQAG'")
    assert len(references)==1 and references[0]['DocumentTemplateId']=='2dtPb0000000BwLIAU','Unexpected template sharing'
    receipt=OUT/'template-upload-receipt.json'
    if receipt.exists():
        version=json.loads(receipt.read_text())['id']
        print('Existing upload receipt; verify without uploading again',version)
    else:
        assert references[0]['LatestContentVersionId']=='068hG0000033ObzQAE','Template drift'
        data={'ContentDocumentId':'069hG000003DZfnQAG','Title':'CPQ Quote Proposal - SteppedUpPricing-v6',
          'PathOnClient':'CPQ Quote Proposal - SteppedUpPricing-v6.docx',
          'Description':'SALDEV-1403 approved Partial update: sequential Term headings without service dates.',
          'VersionData':base64.b64encode(candidate.read_bytes()).decode()}
        res=json.loads(request('/sobjects/ContentVersion','POST',data)); save(receipt.name,res)
        assert res['success']; version=res['id']
    actual=request('/sobjects/ContentVersion/'+version+'/VersionData')
    assert actual==candidate.read_bytes(),'Uploaded file mismatch'
    links=query("SELECT Id,DocumentTemplateId,ContentDocumentId,LatestContentVersionId FROM DocumentTemplateContentDoc WHERE Id='2ddhG0000001bwnQAA'")
    save('template-link-after-upload.json',links)
    assert links[0]['LatestContentVersionId']==version,'Template not linked to new version'
    print('PASS: Uploaded template bytes match candidate; live template points to',version)
elif mode=='readback':
    save('after-mapper-items.json',query("SELECT FIELDS(ALL) FROM OmniDataTransformItem WHERE OmniDataTransformationId IN ('0jIhG0000000GsnUAE','0jIhG0000000HX7UAM') LIMIT 200"))
    save('after-template-links.json',query("SELECT FIELDS(ALL) FROM DocumentTemplateContentDoc WHERE DocumentTemplateId='2dtPb0000000BwLIAU' LIMIT 20"))
    save('after-template.json',query("SELECT FIELDS(ALL) FROM DocumentTemplate WHERE Id='2dtPb0000000BwLIAU' LIMIT 1"))
    print('Captured independent read-back')
else:raise ValueError(mode)
