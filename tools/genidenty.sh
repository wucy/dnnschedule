#!/bin/bash

IDENTITY=$1

echo "<expand> 429 39                                                                                                                                        
v 11                                                                                                                                                         
-5 -4 -3 -2 -1 0 1 2 3 4 5" > $IDENTITY


echo "<transpose> 429 429                                                                                                                                    
11 " >>  $IDENTITY

echo "<bias> 429 429                                                                                                                                         
v 429" >> $IDENTITY

for i in `seq 1 429`
do
echo -n "0 "
done >> $IDENTITY
echo >> $IDENTITY

echo "<window> 429 429                                                                                                                                       
v 429" >> $IDENTITY

for i in `seq 1 429`
do
echo -n "1 "
done >> $IDENTITY
echo >> $IDENTITY
