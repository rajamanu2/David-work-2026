"""Local acceptance-rule simulation only; no Salesforce calls or mutations."""
import json
from pathlib import Path

cases = [
    ('All ramped, different terms', [('G1',2026,12),('G2',2027,6),('G3',2028,18)], ['G1','G2','G3']),
    ('Three non-ramped', [('G1',2026,36),('G2',2026,36),('G3',2026,36)], ['G1','G2','G3']),
    ('One non-ramped, two ramped', [('G1',2026,36),('G2',2026,12),('G3',2027,24)], ['G1','G2','G3']),
    ('72 month mixed terms', [('G1',2026,24),('G2',2028,12),('G3',2029,36),('G4',2026,72)], ['G4','G1','G2','G3']),
    ('Two non-ramped, two ramped', [('G1',2026,24),('G2',2029,48),('G3',2026,72),('G4',2026,72)], ['G3','G4','G1','G2']),
    ('No groups', [], []),
]
results=[]
for name, groups, expected in cases:
    # Stable input order models QLE group sequence when dates and terms tie.
    desired=[g[0] for g in sorted(groups, key=lambda g:(g[1],-g[2]))]
    local_name_sort=sorted(g[0] for g in groups)
    obsolete_term_sort=[g[0] for g in sorted(groups,key=lambda g:-g[2])]
    assert desired == expected, name
    results.append(dict(scenario=name,expected=expected,rule_simulation=desired,
                        local_name_sort=local_name_sort,obsolete_term_sort=obsolete_term_sort))
out=Path(__file__).with_name('order-results.json')
out.write_text(json.dumps({'scope':'Synthetic local comparison; not Apex or live UAT', 'cases':results},indent=2))
print(out.read_text())
