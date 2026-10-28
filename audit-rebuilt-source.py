"""Audit a release rebuild against the previously approved source contents."""
from pathlib import Path, PurePosixPath
import hashlib, json, os, re, tarfile
original=Path("PAmeasures_2.0.0.tar.gz")
rebuilt=Path("submission/PAmeasures_2.0.0.tar.gz")
def members(path):
    files={}
    with tarfile.open(path) as archive:
        for member in archive.getmembers():
            p=PurePosixPath(member.name)
            if p.is_absolute() or ".." in p.parts or p.parts[0]!="PAmeasures":
                raise RuntimeError("Unsafe archive member: "+member.name)
            if member.isdir(): continue
            if not member.isfile(): raise RuntimeError("Non-regular archive member: "+member.name)
            if member.name in files: raise RuntimeError("Duplicate archive member")
            files[member.name]=archive.extractfile(member).read()
    return files
def dcf(data):
    values={}; key=None
    for line in data.decode().splitlines():
        if not line.strip(): continue
        if line[:1].isspace(): values[key]+=" "+line.strip()
        else:
            key,value=line.split(":",1); values[key]=value.strip()
    return {k:re.sub(r"\s+"," ",v) for k,v in values.items()}
a,b=members(original),members(rebuilt)
if set(a)!=set(b): raise RuntimeError("Rebuild changed the archive file list")
changed=[name for name in sorted(a) if a[name]!=b[name]]
allowed={"PAmeasures/DESCRIPTION","PAmeasures/build/partial.rdb"}
if set(changed)-allowed: raise RuntimeError("Unexpected source changes: "+str(changed))
da,db=dcf(a["PAmeasures/DESCRIPTION"]),dcf(b["PAmeasures/DESCRIPTION"])
changed_fields=[key for key in set(da)|set(db) if da.get(key)!=db.get(key)]
if set(changed_fields)-{"Packaged"}: raise RuntimeError("DESCRIPTION semantic changes: "+str(changed_fields))
if db.get("Package")!="PAmeasures" or db.get("Version")!="2.0.0": raise RuntimeError("Wrong package/version")
for name,data in b.items():
    for forbidden in [b"/Users/",b"Dropbox/",b"xywang@ucla.edu",b"BEGIN OPENSSH PRIVATE KEY"]:
        if forbidden in data: raise RuntimeError("Private/local marker found in "+name)
sha=hashlib.sha256(rebuilt.read_bytes()).hexdigest()
summary=dict(R=Path("submission/R-build-version.txt").read_text().strip(),source_sha256=sha,
             bytes=rebuilt.stat().st_size,files=len(b),changed_files=changed,
             changed_description_fields=sorted(changed_fields),unchanged_other_source_files=True)
Path("submission/SHA256SUMS").write_text(sha+"  PAmeasures_2.0.0.tar.gz\n")
Path("submission/build-audit.json").write_text(json.dumps(summary,indent=2)+"\n")
Path("submission/source-manifest.json").write_text(json.dumps([
    dict(path=k,bytes=len(v),sha256=hashlib.sha256(v).hexdigest()) for k,v in sorted(b.items())],indent=2)+"\n")
with open(os.environ["GITHUB_OUTPUT"],"a") as f: f.write("sha256="+sha+"\n")
print("::notice title=Release build audit::"+json.dumps(summary,separators=(",",":")))
