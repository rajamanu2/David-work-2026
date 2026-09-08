const fs=require('fs');const vm=require('vm');const path=require('path');
const base=path.join(__dirname,'evidence');
const rows=[];
function load(name,runtime){
 const code=fs.readFileSync(path.join(base,name+(runtime?'.transpiled.js':'.mjs')),'utf8');
 const exports={};const ctx=vm.createContext({console:{log(){},warn(){},error(){}},Promise,Set,Map,System:{register(n,d,f){const x=f((n,v)=>{if(typeof n==='object')Object.assign(exports,n);else exports[n]=v;},{});x.execute();}}});
 if(runtime)vm.runInContext(code,ctx,{timeout:3000});
 else{vm.runInContext(code.replace(/export (?=(async )?function )/g,''),ctx,{timeout:3000});for(const n of ['isFieldEditable','isFieldVisibleForObject','onBeforeCalculate','onAfterCloneLine'])if(typeof ctx[n]==='function')exports[n]=ctx[n];}
 return exports;
}
function check(mode,name,expected,actual){rows.push({mode,name,expected,actual,pass:JSON.stringify(expected)===JSON.stringify(actual)});}
(async()=>{
 for(const runtime of [false,true]){
 const mode=runtime?'stored transpiled code':'current source';const q=load('QCP_HideFieldInQLE',runtime),c=load('QLE_CloneLineHandler',runtime);
 const record={SBQQ__Existing__c:false,Group_Allow_Product_Ramping__c:true,SBQQ__Source__c:'SOURCE',SBQQ__Group__c:'GROUP2',Ship_To_Account__c:'SHIP',Transaction_Currency__c:'USD'};
 check(mode,'Downstream raw-record Ship-To lock',false,q.isFieldEditable('Ship_To_Account__c',record));
 check(mode,'Downstream raw-record currency lock',false,q.isFieldEditable('Transaction_Currency__c',record));
 const wrapped={record:{SBQQ__Existing__c:false},parentGroup:{record:{Allow_Product_Ramping__c:true,SBQQ__Number__c:2,SBQQ__Source__c:'G1'}}};
 check(mode,'Enriched wrapper Ship-To lock control',false,q.isFieldEditable('Ship_To_Account__c',wrapped));
 check(mode,'Enriched wrapper usage percent editable',true,q.isFieldEditable('Usage_Rate__c',wrapped));
 check(mode,'Enriched wrapper usage amount editable',true,q.isFieldEditable('Usage_Rate_Amt__c',wrapped));
 for(const f of ['SBQQ__Quantity__c','Quoted_Price__c','Adjusted_Rate_Amount__c','Adjusted_Rate_Percent__c','Rate_Details__c'])check(mode,'Enriched wrapper allowed '+f,true,q.isFieldEditable(f,wrapped));
 check(mode,'First-group ordinary attribute control',true,q.isFieldEditable('Transaction_Currency__c',{SBQQ__Existing__c:false}));
 const vis={...record,SBQQ__ProductCode__c:'FWCCY1000',Vertical2__c:'Education',Requires_ARR_Fields_Completion__c:true};
 check(mode,'Downstream ARR Utilization hidden',false,q.isFieldVisibleForObject('Utilization__c',vis,null,'QuoteLine__c'));
 const clone={record:{DOM_Outgoing_PYMTS__c:123,Utilization__c:50,Opportunity_Line_Id__c:'SRC-ID',NS_ID__c:'NS-ID',Transaction_Currency__c:'USD',Ship_To_Account__c:'SHIP'}};
 await c.onAfterCloneLine({}, {clonedLines:[clone]});
 check(mode,'Clone hook clears ARR', [null,null],[clone.record.DOM_Outgoing_PYMTS__c,clone.record.Utilization__c]);
 check(mode,'Clone hook preserves business attributes',['USD','SHIP'],[clone.record.Transaction_Currency__c,clone.record.Ship_To_Account__c]);
 check(mode,'Clone hook ID clearing observed',[null,null],[clone.record.Opportunity_Line_Id__c,clone.record.NS_ID__c]);
 const saved={record:{Id:'SAVED_LINE',SBQQ__Existing__c:false,Opportunity_Line_Id__c:'ESTABLISHED-ID',NS_ID__c:'ESTABLISHED-NS',DOM_Outgoing_PYMTS__c:123}};
 await q.onBeforeCalculate({},[saved]);
 check(mode,'Saved non-contracted line retains established IDs',['ESTABLISHED-ID','ESTABLISHED-NS'],[saved.record.Opportunity_Line_Id__c,saved.record.NS_ID__c]);
 check(mode,'Net-new ARR input retained control',123,saved.record.DOM_Outgoing_PYMTS__c);
 const contracted={record:{Id:'CONTRACTED',SBQQ__Existing__c:true,Opportunity_Line_Id__c:'EXISTING',NS_ID__c:'NS'}};
 await q.onBeforeCalculate({},[contracted]);check(mode,'Contracted existing line preserves IDs',['EXISTING','NS'],[contracted.record.Opportunity_Line_Id__c,contracted.record.NS_ID__c]);
 }
 fs.writeFileSync(path.join(base,'javascript-probe-results.json'),JSON.stringify(rows,null,2));
 console.log(JSON.stringify({checks:rows.length,pass:rows.filter(x=>x.pass).length,fail:rows.filter(x=>!x.pass).length,failures:rows.filter(x=>!x.pass)},null,2));
})().catch(e=>{console.error(e);process.exitCode=1;});

