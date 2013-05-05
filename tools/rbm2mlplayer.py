#!/usr/bin/python

import sys

if len(sys.argv) != 3:
    print 'rbm2mlplayer.py infile outfile'
    print 'accepts -'
    sys.exit(1)


#open files
fnin = sys.argv[1]
fnout = sys.argv[2]

if fnin == '-':
    fin = sys.stdin
else:
    fin = open(fnin,'r')

if fnout == '-':
    fout = sys.stdout
else:
    fout = open(fnout,'w')





#define aux functions
def read_int(file):
    line = file.readline()
    line = line.strip()
    tokL = line.split()
    assert(len(tokL) == 1)
    return int(tokL[0])

def read_vector(file):
    line = file.readline()
    line = line.strip()
    tokL = line.split()
    assert(tokL[0] == 'v')
    while(int(tokL[1]) > len(tokL)-2):
        line = file.readline()
        line = line.strip()
        tokL.extend(line.split())
    assert(int(tokL[1]) == len(tokL)-2)
    #print tokL
    return tokL[2:]

def read_matrix(file):
    line = file.readline()
    #line = line.strip()
    tokL = line.split()
    assert(tokL[0] == 'm')
    mat_size = int(tokL[1]) * int(tokL[2])
    while(mat_size > len(tokL)-3):
        line = file.readline()
        #line = line.strip()
        tokL.extend(line.split())
    assert(mat_size == len(tokL)-3)
    #print tokL
    return (tokL[1],tokL[2],tokL[3:])


#read the RBM
line = fin.readline()
(tag,hidN,visN) = line.split()
hidN=int(hidN)
visN=int(visN)

if(tag != '<rbm>' and tag != '<rbmsparse>'):
    raise 'missing <rbm> tag in header'

line = fin.readline()
(vistype,hidtype) = line.split()

(m_rows,m_cols,m_data) = read_matrix(fin)
m_rows=int(m_rows)
m_cols=int(m_cols)

mv_vis = read_vector(fin)
v_hid = read_vector(fin)

#write the MLP equivalent of RBM
print '<biasedlinearity>',hidN,visN
print 'm',hidN,visN
for row in range(m_rows):
    for col in range(m_cols):
        print m_data[row*m_cols+col],
    print

print 'v',hidN
for idx in range(len(v_hid)):
    print v_hid[idx],
print

if (hidtype=='bern'):
    print '<sigmoid>',hidN,hidN

#finally close files
if fnin != '-':
    fin.close()

if fnout != '-':
    fout.close()
