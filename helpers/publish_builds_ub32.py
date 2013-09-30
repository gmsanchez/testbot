import subprocess
from glob import iglob, glob
from shutil import copy, copyfile
from os.path import join, split

import sys
import os

if len(sys.argv)>1:
    release = sys.argv[1]
else:
    import casadi
    release = casadi.__version__
    if '+' in release:
      try:
        release = casadi.CasadiMeta.getGitDescribe()
      except:
        pass

print "Releasing as version " , release
    
def copy_files(src_glob, dst_folder):
    for fname in iglob(src_glob):
        try:
            copyfile(fname, join(dst_folder, split(fname)[1]))
        except IOError as e:
            print str(e)
            pass

#copy_files("..\\..\\libraries\\*.dll","python\\casadi")

# Clean dist dir
for i in glob("python/dist/*"):
    os.remove(i)
f = file('python/setup.py','w')
f.write("""
from distutils.core import setup, Extension
from glob import glob
from shutil import copyfile

setup(name="casadi",
    version="%s",
    description="CasADi is a symbolic framework for automatic differentation and numeric optimization",
    maintainer="Joris Gillis",
    author="Joel Andersson",
    url="casadi.org",
    packages=["casadi","casadi.tools","casadi.tools.graph"],
    package_data={"casadi": ["_casadi.so"]}
)

""" % release)
if '+' in release:
    releasedir = 'tested'
else:
    releasedir = release
f.close()
p = subprocess.Popen(["python","setup.py","bdist_rpm","--force-arch=i686"],cwd="python")
p.wait()
p = subprocess.Popen(["fakeroot","alien",glob("python/dist/*686.rpm")[-1].split("/")[-1]],cwd="python/dist")
p.wait()
if True:
	f = file('temp.batchftp','w')
	f.write("mkdir %s\n" % releasedir)
	f.close()
	p = subprocess.Popen(["sftp","-b","temp.batchftp","casaditestbot,casadi@web.sourceforge.net:/home/pfs/project/c/ca/casadi/CasADi"])
	p.wait()

	f = file('temp.batchftp','w')
	f.write("cd %s\n" % releasedir)
	f.write("put python/dist/*686.rpm\n")
	f.write("put python/dist/*.deb\n")
	f.close()
	p = subprocess.Popen(["sftp","-b","temp.batchftp","casaditestbot,casadi@web.sourceforge.net:/home/pfs/project/c/ca/casadi/CasADi"])
	p.wait()
