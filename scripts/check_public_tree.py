"""Heuristic pre-publication check. Review findings; this is not a secret scanner guarantee."""
from pathlib import Path
import re, subprocess, sys
root=Path(__file__).resolve().parents[1]
files=subprocess.check_output(['git','ls-files','-z'],cwd=root).decode().split('\0')
patterns=[r'/Users/[^/\s]+/',r'/home/[^/\s]+/',r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',r'gh[pousr]_[A-Za-z0-9]{20,}',r'AKIA[0-9A-Z]{16}',r'(?i)(?:api[_-]?key|access[_-]?token|password)\s*[:=]\s*[\"\'][^\"\']{8,}']
findings=[]
for name in filter(None,files):
 p=root/name
 if p.suffix in {'.p12','.mobileprovision','.key'}:findings.append(name+': forbidden signing/secret file')
 try:text=p.read_text()
 except UnicodeDecodeError:continue
 for n,line in enumerate(text.splitlines(),1):
  if name == 'scripts/check_public_tree.py':continue
  if any(re.search(pattern,line) for pattern in patterns):findings.append(f'{name}:{n}')
  for email in re.findall(r'[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}',line):
   if not email.endswith('@users.noreply.github.com'):findings.append(f'{name}:{n}: email')
history=subprocess.check_output(['git','log','--all','--format=%ae%n%ce'],cwd=root).decode().splitlines()
if any(email != 'duo-demos@users.noreply.github.com' for email in history):findings.append('history: review author/committer identities')
print('\n'.join(findings) if findings else 'PASS: tracked files and reachable author identities')
sys.exit(bool(findings))
