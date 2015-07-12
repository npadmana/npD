from glob import glob
import sys
import os.path
from itertools import ifilter

def toRun(filetup) :
  ret = os.path.isfile(filetup[0])
  ret = ret and os.path.isfile(filetup[1])
  norm = "%s-norm.dat"%filetup[2];
  ret = ret and (not os.path.isfile(norm))
  return ret


def getfiles(inprefix, outprefix, n0, n1):
  ll = [ ("%s.shift.bin"%(inprefix%ii), \
	    "%s.rshift.bin"%(inprefix%ii), \
            outprefix%ii) for ii in range(n0,n1)]
  # Loop over this, making sure all files exist, and that the paircounts don't
  ll = list(ifilter(toRun, ll))
  return ll

def writefiles(ll, outprefix,blocksize=50):
  count = 0
  lastpos = 0
  firstpos = 0
  while lastpos < len(ll) :
    firstpos=lastpos
    lastpos = firstpos + blocksize
    if (lastpos > len(ll)) :
       lastpos = len(ll);
    subll = ll[firstpos:lastpos]
    ff = open(outprefix%count,"w")
    for ii in subll :
      ff.write("%s %s %s true true\n"%ii)
    ff.close()
    count += 1 
  return count

def writeqsub(template, script, n0, n1):
  for ii in range(n0,n1):
    fn = script%ii
    ff = open(fn,"w")
    ff.write(template%ii)
    ff.close()


ngcpbs="""#PBS -q regular
#PBS -l mppwidth=1512
#PBS -l walltime=02:00:00
#PBS -j oe
#PBS -A hacc
#PBS -o ngc.$PBS_JOBID.out

cd $PBS_O_WORKDIR
aprun -n 63 -N 1 -d 24 -cc none ../exec/smu_zweight.x -fpair.conf --jobFile=ini/recon_ngc_jobs_%02d.dat
"""

def ngc():
  ll = getfiles("recon_ngc/qpm_biasmock_%04d.dr12d_combined_ngc","paircounts/recon_ngc/qpm_biasmock_%04d.dr12d_combined_ngc",1,1001)
  count = writefiles(ll,"ini/recon_ngc_jobs_%02d.dat")
  writeqsub(ngcpbs,"scripts/recon-pair/ngc.%02d.qsub",0,count)
 

if __name__=="__main__" :
  cap = sys.argv[1]
  if cap == "ngc" :
    ngc();
 
