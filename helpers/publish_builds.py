import subprocess
from glob import iglob, glob
from shutil import copy, copyfile
from os.path import join, split
from distro import *

import sys
import os

import platform

a,b,_ = platform.dist()

platform_name = a+"-".replace("/","-")

import struct
bit_size = 8 * struct.calcsize("P") # 32 or 64


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

setup(name="python-casadi",
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
p = subprocess.Popen(["python","setup.py","bdist_rpm","--force-arch=" + ("x86_64" if bit_size==64 else "i686")],cwd="python")
p.wait()
p = subprocess.Popen(["fakeroot","alien",glob("python/dist/*"+("64" if bit_size==64 else "686")+".rpm")[-1].split("/")[-1]],cwd="python/dist")
p.wait()
if False:
	f = file('temp.batchftp','w')
	f.write("mkdir %s\n" % releasedir)
	f.close()
	p = subprocess.Popen(["sftp","-b","temp.batchftp","casaditestbot,casadi@web.sourceforge.net:/home/pfs/project/c/ca/casadi/CasADi"])
	p.wait()
	
	f = file('temp.batchftp','w')
	f.write("mkdir %s\n" % releasedir+"/"+platform_name)
	f.close()
	p = subprocess.Popen(["sftp","-b","temp.batchftp","casaditestbot,casadi@web.sourceforge.net:/home/pfs/project/c/ca/casadi/CasADi"])
	p.wait()

	f = file('temp.batchftp','w')
	f.write("cd %s\n" % (releasedir+"/"+platform_name))
	releaseFile(casadi.__version__,glob("python/dist/*" + ("64" if bit_size==64 else "686")+".rpm")[0])
	f.write("put python/dist/*" + ("64" if bit_size==64 else "686")+".rpm\n")
	releaseFile(casadi.__version__,glob("python/dist/*.deb")[0])
	f.write("put python/dist/*.deb\n")
	if bit_size==64:
	  f.write("put python/dist/*.tar.gz\n")
	  releaseFile(casadi.__version__,glob("python/dist/*.tar.gz")[0])
	f.close()
	p = subprocess.Popen(["sftp","-b","temp.batchftp","casaditestbot,casadi@web.sourceforge.net:/home/pfs/project/c/ca/casadi/CasADi"])
	p.wait()
