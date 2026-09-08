import getpass, urllib.request, urllib.parse, urllib.error, json
token = getpass.getpass('Session credential: ')
url = 'https://probomedical--uat.sandbox.my.salesforce.com/services/data/v67.0/query?q=' + urllib.parse.quote('SELECT Id, Name, OrganizationType, IsSandbox, InstanceName FROM Organization')
req = urllib.request.Request(url, headers={'Authorization': 'Bearer ' + token})
token = None
try:
    result = json.load(urllib.request.urlopen(req, timeout=30))
    print(json.dumps(result))
except urllib.error.HTTPError as exc:
    print('HTTP_STATUS', exc.code)
    print(exc.read().decode())
except Exception as exc:
    print(type(exc).__name__, str(getattr(exc, 'reason', 'Connection failed')))
