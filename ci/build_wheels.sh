#!/opt/python/cp36-cp36m/bin/python
import subprocess
from pathlib import Path
import datetime
import shutil

out_dir = Path("/io/wheelhouse")
out_dir.mkdir(exist_ok=True)

for f in ["dist", "wheelhouse"]:
    p = Path('/io') / f
    if p.exists():
        shutil.rmtree(p)


def repair_wheel(wheel, plat):
    show = subprocess.run(["auditwheel", "show", wheel]).returncode
    if show != 0:
        print("Skipping non-platform wheel $wheel")
    else:
        subprocess.check_call(
            ["auditwheel", "repair", wheel, "--plat", plat, "-w", str(out_dir)]
        )


pythons = [x for x in Path("/opt/python").glob("cp*") if not x.name.startswith("cp2")]
if datetime.date.today() < datetime.date(year=2020, month=10, day=5):
    pythons = [x for x in pythons if x.name != "cp39-cp39"]

print("building for pythons", [x.name for x in pythons])


for p in pythons:
    pip = f"{p.absolute()}/bin/pip"
    subprocess.check_call([pip, "install", "-r", "/io/dev-requirements.txt"])
    subprocess.check_call([pip, "wheel", "/io", "--no-deps", "-w", str(out_dir)])

for whl in Path(out_dir).glob("*.whl"):
    repair_wheel(str(whl), "manylinux2010_x86_64")

# Install packages and test
for p in pythons:
    pip = f"{p.absolute()}/bin/pip"
    pytest = f"{p.absolute()}/bin/pytest"
    subprocess.check_call(
        [pip, "install", "mbf_pandas_msgpack", "--no-index", "-f", str(out_dir)]
    )
    subprocess.check_call([pytest, "--import-mode=append"], cwd="/io/tests")

for x in out_dir.glob('*-linux_*.whl'):
    x.unlink()

