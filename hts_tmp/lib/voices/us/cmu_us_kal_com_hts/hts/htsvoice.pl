#!/usr/bin/perl
#  ----------------------------------------------------------------  #
#      The HMM-Based Speech Synthesis System (HTS): version 1.1.1    #
#                        HTS Working Group                           #
#                                                                    #
#                   Department of Computer Science                   #
#                   Nagoya Institute of Technology                   #
#                                and                                 #
#    Interdisciplinary Graduate School of Science and Engineering    #
#                   Tokyo Institute of Technology                    #
#                      Copyright (c) 2001-2003                       #
#                        All Rights Reserved.                        #
#                                                                    #
#  Permission is hereby granted, free of charge, to use and          #
#  distribute this software and its documentation without            #
#  restriction, including without limitation the rights to use,      #
#  copy, modify, merge, publish, distribute, sublicense, and/or      #
#  sell copies of this work, and to permit persons to whom this      #
#  work is furnished to do so, subject to the following conditions:  #
#                                                                    #
#    1. The code must retain the above copyright notice, this list   #
#       of conditions and the following disclaimer.                  #
#                                                                    #
#    2. Any modifications must be clearly marked as such.            #
#                                                                    #
#  NAGOYA INSTITUTE OF TECHNOLOGY, TOKYO INSITITUTE OF TECHNOLOGY,   #
#  HTS WORKING GROUP, AND THE CONTRIBUTORS TO THIS WORK DISCLAIM     #
#  ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING ALL        #
#  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT    #
#  SHALL NAGOYA INSTITUTE OF TECHNOLOGY, TOKYO INSITITUTE OF         #
#  TECHNOLOGY, HTS WORKING GROUP, NOR THE CONTRIBUTORS BE LIABLE     #
#  FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY         #
#  DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,   #
#  WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTUOUS    #
#  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR           #
#  PERFORMANCE OF THIS SOFTWARE.                                     #
#  ----------------------------------------------------------------  #
#    A voice based on "HTS" HMM-based Speech Synthesis System        #
#                                                                    #
#                                  2003/12/26 by Heiga Zen           #
#  ----------------------------------------------------------------  #

$SAMPRATE = 16000;    # if you use other sampling frequency, please change this variable

# default value 

$F0_STD  = 1.0;       # multiply f0
$F0_MEAN = 0.0;       # add f0
$DF      = 0.0;       # duration control
$FW      = 0.42;      # all-pass consonant 
$UV      = 0.5;       # voiced/unvoiced threshold
$LENGTH  = 0.0;       # total length of generated speech
$BETA    = 0.0;       # postfiltering 

$WORKDIR = "/tmp";

$size = @ARGV;
$i    = 0;

while($i < $size) {
   if($ARGV[$i] eq "--directory" || $ARGV[$i] eq "-d") {
      $DIR = $ARGV[$i+1];
      $i = $i+2;
      next;
   }
   if($ARGV[$i] eq "--infile" || $ARGV[$i] eq "-i") {
      $INFEATS = $ARGV[$i+1];
      $i = $i+2;
      next;
   }
   if($ARGV[$i] eq "--outfile" || $ARGV[$i] eq "-o") {
      $OUTWAVE = $ARGV[${i}+1];
      $i=$i+2;
      next;
   }
   if($ARGV[$i] eq "--workdir" || $ARGV[$i] eq "-w") {
      $WORKDIR = $ARGV[$i+1];
      $i=$i+2;
      next;
   }
   if($ARGV[$i] eq "--f0_mean" || $ARGV[$i] eq "-fm") {
      $F0_MEAN = $ARGV[$i+1];
      $i=$i+2;
      next;
   }
   if($ARGV[$i] eq "--f0_std" || $ARGV[$i] eq "-fs") {
      $F0_STD = $ARGV[$i+1];
      $i=$i+2;
      next;
   }
   if($ARGV[$i] eq "--duration_factor" || $ARGV[$i] eq "-r") {
      $DF = $ARGV[$i+1];  # parameter for duration control
      $i=$i+2;
      next;
   }
   if($ARGV[$i] eq "--fw_factor" || $ARGV[$i] eq "-a") {
      $FW = $ARGV[$i+1];  # parameter for frequency warping 
      $i=$i+2;
      next;
   }
   if($ARGV[$i] eq "--total_length" || $ARGV[$i] eq "-l") {
       $LENGTH = $ARGV[$i+1];  # parameter for frequency warping
       $i=$i+2;
       next;
   }
   if($ARGV[$i] eq "--uv_threshold" || $ARGV[$i] eq "-v") {
      $UV = $ARGV[$i+1];  # parameter for frequency warping
      $i=$i+2;
      next;
   }
   if($ARGV[$i] eq "--use_phone_align" || $ARGV[$i] eq "-p") {
      $ALIGN = $ARGV[$i+1]; # use phoneme alignment or not
      $i=$i+2;
      next;
   }
   if($ARGV[$i] eq "--postfilter" || $ARGV[$i] eq "-pf") {
      $BETA = $ARGV[$i+1];
      $i=$i+2;
      next;
   }
}

# convert extracted features to context-dependent label sequence

system("awk -f ${DIR}/label-full.awk ${INFEATS} > ${WORKDIR}/tmp.lab");

# generate speech 

$line = "$DIR/hts_engine "             # speech sythesis module
      . "-dm ${DIR}/mcep_dyn.win   "   # window for Mel-cepstrum dynamic calculation
      . "-dm ${DIR}/mcep_acc.win   "   # window for Mel-cepstrum acceralation calculation 
      . "-df ${DIR}/lf0_dyn.win    "   # window for Log-F0 dynamic calculation
      . "-df ${DIR}/lf0_acc.win    "   # window for Log-F0 dynamic calculation
      . "-td ${DIR}/tree-dur.inf   "   # decision-trees for duration
      . "-tm ${DIR}/tree-mcep.inf  "   # decision-trees for Mel-cepstrum
      . "-tf ${DIR}/tree-lf0.inf   "   # decision-trees for Log-F0
      . "-md ${DIR}/duration.pdf   "   # probability density functions of duration
      . "-mm ${DIR}/mcep.pdf       "   # probability density functions of Mel-Cepstrum 
      . "-mf ${DIR}/lf0.pdf        "   # probability density functions of Log-F0
      . "-a  ${FW}                 "   # parameter for frequency warping
      . "-r  ${DF}                 "   # parameter for duration control
      . "-fs ${F0_STD}             "   # parameter for F0 shifting 
      . "-fm ${F0_MEAN}            "   # parameter for F0 multiplying
      . "-om ${WORKDIR}/tmp.mcep   "   # generated Mel-cepstrum sequence
      . "-of ${WORKDIR}/tmp.f0     "   # generated F0 sequence
      . "-or ${WORKDIR}/tmp.raw    "   # generated raw audio 
      . "-u  ${UV}                 "   # voiced/unvoiced threshold
      . "-l  ${LENGTH}             "   # Length of generated speech
      . "-b  ${BETA}               ";  # Postfiltering 

if($ALIGN!=0) {
   $line = ${line}."-vp            ";  # use phoneme alignment
}

$line = ${line}." ${WORKDIR}/tmp.lab    ";  # input label file

$line = $line . ">/dev/null";

system($line);

# add WAV header 

system("sox -r $SAMPRATE -t raw -s -c 1 -w $WORKDIR/tmp.raw $OUTWAVE");

# --- end of htsvoice.pl ---
