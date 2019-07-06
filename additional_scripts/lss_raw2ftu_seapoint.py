#! /usr/bin/env python
#
#******************  lss_raw2ftu.py ###############################
#
# A conversion script to compute turbidity as measured by a Seapoint
# brand turbidity meter. Turbidity units are Formazin Turbidity Units,
# computed as specified by published sensitivities in Seapoint docs.
#
# Usage:
#        prompt% lss_raw2ftu.py infile outfile
#
# Formats are specific to output from ROV Jason's sensor package and
# downstream data logging. Jason's raw data stream yields a timeseries
# of analog to digital converter values, which represent voltages
# produced by the Seapoint turbidity meter. Another value in each record
# is the scale factor, which indicates the sensitivity setting imposed
# on the meter. Turbidity measurements are computed through use of the
# scale factor and of the ADC output value.
#
# Related information:
#
# Seapoint sensor User manual and data sheet @ www.seapoint.com
# ROV Jason Data Formats spreadsheet @ ndsfdh1 content mgmt system
# 
#
# Scott McCue
# WHOI National Deep Submergence Facility
# smccue@whoi.edu
# 508.289.3462  smccue@whoi.edu
#
# HISTORY
# 8Oct2012 SJM Initial release, sent to sea for exercising 
# 22Mar2013 SJM Add tolerance to records that don't match
#               standard form. If discovered, ignore the line.
#               Added 'can_convert' function to support this. 


import sys, re

def proc_lssraw2ftu(infile, outfile):
    
    # open in and outfiles, process each line of infile, write
    # results to outfile

    linecnt = 0

    try:
        ifh = open(infile, "r")
    except:
        print 'Cant open ', infile

    try:
        ofh = open(outfile, "w")
    except:
        print 'Cant open ', outfile
        

    for line in ifh:
        
            line.rstrip()
            idstr, date, time, counter, scaling, adc_value = line.split(' ')
            
            if not can_convert(scaling) or not can_convert(adc_value):
                linecnt = linecnt +1
                print linecnt
#                pass
            else:
                adc_value = re.sub('\s', ' ', adc_value)
                ftu = adc2ftu_seapoint(int(adc_value), int(scaling))
                ofh.write('FTU %s %s %s %s %s %s\n' % \
                              (date, time, counter, scaling, adc_value, ftu))

    ifh.close()
    ofh.close()
    
def adc2ftu_seapoint(adc, scale):

    # Convert raw analog-to-digital converter values to
    # Formazin Turbidity Units. Specific to the sesnsitivities
    # of a Seapoint brand sensor.
    # 
    #
    # Using Paul Fucile's electronics.
    # Legal scale values are '0' or '1'
    # Seapoint out range is 0-5VDC
    # Per Seapoint datasheet,
    #   Scaling index |  Gain  |  Sensitivity
    #   ==============|========|=============
    #         0       |   1x   | 2 mV/FTU
    #         1       |   5x   | 10 mV/FTU
    #
    # 12 bit ADC, so values range from 0-4095.
    # Presumed linear.
    # One ADC quantum step is therefore 1.2 millivolts
    # 
    #   Scaling index |  Sensitivity |  FTU/ADC step
    #   ==============|==============|=============
    #         0       |   2 mV/FTU  | 1.2/2 = 0.6 FTU
    #         1       |  10 mV/FTU  | 1.2/10 = 0.12 FTU

    #

    if adc > 4095:
        return None

    if scale == 0:
        # Seapoint sensitivity is set to 1x, 1 quantum step
        # from ADC is 0.6 FTU

        return 0.6 * adc
    
    elif scale == 1:
        # Seapoint sensitivity is set to 5x, 1 quantum step
        # from ADC is 0.12 FTU

        return 0.12 * adc

    else:
        return None

def can_convert (s):
    try:
        int(s)
    except ValueError as e:
        return False
    else:
        return True
            
if __name__ == "__main__":

    if len(sys.argv) != 3:
        # must be invoked with two arguments
        print "Usage: lss_raw2ftu.py <noargs> or lss_raw2ftu.py infile outfile"
    else:
        # filenames have been passed as command line arguments
            proc_lssraw2ftu(sys.argv[1], sys.argv[2])

