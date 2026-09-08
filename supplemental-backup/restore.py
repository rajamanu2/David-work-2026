from pathlib import Path
import hashlib,json,zipfile,tempfile,shutil

here=Path(__file__).resolve().parent
root=here.parent
for item in json.loads((here/'manifest.json').read_text(encoding='utf-8')):
    with tempfile.TemporaryFile() as assembled:
        digest=hashlib.sha256()
        for name in item['parts']:
            with (here/name).open('rb') as f:
                for chunk in iter(lambda:f.read(1048576),b''):
                    digest.update(chunk)
                    assembled.write(chunk)
        if digest.hexdigest()!=item['sha256']:raise RuntimeError('Hash mismatch: '+item['archive'])
        assembled.seek(0)
        with zipfile.ZipFile(assembled) as z:
            for entry in z.infolist():
                target=(root/entry.filename).resolve()
                if not target.is_relative_to(root):raise RuntimeError('Invalid archive path')
            z.extractall(root)
    print('Restored:',item['project'])
