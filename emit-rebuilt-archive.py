# The source is already public and is emitted only after the invariant/privacy audit.
# This provides a credential-free way to retrieve the exact rebuilt source locally.
from pathlib import Path
import base64,math
encoded=base64.b64encode(Path("submission/PAmeasures_2.0.0.tar.gz").read_bytes()).decode("ascii")
width=30000; count=math.ceil(len(encoded)/width)
if count>9: raise RuntimeError("Rebuilt archive exceeds the small-source transfer limit")
for i in range(count):
    print(f"::notice title=Rebuilt source archive {i+1:02d}/{count:02d}::"+encoded[i*width:(i+1)*width])
