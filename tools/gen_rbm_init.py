
# ./gen_hamm_dct.py
# script generateing NN initialization for training with TNet
#   
# author: Karel Vesely

# calling example:
# python gen_mlp_init.py --dimIn=598 --dimOut=135 --dimHid=1024:1024:1024 
#

import math, random
import sys


from optparse import OptionParser

parser = OptionParser()
parser.add_option('--dim', dest='dim', help='d1:d2:d3 layer dimensions in the network')
parser.add_option('--gauss', dest='gauss', help='use gaussian noise for weights', action='store_true', default=False)
parser.add_option('--negbias', dest='negbias', help='use uniform [-4.1,-3.9] for bias (default all 0.0)', action='store_true', default=False)
parser.add_option('--hidtype', dest='hidtype', help='gauss/bern', default='bern')
parser.add_option('--vistype', dest='vistype', help='gauss/bern', default='bern')
parser.add_option('--sparsitycost', dest='sparsitycost', help='set sparsity cost', default=0.0)

(options, args) = parser.parse_args()

if(options.dim == None):
    parser.print_help()
    sys.exit(1)


dimStrL = options.dim.split(':')
dimL = []
for i in range(len(dimStrL)):
    dimL.append(int(dimStrL[i]))


#generate RBM
layer=0
#print '<rbm>' if options.sparsitycost == 0.0 else '<rbmsparse>', dimL[layer+1], dimL[layer]
#print 'gauss' if options.vistype == 'gauss' else 'bern',\
#      'gauss' if options.hidtype == 'gauss' else 'bern'
if(options.sparsitycost==0.0):
    print '<rbm>',
else:
    print '<rbmsparse>'
print dimL[layer+1], dimL[layer] 

if(options.vistype=='gauss'):
    print 'gauss',
else:
    print 'bern',

if(options.hidtype == 'gauss'):
    print 'gauss'
else:
    print 'bern'


#init weight matrix
print 'm', dimL[layer+1], dimL[layer]
for row in range(dimL[layer+1]):
    for col in range(dimL[layer]):
        if(options.gauss):
            print 0.1*random.gauss(0.0,1.0),
        else:
            print random.random()/5.0-0.1, 
    print

#init visbias
print 'v', dimL[layer]
for idx in range(dimL[layer]):
    if(options.vistype=='gauss'):
        print '0.0',
    elif(options.negbias):
        print random.random()/5.0-4.1,
    else:
        print '0.0',
print

#init hidbias
print 'v', dimL[layer+1]
for idx in range(dimL[layer+1]):
    if(options.hidtype=='gauss'):
        print '0.0',
    elif(options.negbias):
        print random.random()/5.0-4.1,
    else:
        print '0.0',
print
if (options.sparsitycost != 0.0):
    print options.sparsitycost

