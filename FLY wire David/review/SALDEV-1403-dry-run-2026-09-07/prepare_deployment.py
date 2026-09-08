import json
from pathlib import Path
R=Path(__file__).resolve().parent
p=json.loads((R/'candidate/mapper-change-spec.json').read_text())
def lit(value):return "'"+value.replace('\\','\\\\').replace("'","\\'").replace('\r','\\r').replace('\n','\\n')+"'"
out=["// Authorized SALDEV-1403 deployment to Partial only. Unhandled assertion errors roll back the transaction.",
"Organization org = [SELECT Id, IsSandbox FROM Organization LIMIT 1];",
"System.assert(org.IsSandbox && org.Id == '00DhG0000000jOXUAY', 'Wrong org');",
"System.assertEquals(164, [SELECT count() FROM OmniDataTransformItem WHERE OmniDataTransformationId IN ('0jIhG0000000GsnUAE','0jIhG0000000HX7UAM')], 'Unexpected mapper drift');",
"List<OmniDataTransformItem> changes = new List<OmniDataTransformItem>();"]
for idx,u in enumerate(p['updates']):
    out += [f"OmniDataTransformItem item{idx} = [SELECT Id, FormulaExpression FROM OmniDataTransformItem WHERE Id = {lit(u['Id'])} FOR UPDATE];",
        f"System.assertEquals({lit(u['before'])}, item{idx}.FormulaExpression, 'Before-value mismatch');",
        f"item{idx}.FormulaExpression = {lit(u['after'])};",f"changes.add(item{idx});"]
out += ['update changes;']
out += ["List<OmniDataTransformItem> additions = (List<OmniDataTransformItem>)JSON.deserialize("+lit(json.dumps(p['creates'],separators=(',',':')))+", List<OmniDataTransformItem>.class);",
        'insert additions;',
        "ConnectApi.DatamapperCacheInputParamRepresentation cacheInput = new ConnectApi.DatamapperCacheInputParamRepresentation();",
        "cacheInput.dataMapperList = new List<ConnectApi.DataMapperParamRepresentation>();",
        "for(String mapperName : new List<String>{'GetQuoteProposalDataSteppedUpPricing','CPQQuoteProposalDocumentSteppedUpPricing'}) { ConnectApi.DataMapperParamRepresentation param = new ConnectApi.DataMapperParamRepresentation(); param.dataMapperName = mapperName; cacheInput.dataMapperList.add(param); }",
        "cacheInput.cacheStorageType = ConnectApi.CacheStorageType.Metadata;",
        "System.debug(LoggingLevel.ERROR, 'CACHE_CLEAR|' + JSON.serialize(ConnectApi.OmniDesignerConnect.clearDatamapperCache(cacheInput)));",
        "omnistudio.DRProcessResult ex = omnistudio.DRGlobal.processFromApex(new Map<String,Object>{'Id'=>'a2NhG000003lAjmUAE'}, 'GetQuoteProposalDataSteppedUpPricing');",
        "System.assertEquals(false, ex.hasErrors(), 'Extract errors');",
        "omnistudio.DRProcessResult tr = omnistudio.DRGlobal.processFromApex((Map<String,Object>)ex.toJson(), 'CPQQuoteProposalDocumentSteppedUpPricing');",
        "System.assertEquals(false, tr.hasErrors(), 'Transform errors');",
        "Map<String,Object> payload = (Map<String,Object>)tr.toJson();",
        "List<Object> groups = (List<Object>)payload.get('Group');",
        "System.debug(LoggingLevel.ERROR, 'CANDIDATE_GROUPS|' + JSON.serialize(groups));",
        "System.assertEquals(4, groups.size(), 'Group count');",
        "List<String> expected = new List<String>{'Group4','Group1','Group2','Group3'};",
        "for(Integer i=0; i<4; i++){ Map<String,Object> g=(Map<String,Object>)groups[i]; System.assertEquals(expected[i],g.get('Name'),'Group order'); System.assertEquals(i==0?36:12, Integer.valueOf(String.valueOf(g.get('SubscriptionTerm'))),'Group term'); }",
        "System.debug(LoggingLevel.ERROR,'SALDEV1403_DEPLOYED|'+JSON.serialize(new Map<String,Object>{'createdItems'=>additions,'updatedIds'=>new List<Id>{changes[0].Id,changes[1].Id},'validatedQuote'=>'Q-37912'}));"]
(R/'deployment/apply-mappers.apex').write_text('\n'.join(out),encoding='utf-8')
print('Prepared exact six-item transaction with native assertions; failure rolls back all six changes.')
